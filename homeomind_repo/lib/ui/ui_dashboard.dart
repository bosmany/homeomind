// ui_dashboard.dart
// HomeoMind — Dashboard: searchable case list, FAB to new case, backup menu.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/backup_service.dart';
import '../data/db_helper.dart';
import '../models/case_model.dart';
import 'ui_case_detail.dart';
import 'ui_appointments.dart';
import 'ui_settings.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  List<HomeoCase> _cases = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCases();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------
  // Data
  // -------------------------------------------------------------------

  Future<void> _loadCases() async {
    setState(() => _loading = true);
    final results = await DatabaseHelper.instance
        .getAllCases(search: _searchCtrl.text);
    if (!mounted) return;
    setState(() {
      _cases = results;
      _loading = false;
    });
  }

  /// Debounced real-time search: queries SQLite 300 ms after typing stops,
  /// so we hit the indexed columns instead of filtering a full list in Dart.
  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _loadCases);
  }

  Future<void> _runBackup() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final path = await BackupService.backupAllCases();
      messenger.showSnackBar(
        SnackBar(content: Text('Backup saved: $path')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Backup failed: $e')),
      );
    }
  }

  // -------------------------------------------------------------------
  // UI
  // -------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'HomeoMind',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            tooltip: 'Appointments',
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AppointmentsScreen(),
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'backup') _runBackup();
              if (value == 'settings') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SettingsScreen(),
                  ),
                );
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'backup',
                child: ListTile(
                  leading: Icon(Icons.archive_outlined),
                  title: Text('Backup Data'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings_outlined),
                  title: Text('Settings'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SearchBar(
              controller: _searchCtrl,
              hintText: 'Search by patient name or case no.',
              leading: const Icon(Icons.search),
              trailing: [
                if (_searchCtrl.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _searchCtrl.clear();
                      _loadCases();
                    },
                  ),
              ],
              elevation: const WidgetStatePropertyAll(0),
              onChanged: _onSearchChanged,
            ),
          ),
        ),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('New Case'),
        onPressed: () async {
          await Navigator.pushNamed(context, '/new-case');
          _loadCases(); // refresh list after returning from the form
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_cases.isEmpty) {
      return _EmptyState(searching: _searchCtrl.text.isNotEmpty);
    }

    return RefreshIndicator(
      onRefresh: _loadCases,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 96), // clear the FAB
        itemCount: _cases.length + 1, // +1 for the Instagram bridge card
        itemBuilder: (context, i) {
          if (i == _cases.length) {
            return const InstagramBridgeCard();
          }

          return _CaseCard(
            homeoCase: _cases[i],
            onChanged: _loadCases,
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Case card: Name · Case No · Date (+ chief complaint preview)
// ---------------------------------------------------------------------

class _CaseCard extends StatelessWidget {
  const _CaseCard({
    required this.homeoCase,
    required this.onChanged,
  });

  final HomeoCase homeoCase;
  final VoidCallback onChanged;

  String _formatDate(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final p = homeoCase.patient;

    final ageSex = [
      if (p.age != null) '${p.age}y',
      if (p.sex.isNotEmpty) p.sex,
    ].join(' / ');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CaseDetailScreen(
                existingCase: homeoCase,
              ),
            ),
          );

          onChanged(); // refresh list after edit/delete
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: cs.primaryContainer,
                child: Text(
                  p.name.isNotEmpty
                      ? p.name[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name.isNotEmpty
                          ? p.name
                          : '(Unnamed patient)',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (ageSex.isNotEmpty) ageSex,
                        if (homeoCase
                            .chiefComplaint.complaint.isNotEmpty)
                          homeoCase.chiefComplaint.complaint,
                      ].join(' · '),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: cs.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      homeoCase.caseNo.isNotEmpty
                          ? '#${homeoCase.caseNo}'
                          : '#—',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(
                            color: cs.onSecondaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatDate(homeoCase.date),
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.searching,
  });

  final bool searching;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            searching
                ? Icons.search_off
                : Icons.folder_open_outlined,
            size: 56,
            color: cs.outline,
          ),
          const SizedBox(height: 12),
          Text(
            searching
                ? 'No cases match your search'
                : 'No cases yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            searching
                ? 'Try a different name or case number.'
                : 'Tap "New Case" to record your first patient.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Instagram bridge — "Clinical Insights" card linking to the clinic's
// profile. A native card + url_launcher is far more reliable than
// embedding Instagram in a WebView (login walls, CSP, web build issues).
// ---------------------------------------------------------------------

class InstagramBridgeCard extends StatelessWidget {
  const InstagramBridgeCard({super.key});

  static final Uri _profile = Uri.parse(
    'https://www.instagram.com/muhammadibrahimubharay/',
  );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => launchUrl(
          _profile,
          mode: LaunchMode.externalApplication,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF7A3EB1),
                      Color(0xFFE1306C),
                      Color(0xFFFCAF45),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.camera_alt_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Clinical Insights',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      'Latest reels & posts from the clinic\'s Instagram',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.open_in_new,
                size: 18,
                color: cs.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
