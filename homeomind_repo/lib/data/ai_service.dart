// ai_service.dart
// HomeoMind — OpenAI integration.
// getSuggestion(): remedy + potency + dose + reasoning + rubrics +
//                  GNM conflict + remedy comparison (differentials).
// extractTotality(): drafts Mental/Physical/Particulars from case text.
// Key lives in flutter_secure_storage; set it from Settings.

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class RemedySuggestion {
  final String remedy;
  final String potency;
  final String dose;
  final String reasoning;
  final List<String> rubrics;
  final String gnmConflict;
  final List<String> differentials;

  const RemedySuggestion({
    required this.remedy,
    required this.potency,
    required this.dose,
    required this.reasoning,
    this.rubrics = const [],
    this.gnmConflict = '',
    this.differentials = const [],
  });

  factory RemedySuggestion.fromJson(Map<String, dynamic> j) =>
      RemedySuggestion(
        remedy: j['remedy'] ?? '',
        potency: j['potency'] ?? '',
        dose: j['dose'] ?? '',
        reasoning: j['reasoning'] ?? '',
        rubrics: (j['rubrics'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        gnmConflict: j['gnmConflict'] ?? '',
        differentials: (j['differentials'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      );
}

class TotalityDraft {
  final List<String> mental;
  final List<String> physical;
  final List<String> particulars;

  const TotalityDraft({
    this.mental = const [],
    this.physical = const [],
    this.particulars = const [],
  });

  factory TotalityDraft.fromJson(Map<String, dynamic> j) => TotalityDraft(
        mental:
            (j['mental'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
        physical:
            (j['physical'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
        particulars: (j['particulars'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      );
}

class OpenAIService {
  OpenAIService._internal();
  static final OpenAIService instance = OpenAIService._internal();

  static const _storage = FlutterSecureStorage();
  static const _keyName = 'openai_api_key';
  static const _endpoint = 'https://api.openai.com/v1/chat/completions';
  static const _model = 'gpt-4o-mini';

  Future<void> setApiKey(String key) =>
      _storage.write(key: _keyName, value: key);
  Future<String?> getApiKey() => _storage.read(key: _keyName);
  Future<void> clearApiKey() => _storage.delete(key: _keyName);

  Future<String> _requireKey() async {
    final key = await getApiKey();
    if (key == null || key.isEmpty) {
      throw StateError(
          'No API key configured. Add one in Settings to enable AI.');
    }
    return key;
  }

  Future<void> testConnection() async {
    await _chat('Reply with OK', 'Reply with only the word OK',
        maxTokens: 5, wantJson: false);
  }

  Future<RemedySuggestion> getSuggestion(
      Map<String, dynamic> caseData) async {
    final content = await _chat(
      jsonEncode(caseData),
      'You are a homeopathic repertorization assistant for a licensed '
      'practitioner (MD Hom) who also uses German New Medicine (GNM) '
      'concepts. Given structured case data, respond ONLY with JSON: '
      '{"remedy": string, "potency": string, "dose": string, '
      '"reasoning": string, '
      '"rubrics": [5-8 relevant repertory rubrics as strings, e.g. '
      '"MIND - FEAR - husband, of losing"], '
      '"gnmConflict": string (one short paragraph naming the most likely '
      'biological conflict type and why, or "" if unclear), '
      '"differentials": [2-3 strings, each "RemedyName — one-line '
      'comparison vs the chosen remedy"]}. '
      'The practitioner reviews everything; nothing is auto-accepted.',
    );
    return RemedySuggestion.fromJson(jsonDecode(content));
  }

  Future<TotalityDraft> extractTotality(Map<String, dynamic> input) async {
    final content = await _chat(
      jsonEncode(input),
      'You are assisting a homeopath in organising a case. From the given '
      'case text (chief complaint, additional complaints, mind picture, '
      'DHS), extract the totality. Respond ONLY with JSON: '
      '{"mental": [strings], "physical": [strings], '
      '"particulars": [strings]}. Each item one short symptom line in '
      'repertory-friendly language. Do not invent symptoms not present '
      'in the input.',
    );
    return TotalityDraft.fromJson(jsonDecode(content));
  }

  // ---- shared plumbing ----

  Future<String> _chat(String user, String system,
      {int maxTokens = 900, bool wantJson = true}) async {
    final key = await _requireKey();
    final body = <String, dynamic>{
      'model': _model,
      'temperature': 0.3,
      'max_tokens': maxTokens,
      'messages': [
        {'role': 'system', 'content': system},
        {'role': 'user', 'content': user},
      ],
    };
    if (wantJson) body['response_format'] = {'type': 'json_object'};

    final r = await http
        .post(Uri.parse(_endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $key',
            },
            body: jsonEncode(body))
        .timeout(const Duration(seconds: 60));

    if (r.statusCode != 200) throw Exception(_friendlyError(r));
    final data = jsonDecode(r.body) as Map<String, dynamic>;
    final content = data['choices']?[0]?['message']?['content'] as String?;
    if (content == null) throw Exception('Unexpected API response shape.');
    return content;
  }

  String _friendlyError(http.Response r) {
    switch (r.statusCode) {
      case 401:
        return 'Invalid API key (401). Re-check it in Settings.';
      case 429:
        return 'Rate limit / quota exceeded (429). Check OpenAI billing.';
      case 500:
      case 503:
        return 'OpenAI unavailable (${r.statusCode}). Try again shortly.';
      default:
        return 'API error ${r.statusCode}: ${r.body}';
    }
  }
}
