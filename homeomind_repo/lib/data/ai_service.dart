// ai_service.dart  (REPLACES the previous mock version)
// HomeoMind — real OpenAI integration for remedy suggestions.
// Key lives in flutter_secure_storage; set it from the Settings screen.
//
// pubspec.yaml dependencies:
//   flutter_secure_storage: ^9.0.0
//   http: ^1.2.0

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class RemedySuggestion {
  final String remedy;
  final String potency;
  final String dose;
  final String reasoning;

  const RemedySuggestion({
    required this.remedy,
    required this.potency,
    required this.dose,
    required this.reasoning,
  });

  factory RemedySuggestion.fromJson(Map<String, dynamic> j) =>
      RemedySuggestion(
        remedy: j['remedy'] ?? '',
        potency: j['potency'] ?? '',
        dose: j['dose'] ?? '',
        reasoning: j['reasoning'] ?? '',
      );
}

class OpenAIService {
  OpenAIService._internal();
  static final OpenAIService instance = OpenAIService._internal();

  static const _storage = FlutterSecureStorage();
  static const _keyName = 'openai_api_key';
  static const _endpoint = 'https://api.openai.com/v1/chat/completions';
  static const _model = 'gpt-4o-mini'; // change to taste

  // ---- key management ------------------------------------------------------
  Future<void> setApiKey(String key) =>
      _storage.write(key: _keyName, value: key);
  Future<String?> getApiKey() => _storage.read(key: _keyName);
  Future<void> clearApiKey() => _storage.delete(key: _keyName);

  Future<String> _requireKey() async {
    final key = await getApiKey();
    if (key == null || key.isEmpty) {
      throw StateError(
          'No API key configured. Add one in Settings to enable AI analysis.');
    }
    return key;
  }

  // ---- public API -----------------------------------------------------------

  /// Minimal round-trip so Settings can verify the key before clinical use.
  Future<void> testConnection() async {
    final key = await _requireKey();
    final r = await http
        .post(Uri.parse(_endpoint),
            headers: _headers(key),
            body: jsonEncode({
              'model': _model,
              'max_tokens': 5,
              'messages': [
                {'role': 'user', 'content': 'Reply with OK'}
              ],
            }))
        .timeout(const Duration(seconds: 20));
    if (r.statusCode != 200) {
      throw Exception(_friendlyError(r));
    }
  }

  Future<RemedySuggestion> getSuggestion(Map<String, dynamic> caseData) async {
    final key = await _requireKey();

    final response = await http
        .post(Uri.parse(_endpoint),
            headers: _headers(key),
            body: jsonEncode({
              'model': _model,
              'response_format': {'type': 'json_object'},
              'temperature': 0.3,
              'messages': [
                {
                  'role': 'system',
                  'content':
                      'You are a homeopathic repertorization assistant for a '
                          'licensed practitioner (MD Hom). Given structured case '
                          'data (chief complaint, mind, totality), respond ONLY '
                          'with JSON: {"remedy": string, "potency": string, '
                          '"dose": string, "reasoning": string}. In reasoning, '
                          'reference the specific rubrics that led to the choice '
                          'and mention 1-2 differential remedies considered. '
                          'The practitioner makes the final decision.',
                },
                {'role': 'user', 'content': jsonEncode(caseData)},
              ],
            }))
        .timeout(const Duration(seconds: 60));

    if (response.statusCode != 200) {
      throw Exception(_friendlyError(response));
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final content = body['choices']?[0]?['message']?['content'] as String?;
    if (content == null) {
      throw Exception('Unexpected API response shape.');
    }
    return RemedySuggestion.fromJson(
        jsonDecode(content) as Map<String, dynamic>);
  }

  // ---- helpers --------------------------------------------------------------

  Map<String, String> _headers(String key) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $key',
      };

  String _friendlyError(http.Response r) {
    switch (r.statusCode) {
      case 401:
        return 'Invalid API key (401). Re-check it in Settings.';
      case 429:
        return 'Rate limit or quota exceeded (429). Check your OpenAI billing.';
      case 500:
      case 503:
        return 'OpenAI service unavailable (${r.statusCode}). Try again shortly.';
      default:
        return 'API error ${r.statusCode}: ${r.body}';
    }
  }
}
