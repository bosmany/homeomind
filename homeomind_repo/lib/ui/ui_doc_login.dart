// ui_doc_login.dart
// HomeoMind — simple doctor gate. Password 'demo123' → dashboard.
// NOTE: demo-grade only; replace with real auth before storing real
// patient data on any shared/hosted deployment.

import 'package:flutter/material.dart';

class DocLoginScreen extends StatefulWidget {
  const DocLoginScreen({super.key});

  @override
  State<DocLoginScreen> createState() => _DocLoginScreenState();
}

class _DocLoginScreenState extends State<DocLoginScreen> {
  final _pw = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _pw.dispose();
    super.dispose();
  }

  void _login() {
    if (_pw.text == 'demo123') {
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incorrect password')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Doctor Login')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline,
                      size: 40,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 12),
                  Text('HomeoMind Portal',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _pw,
                    obscureText: _obscure,
                    onSubmitted: (_) => _login(),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      suffixIcon: IconButton(
                        icon: Icon(_obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () =>
                            setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                        onPressed: _login, child: const Text('Enter Portal')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
