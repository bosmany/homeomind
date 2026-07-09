// ui_settings.dart
// HomeoMind — Settings: securely store the OpenAI API key (flutter_secure_storage
// via OpenAIService). The key never appears in source code or the database.

import 'package:flutter/material.dart';

import '../data/ai_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _keyCtrl = TextEditingController();
  bool _hasKey = false;
  bool _busy = false;
  String _maskedTail = '';

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  @override
  void dispose() {
    _keyCtrl.dispose();
    super.dispose();
  }

  Future<void> _refreshStatus() async {
    final key = await OpenAIService.instance.getApiKey();
    if (!mounted) return;
    setState(() {
      _hasKey = key != null && key.isNotEmpty;
      _maskedTail = _hasKey && key!.length > 4
          ? '••••${key.substring(key.length - 4)}'
          : '';
    });
  }

  Future<void> _saveKey() async {
    final key = _keyCtrl.text.trim();
    if (key.isEmpty) return;
    setState(() => _busy = true);
    await OpenAIService.instance.setApiKey(key);
    _keyCtrl.clear();
    await _refreshStatus();
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('API key saved securely')),
    );
  }

  Future<void> _clearKey() async {
    await OpenAIService.instance.clearApiKey();
    await _refreshStatus();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('API key removed')),
    );
  }

  /// Fires a minimal real request so the doctor knows the key works
  /// before relying on it mid-consultation.
  Future<void> _testConnection() async {
    setState(() => _busy = true);
    try {
      await OpenAIService.instance.testConnection();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✓ Connection successful')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI Remedy Suggestions',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Text(
                    _hasKey
                        ? 'Key configured ($_maskedTail). AI analysis is active.'
                        : 'No API key set — the ✨ Analyze feature is disabled '
                            'until you add one.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _keyCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'OpenAI API key',
                      hintText: 'sk-…',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: _busy ? null : _saveKey,
                        icon: const Icon(Icons.lock_outline, size: 18),
                        label: const Text('Save securely'),
                      ),
                      if (_hasKey)
                        FilledButton.tonalIcon(
                          onPressed: _busy ? null : _testConnection,
                          icon: _busy
                              ? const SizedBox(
                                  width: 15,
                                  height: 15,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2))
                              : const Icon(Icons.wifi_tethering, size: 18),
                          label: const Text('Test connection'),
                        ),
                      if (_hasKey)
                        TextButton(
                          onPressed: _busy ? null : _clearKey,
                          child: const Text('Remove key'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'The key is stored in your device\'s encrypted keystore '
                    '(Keystore/Keychain), never in the case database or backups.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
