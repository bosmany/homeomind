// ui_patient_home.dart
// HomeoMind — patient page, premium botanical design:
// gradient hero with photo + badges, stats, services (mirroring the clinic's
// real service lines), embedded Instagram, stories, WhatsApp booking.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'instagram_embed.dart';

const _kGreenDark = Color(0xFF0F2A1C);
const _kGreen = Color(0xFF1D4D34);
const _kGreenMid = Color(0xFF2E6E4E);
const _kGold = Color(0xFFD9A419);

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
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _Hero(onPortal: () => Navigator.pushNamed(context, '/doc')),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 14),
                const _StatsRow(),
                const _SectionTitle('About the Doctor'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Dr. Ubharay Homeopathy Clinic, led by Dr. Muhammad '
                      'Ibrahim A. Ubharay (MD Hom, Psychiatry), offers '
                      'compassionate, holistic care. With over 10 years of '
                      'experience, he specialises in psychiatric and general '
                      'conditions, integrating classical homeopathy with '
                      'modern counselling (CBT). Individualized, root-cause '
                      'treatment for mind and body — safe, natural and '
                      'side-effect free, for patients of all ages.',
                      style: TextStyle(
                          height: 1.55, color: Colors.grey.shade800),
                    ),
                  ),
                ),
                const _SectionTitle('Our Services'),
                const _ServiceCard('Psychiatric Care',
                    'Anxiety, depression, OCD, ADHD and stress disorders — homeopathy combined with CBT-informed counselling.'),
                const _ServiceCard('Skin & Hair Care',
                    'Eczema, psoriasis, vitiligo, acne, warts, fungal infections and hair fall — lasting relief by correcting immunity.'),
                const _ServiceCard('Respiratory Health',
                    'Asthma, bronchitis, allergic rhinitis and recurrent colds — strengthening natural respiratory immunity.'),
                const _ServiceCard('Digestive & Metabolic',
                    'Acidity, IBS, constipation, obesity and diabetes support — regulating metabolism with individualized care.'),
                const _ServiceCard('Women\'s & Men\'s Health',
                    'PCOS, menstrual disorders, menopause; vitality and confidence concerns — hormonal balance restored naturally.'),
                const _ServiceCard('Child Health',
                    'Recurrent tonsillitis, allergies, behavioural and developmental concerns — gentle, child-friendly medicine.'),
                const _SectionTitle('Clinical Insights'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        const ClipRRect(
                          borderRadius:
                              BorderRadius.all(Radius.circular(12)),
                          child: InstagramEmbed(),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                  "Latest from the clinic's Instagram",
                                  style: TextStyle(
                                      fontSize: 12.5,
                                      color: Colors.grey.shade600)),
                            ),
                            TextButton(
                              onPressed: () => _safeLaunch(Uri.parse(
                                  'https://www.instagram.com/muhammadibrahimubharay/')),
                              child: const Text('View Profile ↗'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const _SectionTitle('Patient Stories'),
                const _Story(
                    'After months of panic attacks, the combination of remedies and counselling gave me my life back. I felt heard from the first sitting.',
                    '— R.K., 34 (anxiety)'),
                const _Story(
                    'My son\'s recurrent tonsillitis stopped within a season of treatment. No antibiotics for over a year now.',
                    '— Parent of A.M., 12'),
                const _Story(
                    'The doctor took a full hour to understand my case history. The migraines are now rare and mild.',
                    '— S.P., 41 (migraine)'),
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4),
                  child: Text('Representative stories, shared with consent.',
                      style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey.shade600)),
                ),
                const _SectionTitle('Book an Appointment'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextField(
                            controller: _name,
                            decoration: const InputDecoration(
                                labelText: 'Your name *')),
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
                          items: const [
                            DropdownMenuItem(
                                value: 'Morning (10 AM – 1 PM)',
                                child: Text('Morning (10 AM – 1 PM)')),
                            DropdownMenuItem(
                                value: 'Evening (5 PM – 9 PM)',
                                child: Text('Evening (5 PM – 9 PM)')),
                          ],
                          onChanged: (v) =>
                              setState(() => _slot = v ?? _slot),
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
                            style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366),
                                foregroundColor: Colors.white),
                            icon: const Icon(Icons.send_outlined, size: 18),
                            label:
                                const Text('Send Request via WhatsApp'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                      'Dr. Ubharay Homeopathy Clinic · Mumbai · +91 82080 15063',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 11.5, color: Colors.grey.shade600)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================ HERO ============================

