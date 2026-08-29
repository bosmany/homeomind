// voice_input.dart
// HomeoMind — dictation. Default: the browser's built-in speech recognition
// (Chrome/Edge), free, no API key needed. Optional: OpenAI Whisper via the
// CORS proxy (see VoiceMode below) for better accuracy on fast speech and
// accented multi-language input, toggled from Settings. English, Hindi,
// Marathi. Web-only, like instagram_embed.

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/transcription_service.dart';

/// Global dictation language shared by every mic button.
class VoiceLang {
  static final ValueNotifier<String> current = ValueNotifier('en-IN');
  static const options = <String, String>{
    'en-IN': 'English',
    'hi-IN': 'हिंदी',
    'mr-IN': 'मराठी',
  };
}

/// Global dictation engine, shared by every mic button and persisted across
/// sessions: `false` (default) uses the free browser speech recognition
/// below; `true` routes through [TranscriptionService] (Whisper) instead.
/// Call [VoiceMode.load] once at app startup so the persisted choice is in
/// effect before any mic button is shown.
class VoiceMode {
  static final ValueNotifier<bool> useWhisper = ValueNotifier(false);
  static const _prefKey = 'voice_use_whisper';

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    useWhisper.value = prefs.getBool(_prefKey) ?? false;
  }

  static Future<void> setUseWhisper(bool value) async {
    useWhisper.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, value);
  }
}

/// Language switcher — place once at the top of a form.
class VoiceLangSelector extends StatelessWidget {
  const VoiceLangSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: VoiceLang.current,
      builder: (_, lang, __) => Row(
        children: [
          const Icon(Icons.mic_none, size: 16),
          const SizedBox(width: 6),
          const Text('Dictation:', style: TextStyle(fontSize: 12.5)),
          const SizedBox(width: 8),
          Expanded(
            child: SegmentedButton<String>(
              style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              segments: VoiceLang.options.entries
                  .map((e) => ButtonSegment(
                      value: e.key,
                      label: Text(e.value,
                          style: const TextStyle(fontSize: 11.5))))
                  .toList(),
              selected: {lang},
              onSelectionChanged: (s) => VoiceLang.current.value = s.first,
            ),
          ),
        ],
      ),
    );
  }
}

/// Mic button that appends dictated text to [controller].
/// Tap to start, tap again (or pause speaking) to stop.
class MicButton extends StatefulWidget {
  const MicButton({super.key, required this.controller});
  final TextEditingController controller;

