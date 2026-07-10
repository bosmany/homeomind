// ui_appointments.dart
// HomeoMind — doctor portal: appointment requests booked from the patient
// page. Two sections: New Requests, and Past & Completed.
// NOTE: appointments are stored in this device's local database. Bookings
// made on other devices reach the doctor via WhatsApp (by design) until a
// cloud backend is added.

import 'package:flutter/material.dart';

import '../data/db_helper.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  List<Map<String, dynamic>> _appts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final a = await DatabaseHelper.instance.getAppointments();
      if (!mounted) return;
      setState(() {
        _appts = a;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Load failed: $e')));
    }
  }

  Future<void> _markDone(int id) async {
    await DatabaseHelper.instance.setAppointmentStatus(id, 'done');
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final fresh = _appts.where((a) => a['status'] != 'done').toList();
    final past = _appts.where((a) => a['status'] == 'done').toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Appointments')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _sectionHeader(context, 'New Requests', fresh.length),
                  if (fresh.isEmpty) _empty('No new appointment requests.'),
                  ...fresh.map((a) => _ApptCard(a, onDone: _markDone)),
                  const SizedBox(height: 14),
                  _sectionHeader(
                    context,
                    'Past & Completed',
                    past.length,
                  ),
                  if (past.isEmpty) _empty('Nothing completed yet.'),
                  ...past.map((a) => _ApptCard(a, onDone: null)),
                ],
              ),
            ),
    );
  }

  Widget _sectionHeader(BuildContext context, String t, int n) => Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 4),
        child: Text(
          '$t ($n)',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontSize: 17),
        ),
      );

  Widget _empty(String msg) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          msg,
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
}

class _ApptCard extends StatelessWidget {
  const _ApptCard(this.a, {required this.onDone});

  final Map<String, dynamic> a;
  final void Function(int id)? onDone;

  @override
  Widget build(BuildContext context) {
    final isFu = a['type'] == 'followup';
    final done = a['status'] == 'done';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    a['name']?.toString() ?? '—',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
                _pill(
                  isFu
                      ? 'FOLLOW-UP · ${a['caseNo'] ?? ''}'
                      : 'NEW PATIENT',
                  isFu
                      ? const Color(0xFFD9A419)
                      : const Color(0xFF1D4D34),
                ),
                const SizedBox(width: 6),
                _pill(
                  done ? 'DONE' : 'NEW',
                  done ? Colors.grey : const Color(0xFF2E6E4E),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '📅 ${a['date'] ?? '—'}  ·  ${a['slot'] ?? ''}\n'
              '📞 ${a['phone'] ?? '—'}'
              '${(a['concern'] ?? '').toString().isEmpty ? '' : '\n📝 ${a['concern']}'}',
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Colors.grey.shade800,
              ),
            ),
            if (!done && onDone != null && a['id'] != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => onDone!(a['id'] as int),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Mark done'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _pill(String t, Color c) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: c.withOpacity(.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          t,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            color: c,
          ),
        ),
      );
}
