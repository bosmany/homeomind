// transcription_service.dart
// HomeoMind — optional Whisper-based dictation.
// Records audio via the browser's MediaRecorder and uploads it through the
// CORS proxy (see cf-worker/) to OpenAI's Whisper endpoint, returning the
// transcript. Far more accurate than the free browser Web Speech API for
// fast speech and accented multi-language input, at the cost of a short
// upload delay and API usage on the doctor's own key. Opt-in via the
// VoiceMode toggle in voice_input.dart — the default dictation path
// (voice_input.dart's browser STT) needs neither this file nor a key.

// ignore: avoid_web_libraries_in_flutter
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'ai_service.dart';

class TranscriptionService {
  TranscriptionService._internal();
  static final TranscriptionService instance =
      TranscriptionService._internal();

  // Same proxy as ai_service.dart's _endpoint, different OpenAI path.
  // TODO: replace <subdomain> once the Worker's first deploy confirms it
  // (see ai_service.dart's matching TODO).
  static const _endpoint =
      'https://homeomind-ai-proxy.<subdomain>.workers.dev/v1/audio/transcriptions';

  html.MediaRecorder? _recorder;
  html.MediaStream? _stream;
  final List<html.Blob> _chunks = [];

  Future<void> startRecording() async {
    final mediaDevices = html.window.navigator.mediaDevices;
    if (mediaDevices == null) {
      throw StateError('Microphone access needs Chrome or Edge on this device.');
    }
    _chunks.clear();
    _stream = await mediaDevices.getUserMedia({'audio': true});
    final rec = html.MediaRecorder(_stream!, {'mimeType': 'audio/webm'});
    rec.on['dataavailable'].listen((e) {
      final blob = (e as html.BlobEvent).data;
      if (blob != null && blob.size > 0) _chunks.add(blob);
    });
    rec.start();
    _recorder = rec;
  }

  /// Stops recording, uploads the clip to Whisper via the CORS proxy, and
  /// returns the transcript (empty string if nothing was recorded).
  /// Throws if no API key is configured or the upload fails.
  Future<String> stopAndTranscribe({required String language}) async {
    final rec = _recorder;
    if (rec == null) return '';

    final stopped = rec.on['stop'].first;
    rec.stop();
    await stopped;
    for (final track in _stream?.getTracks() ?? const <html.MediaStreamTrack>[]) {
      track.stop();
    }
    _recorder = null;
    _stream = null;

    if (_chunks.isEmpty) return '';
    final blob = html.Blob(List<html.Blob>.from(_chunks), 'audio/webm');
    _chunks.clear();

    final key = await OpenAIService.instance.getApiKey();
    if (key == null || key.isEmpty) {
      throw StateError('No API key configured. Add one in Settings.');
    }

    final reader = html.FileReader()..readAsArrayBuffer(blob);
    await reader.onLoad.first;
    final bytes = reader.result as Uint8List;

    final req = http.MultipartRequest('POST', Uri.parse(_endpoint))
      ..headers['Authorization'] = 'Bearer $key'
      ..fields['model'] = 'whisper-1'
      ..fields['language'] = language.split('-').first // 'en-IN' -> 'en'
      ..files.add(
          http.MultipartFile.fromBytes('file', bytes, filename: 'audio.webm'));

    final streamed = await req.send().timeout(const Duration(seconds: 60));
    final resp = await http.Response.fromStream(streamed);
    if (resp.statusCode != 200) {
      throw Exception(
          'Transcription failed (${resp.statusCode}): ${resp.body}');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return (data['text'] as String?)?.trim() ?? '';
  }

  /// Discards an in-progress recording without transcribing it — used when
  /// the mic button is disposed mid-recording (e.g. the user navigates
  /// away).
  void cancel() {
    try {
      _recorder?.stop();
    } catch (_) {}
    for (final track in _stream?.getTracks() ?? const <html.MediaStreamTrack>[]) {
      track.stop();
    }
    _recorder = null;
    _stream = null;
    _chunks.clear();
  }
}