  @override
  State<MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<MicButton> {
  static const _maxRestarts = 5;

  html.SpeechRecognition? _rec;
  bool _listening = false;

  // Text already in the controller when this listening session began (or
  // when the session last auto-restarted) — everything new is appended
  // after this rather than replacing it.
  String _baseText = '';
  // Finalized transcript accumulated since _baseText was captured.
  String _finalizedText = '';
  // Live in-progress guess for the current (not-yet-final) phrase; replaced
  // wholesale on every event rather than appended, since the recognizer
  // keeps revising it.
  String _interimText = '';
  // How many entries of the current recognizer's `results` list have
  // already been folded into _finalizedText, so continuous mode's repeated
  // delivery of the same growing list doesn't double-append them.
  int _finalizedThrough = 0;

  bool _userStopped = false; // tap-to-stop, or a fatal (permission) error
  int _restartAttempts = 0;

  bool get _supported => html.SpeechRecognition.supported;

  String _joinNonEmpty(Iterable<String> parts) =>
      parts.where((p) => p.isNotEmpty).join(' ');

  void _applyToController() {
    final combined =
        _joinNonEmpty([_baseText, _finalizedText, _interimText]);
    widget.controller.text = combined;
    widget.controller.selection =
        TextSelection.collapsed(offset: combined.length);
  }

  void _onResult(html.SpeechRecognitionEvent e) {
    final results = e.results;
    if (results == null) return;
    final start = e.resultIndex ?? 0;
    String newFinal = '';
    String interim = '';
    for (var i = start; i < results.length; i++) {
      final result = results[i];
      if ((result.length ?? 0) == 0) continue;
      final transcript = result.item(0).transcript?.trim() ?? '';
      if (transcript.isEmpty) continue;
      if (result.isFinal == true) {
        if (i >= _finalizedThrough) {
          newFinal = _joinNonEmpty([newFinal, transcript]);
          _finalizedThrough = i + 1;
        }
      } else {
        interim = _joinNonEmpty([interim, transcript]);
      }
    }
    if (newFinal.isNotEmpty) {
      _finalizedText = _joinNonEmpty([_finalizedText, newFinal]);
      _restartAttempts = 0; // recognizer is healthy — reset the budget
    }
    _interimText = interim;
    _applyToController();
  }

  void _startSession({required bool isRestart}) {
    final rec = html.SpeechRecognition()
      ..lang = VoiceLang.current.value
      ..continuous = true
      ..interimResults = true;

    if (isRestart) {
      // Fold whatever was already committed into the new base so a
      // forced restart never loses text already accumulated.
      _baseText = _joinNonEmpty([_baseText, _finalizedText, _interimText]);
    } else {
      _baseText = widget.controller.text;
    }
    _finalizedText = '';
    _interimText = '';
    _finalizedThrough = 0;

    rec.onResult.listen((e) {
      try {
        _onResult(e);
      } catch (_) {}
    });
    rec.onEnd.listen((_) => _handleEnd());
    rec.onError.listen((e) => _handleError(e));

    rec.start();
    _rec = rec;
  }

  void _handleEnd() {
    if (!mounted) return;
    if (_userStopped || !_listening) {
      setState(() => _listening = false);
      return;
    }
    // The browser ended the session on its own (silence timeout, a network
    // hiccup, ~60s continuous-mode cap) even though the user never tapped
    // stop — pick dictation back up instead of silently going quiet.
    if (_restartAttempts < _maxRestarts) {
      _restartAttempts++;
      try {
        _startSession(isRestart: true);
        return;
      } catch (_) {}
    }
    setState(() => _listening = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Dictation stopped unexpectedly — tap the mic to '
            'try again.')));
  }

  void _handleError(html.SpeechRecognitionError e) {
    const fatal = {'not-allowed', 'audio-capture', 'service-not-allowed'};
    if (fatal.contains(e.error)) {
      _userStopped = true; // stop _handleEnd() from attempting a restart
      if (mounted) {
        setState(() => _listening = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Mic error — allow microphone access and try again.')));
      }
    }
    // Recoverable errors ('no-speech', 'network', 'aborted') are left to
    // the 'end' event that follows, which restarts the session.
  }

  void _toggle() {
    if (VoiceMode.useWhisper.value) {
      _toggleWhisper();
    } else {
      _toggleBrowserStt();
    }
  }

  void _toggleBrowserStt() {
    if (_listening) {
      _stopBrowserStt();
      return;
    }
    if (!_supported) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Voice input needs Chrome or Edge on this device.')));
      return;
    }
    try {
      _userStopped = false;
      _restartAttempts = 0;
      _startSession(isRestart: false);
      setState(() => _listening = true);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not start voice input on this browser.')));
    }
  }

  void _stopBrowserStt() {
    _userStopped = true;
    try {
      _rec?.stop();
    } catch (_) {}
    if (mounted) setState(() => _listening = false);
  }

  bool _transcribing = false;

  Future<void> _toggleWhisper() async {
    if (_listening) {
      setState(() {
        _listening = false;
        _transcribing = true;
      });
      try {
        final transcript = await TranscriptionService.instance
            .stopAndTranscribe(language: VoiceLang.current.value);
        if (transcript.isNotEmpty) {
          final t = widget.controller.text;
          widget.controller.text = t.isEmpty ? transcript : '$t $transcript';
          widget.controller.selection = TextSelection.collapsed(
              offset: widget.controller.text.length);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Transcription failed: $e')));
        }
      } finally {
        if (mounted) setState(() => _transcribing = false);
      }
      return;
    }
    try {
      await TranscriptionService.instance.startRecording();
      if (mounted) setState(() => _listening = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  void dispose() {
    _userStopped = true;
    try {
      _rec?.stop();
    } catch (_) {}
    if (_listening && VoiceMode.useWhisper.value) {
      TranscriptionService.instance.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_transcribing) {
      return const Padding(
        padding: EdgeInsets.all(14),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return IconButton(
      tooltip: _listening ? 'Stop dictation' : 'Dictate',
      icon: Icon(
        _listening ? Icons.mic : Icons.mic_none,
        color: _listening
            ? Colors.red
            : Theme.of(context).colorScheme.primary,
        size: 20,
      ),
      onPressed: _toggle,
    );
  }
}
