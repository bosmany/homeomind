// ui_patient_home.dart
// HomeoMind — patient-facing screen: doctor profile, booking → WhatsApp,
// Instagram link, doctor portal entry. Every external asset is null-safe:
// missing photo → initials avatar; failed launches → snackbar, never a crash.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'ui_dashboard.dart' show InstagramBridgeCard;

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  static const _docPhone = '918208015063';
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _date = TextEditingController();
  final _concern = TextEditingController();
  String _slot = 'Morning (10 AM – 1 PM)';

  @override
  void dispose() {
    for (final c in [_name, _phone, _date, _concern]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _safeLaunch(Uri uri) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) throw 'unavailable';
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not open the app — please call the clinic.')));
    }
  }

  void _book() {
    final n = _name.text.trim(), p = _phone.text.trim(), d = _date.text.trim();
    if (n.isEmpty || p.isEmpty || d.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill name, phone and date')));
      return;
    }
    final msg = Uri.encodeComponent(
        'New Appointment Request — Dr. Ubharay Homeopathy Clinic\n'
        'Name: $n\nPhone: $p\nDate: $d\nSlot: $_slot\n'
        'Concern: ${_concern.text.trim().isEmpty ? '—' : _concern.text.trim()}');
    _safeLaunch(Uri.parse('https://wa.me/$_docPhone?text=$msg'));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dr. Ubharay Clinic'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/doc'),
            child: const Text('Doctor Portal',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---- Doctor profile (photo is null-safe) ----
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  _DoctorAvatar(radius: 56),
                  const SizedBox(height: 12),
                  Text('Dr. Muhammad Ibrahim A. Ubharay',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge),
                  Text('MD (Hom), Psychiatry',
                      style: TextStyle(
                          color: cs.primary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    'Consultant Homeopath · Assistant Professor · Mumbai\n'
                    '10+ yrs · AIAPGET state rank · CBT-integrated care',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => _safeLaunch(
                        Uri.parse('https://wa.me/$_docPhone')),
                    icon: const Icon(Icons.chat_outlined, size: 18),
                    label: const Text('WhatsApp the Clinic'),
                    style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 6),
          const InstagramBridgeCard(),
          const SizedBox(height: 6),

          // ---- Booking ----
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Book an Appointment',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  TextField(
                      controller: _name,
                      decoration:
                          const InputDecoration(labelText: 'Your name *')),
                  const SizedBox(height: 10),
                  TextField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                          labelText: 'Phone / WhatsApp *')),
                  const SizedBox(height: 10),
                  TextField(
                      controller: _date,
                      keyboardType: TextInputType.datetime,
                      decoration: const InputDecoration(
                          labelText: 'Preferred date (YYYY-MM-DD) *')),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _slot,
                    dropdownColor: const Color(0xFF17231C),
                    items: const [
                      DropdownMenuItem(
                          value: 'Morning (10 AM – 1 PM)',
                          child: Text('Morning (10 AM – 1 PM)')),
                      DropdownMenuItem(
                          value: 'Evening (5 PM – 9 PM)',
                          child: Text('Evening (5 PM – 9 PM)')),
                    ],
                    onChanged: (v) => setState(() => _slot = v ?? _slot),
                    decoration:
                        const InputDecoration(labelText: 'Time slot'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                      controller: _concern,
                      maxLines: 2,
                      decoration: const InputDecoration(
                          labelText: 'Health concern (brief)')),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _book,
                      icon: const Icon(Icons.send_outlined, size: 18),
                      label: const Text('Send Request via WhatsApp'),
                    ),
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

/// Doctor photo with graceful fallback: place the image at
/// assets/images/doctor.jpg (declared in pubspec). If it's missing or fails
/// to decode, an initials avatar renders instead — never a crash.
class _DoctorAvatar extends StatelessWidget {
  const _DoctorAvatar({required this.radius});
  final double radius;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipOval(
      child: Image.asset(
        'assets/images/doctor.jpg',
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: radius * 2,
          height: radius * 2,
          color: cs.primaryContainer,
          alignment: Alignment.center,
          child: Text('MU',
              style: TextStyle(
                  fontSize: radius * 0.6,
                  fontWeight: FontWeight.w700,
                  color: cs.onPrimaryContainer)),
        ),
      ),
    );
  }
}
