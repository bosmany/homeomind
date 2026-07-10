// voice_input.dart
// HomeoMind — dictation via the browser's built-in speech recognition
// (Chrome/Edge). English, Hindi, Marathi. Web-only, like instagram_embed.
// Free: no Google Cloud account or API key needed.

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/material.dart';

/// Global dictation language shared by every mic button.
class VoiceLang {
  static final ValueNotifier<String> current = ValueNotifier('en-IN');
  static const options = <String, String>{
    'en-IN': 'English',
    'hi-IN': 'हिंदी',
    'mr-IN': 'मराठी',
  };
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
  html.SpeechRecognition? _rec;
  bool _listening = false;

  bool get _supported => html.SpeechRecognition.supported;

  void _toggle() {
    if (_listening) {
      _stop();
      return;
    }
    if (!_supported) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Voice input needs Chrome or Edge on this device.')));
      return;
    }
    try {
      final rec = html.SpeechRecognition()
        ..lang = VoiceLang.current.value
        ..continuous = false
        ..interimResults = false;

      rec.onResult.listen((e) {
        try {
          final results = e.results;
          if (results == null || results.isEmpty) return;
          final transcript =
              results.last.item(0)?.transcript?.trim() ?? '';
          if (transcript.isEmpty) return;
          final t = widget.controller.text;
          widget.controller.text =
              t.isEmpty ? transcript : '$t $transcript';
          widget.controller.selection = TextSelection.collapsed(
              offset: widget.controller.text.length);
        } catch (_) {}
      });
      rec.onEnd.listen((_) {
        if (mounted) setState(() => _listening = false);
      });
      rec.onError.listen((_) {
        if (mounted) {
          setState(() => _listening = false);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  'Mic error — allow microphone access and try again.')));
        }
      });

      rec.start();
      _rec = rec;
      setState(() => _listening = true);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not start voice input on this browser.')));
    }
  }

  void _stop() {
    try {
      _rec?.stop();
    } catch (_) {}
    if (mounted) setState(() => _listening = false);
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