class _Hero extends StatelessWidget {
  const _Hero({required this.onPortal});
  final VoidCallback onPortal;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kGreenDark, _kGreen, _kGreenMid],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              children: [
                Text('Dr. Ubharay Clinic',
                    style: GoogleFonts.fraunces(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w700)),
                const Spacer(),
                TextButton(
                  onPressed: onPortal,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.white.withOpacity(.13),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                  ),
                  child: const Text('Doctor Portal',
                      style: TextStyle(fontSize: 12.5)),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const _DoctorAvatar(radius: 58),
            const SizedBox(height: 12),
            Text('Dr. Muhammad Ibrahim A. Ubharay',
                textAlign: TextAlign.center,
                style: GoogleFonts.fraunces(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            const Text('MD (Hom), Psychiatry',
                style: TextStyle(
                    color: _kGold,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5)),
            const SizedBox(height: 4),
            Text('Consultant Homeopath · Assistant Professor · Mumbai',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white.withOpacity(.85), fontSize: 12.5)),
            const SizedBox(height: 14),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: const [
                _Badge('10+ Years'),
                _Badge('AIAPGET State Rank'),
                _Badge('Published Researcher'),
                _Badge('CBT-Integrated'),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => launchUrl(
                  Uri.parse('https://wa.me/918208015063'),
                  mode: LaunchMode.externalApplication),
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white),
              icon: const Icon(Icons.chat_outlined, size: 18),
              label: const Text('WhatsApp the Clinic'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoctorAvatar extends StatelessWidget {
  const _DoctorAvatar({required this.radius});
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: _kGold, width: 2.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(.35),
              blurRadius: 18,
              offset: const Offset(0, 8)),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/doctor.jpg',
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: radius * 2,
            height: radius * 2,
            color: _kGreenMid,
            alignment: Alignment.center,
            child: Text('MU',
                style: TextStyle(
                    fontSize: radius * .6,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(.25)),
      ),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w600)),
    );
  }
}

// ============================ BODY WIDGETS ============================

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    Widget stat(String big, String small) => Expanded(
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                children: [
                  Text(big,
                      style: GoogleFonts.fraunces(
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                          color: _kGreen)),
                  const SizedBox(height: 2),
                  Text(small,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 10.5,
                          letterSpacing: .4,
                          color: Colors.grey.shade600)),
                ],
              ),
            ),
          ),
        );
    return Row(children: [
      stat('10+', 'YEARS EXP.'),
      stat('95%', 'POSITIVE FEEDBACK'),
      stat('5K+', 'PATIENTS TREATED'),
    ]);
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 8, left: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.fraunces(
                  fontSize: 19, fontWeight: FontWeight.w700, color: _kGreen)),
          const SizedBox(height: 5),
          Container(
              width: 32,
              height: 3,
              decoration: BoxDecoration(
                  color: _kGold, borderRadius: BorderRadius.circular(2))),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard(this.title, this.desc);
  final String title;
  final String desc;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient:
                    const LinearGradient(colors: [_kGreen, _kGreenMid]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.spa_outlined,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14.5)),
                  const SizedBox(height: 3),
                  Text(desc,
                      style: TextStyle(
                          fontSize: 12.5,
                          height: 1.45,
                          color: Colors.grey.shade700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Story extends StatelessWidget {
  const _Story(this.quote, this.who);
  final String quote;
  final String who;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        decoration: const BoxDecoration(
          border: Border(left: BorderSide(color: _kGold, width: 3)),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('"$quote"',
                style: TextStyle(
                    fontStyle: FontStyle.italic,
                    height: 1.45,
                    fontSize: 13.5,
                    color: Colors.grey.shade800)),
            const SizedBox(height: 6),
            Text(who,
                style: TextStyle(
                    fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}
