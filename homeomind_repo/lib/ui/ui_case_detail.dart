// ui_case_detail.dart
// HomeoMind — CaseDetailScreen: create, view, edit, and delete a case.
//   existingCase == null  → blank 12-step Stepper (create mode)
//   existingCase != null  → read-only detail preview; AppBar 'Edit' switches
//                           to the pre-filled Stepper (edit mode)
// Text inputs use a keyed controller map (_c); choice fields use M3 chips.

import 'package:flutter/material.dart';

import '../data/ai_service.dart';
import '../data/db_helper.dart';
import '../models/case_model.dart';

class CaseDetailScreen extends StatefulWidget {
  const CaseDetailScreen({super.key, this.existingCase});

  /// When provided, the screen opens as a read-only detail view with
  /// Edit/Delete actions; when null, it opens as a blank case form.
  final HomeoCase? existingCase;

  @override
  State<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends State<CaseDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _saving = false;
  bool _viewMode = false;
  bool _analyzing = false;

  // ---- keyed text controllers -------------------------------------------
  final _ctrl = <String, TextEditingController>{};
  TextEditingController _c(String key) =>
      _ctrl.putIfAbsent(key, () => TextEditingController());
  String _v(String key) => _c(key).text.trim();

  // ---- non-text state -----------------------------------------------------
  String _sex = '';
  final Set<String> _nature = {};
  static const _natureOptions = [
    'Mild', 'Irritable', 'Reserved', 'Sensitive',
    'Ambitious', 'Fastidious', 'Responsible', 'Anxious',
  ];
  String _gnmPhase = '';
  String _thermals = '';

  @override
  void initState() {
    super.initState();
    final c = widget.existingCase;
    if (c != null) {
      _viewMode = true; // existing cases open in read-only preview
      _prefill(c);
    }
  }

  /// Copies an existing case into the keyed controllers + choice state so
  /// the Stepper is fully pre-filled the moment the user taps 'Edit'.
  void _prefill(HomeoCase c) {
    _c('caseNo').text = c.caseNo;
    _c('date').text = c.date;
    _c('p.name').text = c.patient.name;
    _c('p.age').text = c.patient.age?.toString() ?? '';
    _c('p.occupation').text = c.patient.occupation;
    _sex = c.patient.sex;

    final cc = c.chiefComplaint;
    _c('cc.complaint').text = cc.complaint;
    _c('cc.location').text = cc.location;
    _c('cc.sensation').text = cc.sensation;
    _c('cc.modalities').text = cc.modalities;
    _c('cc.concomitants').text = cc.concomitants;
    _c('cc.duration').text = cc.duration;
    _c('cc.onset').text = cc.onsetAilmentsFrom;

    _nature.addAll(c.mind.nature.where(_natureOptions.contains));
    _c('mind.natureOther').text =
        c.mind.nature.where((n) => !_natureOptions.contains(n)).join('\n');
    _c('mind.conflict').text = c.mind.mainEmotionalConflict;
    _c('mind.fears').text = c.mind.fears.join('\n');
    _c('mind.stress').text = c.mind.stressTriggerEvent;
    _c('mind.relationships').text = c.mind.relationships;

    _c('gnm.dhs').text = c.gnm.dhsBiologicalConflict;
    _c('gnm.theme').text = c.gnm.conflictTheme;
    _gnmPhase = c.gnm.phase;

    final pg = c.physicalGenerals;
    _c('pg.appetite').text = pg.appetite;
    _c('pg.thirst').text = pg.thirst;
    _c('pg.desires').text = pg.desiresAversions;
    _thermals = pg.thermals;
    _c('pg.sleep').text = pg.sleep;
    _c('pg.stoolUrine').text = pg.stoolUrine;
    _c('pg.energy').text = pg.energy;

    _c('h.past').text = c.history.pastHistory;
    _c('h.family').text = c.history.familyHistory;
    _c('exam').text = c.examinationInvestigations;

    _c('tot.mental').text = c.totality.mental.join('\n');
    _c('tot.physical').text = c.totality.physical.join('\n');
    _c('tot.particulars').text = c.totality.particulars.join('\n');

    _c('rx.remedy').text = c.prescription.remedy;
    _c('rx.potency').text = c.prescription.potency;
    _c('rx.dose').text = c.prescription.dose;
    _c('rx.advice').text = c.prescription.advice;

    // The form edits the FIRST follow-up; later entries are preserved on save.
    if (c.followUps.isNotEmpty) {
      final fu = c.followUps.first;
      _c('fu.date').text = fu.date;
      _c('fu.changes').text = fu.changes;
      _c('fu.remedy').text = fu.prescription.remedy;
      _c('fu.potency').text = fu.prescription.potency;
      _c('fu.dose').text = fu.prescription.dose;
    }
  }

  @override
  void dispose() {
    for (final c in _ctrl.values) {
      c.dispose();
    }
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Save
  // -------------------------------------------------------------------------

  List<String> _lines(String key) => _v(key)
      .split('\n')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  HomeoCase _assembleCase() {
    final followUpHasData = _v('fu.date').isNotEmpty ||
        _v('fu.changes').isNotEmpty ||
        _v('fu.remedy').isNotEmpty;

    return HomeoCase(
      caseNo: _v('caseNo'),
      date: _v('date').isNotEmpty
          ? _v('date')
          : DateTime.now().toIso8601String(),
      patient: PatientDetails(
        name: _v('p.name'),
        age: int.tryParse(_v('p.age')),
        sex: _sex,
        occupation: _v('p.occupation'),
      ),
      chiefComplaint: ChiefComplaint(
        complaint: _v('cc.complaint'),
        location: _v('cc.location'),
        sensation: _v('cc.sensation'),
        modalities: _v('cc.modalities'),
        concomitants: _v('cc.concomitants'),
        duration: _v('cc.duration'),
        onsetAilmentsFrom: _v('cc.onset'),
      ),
      mind: MindAssessment(
        nature: [..._nature, ..._lines('mind.natureOther')],
        mainEmotionalConflict: _v('mind.conflict'),
        fears: _lines('mind.fears'),
        stressTriggerEvent: _v('mind.stress'),
        relationships: _v('mind.relationships'),
      ),
      gnm: GnmAssessment(
        dhsBiologicalConflict: _v('gnm.dhs'),
        conflictTheme: _v('gnm.theme'),
        phase: _gnmPhase,
      ),
      physicalGenerals: PhysicalGenerals(
        appetite: _v('pg.appetite'),
        thirst: _v('pg.thirst'),
        desiresAversions: _v('pg.desires'),
        thermals: _thermals,
        sleep: _v('pg.sleep'),
        stoolUrine: _v('pg.stoolUrine'),
        energy: _v('pg.energy'),
      ),
      history: CaseHistory(
        pastHistory: _v('h.past'),
        familyHistory: _v('h.family'),
      ),
      examinationInvestigations: _v('exam'),
      totality: Totality(
        mental: _lines('tot.mental'),
        physical: _lines('tot.physical'),
        particulars: _lines('tot.particulars'),
      ),
      prescription: Prescription(
        remedy: _v('rx.remedy'),
        potency: _v('rx.potency'),
        dose: _v('rx.dose'),
        advice: _v('rx.advice'),
      ),
      followUps: followUpHasData
          ? [
              FollowUp(
                date: _v('fu.date'),
                changes: _v('fu.changes'),
                prescription: Prescription(
                  remedy: _v('fu.remedy'),
                  potency: _v('fu.potency'),
                  dose: _v('fu.dose'),
                ),
              ),
            ]
          : [],
    );
  }

  Future<void> _saveCase() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      setState(() => _currentStep = 0); // jump to the step with errors
      return;
    }
    setState(() => _saving = true);
    final existing = widget.existingCase;
    try {
      if (existing == null) {
        await DatabaseHelper.instance.insertCase(_assembleCase());
      } else {
        final updated = _assembleCase()
          ..id = existing.id
          ..createdAt = existing.createdAt;
        // The form edits only the first follow-up; carry over later entries.
        if (existing.followUps.length > 1) {
          updated.followUps = [
            ...updated.followUps,
            ...existing.followUps.skip(1),
          ];
        }
        await DatabaseHelper.instance.updateCase(updated);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(existing == null ? 'Case saved' : 'Case updated')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')), // e.g. duplicate case no.
      );
    }
  }

  // -------------------------------------------------------------------------
  // Reusable field builders
  // -------------------------------------------------------------------------

  Widget _tf(
    String key,
    String label, {
    int maxLines = 1,
    String? hint,
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _c(key),
        maxLines: maxLines,
        keyboardType: keyboard,
        validator: validator,
        decoration: InputDecoration(labelText: label, hintText: hint),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: Theme.of(context).colorScheme.primary)),
      );

  // -------------------------------------------------------------------------
  // Step contents (one private method per section)
  // -------------------------------------------------------------------------

  Widget _buildPatientStep() => Column(children: [
        _tf('p.name', 'Patient name *',
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Name is required' : null),
        Row(children: [
          Expanded(
            child: _tf('p.age', 'Age', keyboard: TextInputType.number),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'M', label: Text('M')),
                  ButtonSegment(value: 'F', label: Text('F')),
                  ButtonSegment(value: 'Other', label: Text('Other')),
                ],
                selected: _sex.isEmpty ? {} : {_sex},
                emptySelectionAllowed: true,
                onSelectionChanged: (s) =>
                    setState(() => _sex = s.isEmpty ? '' : s.first),
              ),
            ),
          ),
        ]),
        _tf('p.occupation', 'Occupation'),
        _tf('caseNo', 'Case No. *',
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Case number is required'
                : null),
        _tf('date', 'Date (YYYY-MM-DD)',
            hint: 'Leave blank for today', keyboard: TextInputType.datetime),
      ]);

  Widget _buildChiefComplaintStep() => Column(children: [
        _tf('cc.complaint', 'Chief complaint', maxLines: 2),
        _tf('cc.location', 'Location'),
        _tf('cc.sensation', 'Sensation'),
        _tf('cc.modalities', 'Modalities (< worse / > better)', maxLines: 2),
        _tf('cc.concomitants', 'Concomitants'),
        _tf('cc.duration', 'Duration'),
        _tf('cc.onset', 'Onset / Ailments from'),
      ]);

  Widget _buildMindStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Nature'),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _natureOptions
                .map((n) => FilterChip(
                      label: Text(n),
                      selected: _nature.contains(n),
                      onSelected: (sel) => setState(
                          () => sel ? _nature.add(n) : _nature.remove(n)),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          _tf('mind.natureOther', 'Other nature traits (one per line)',
              maxLines: 2),
          _tf('mind.conflict', 'Main emotional conflict', maxLines: 2),
          _tf('mind.fears', 'Fear(s) — one per line', maxLines: 3),
          _tf('mind.stress', 'Stress / Trigger / Significant life event',
              maxLines: 3),
          _tf('mind.relationships', 'Relationships', maxLines: 2),
        ],
      );

  Widget _buildGnmStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _tf('gnm.dhs', 'DHS / Biological conflict', maxLines: 2),
          _tf('gnm.theme', 'Conflict theme'),
          _sectionLabel('Phase'),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                  value: 'Conflict Active', label: Text('Conflict Active')),
              ButtonSegment(value: 'Healing', label: Text('Healing')),
            ],
            selected: _gnmPhase.isEmpty ? {} : {_gnmPhase},
            emptySelectionAllowed: true,
            onSelectionChanged: (s) =>
                setState(() => _gnmPhase = s.isEmpty ? '' : s.first),
          ),
        ],
      );

  Widget _buildPhysicalGeneralsStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _tf('pg.appetite', 'Appetite'),
          _tf('pg.thirst', 'Thirst'),
          _tf('pg.desires', 'Desires / Aversions', maxLines: 2),
          _sectionLabel('Thermals'),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'Hot', label: Text('Hot')),
              ButtonSegment(value: 'Chilly', label: Text('Chilly')),
              ButtonSegment(value: 'Ambithermal', label: Text('Ambi')),
            ],
            selected: _thermals.isEmpty ? {} : {_thermals},
            emptySelectionAllowed: true,
            onSelectionChanged: (s) =>
                setState(() => _thermals = s.isEmpty ? '' : s.first),
          ),
          const SizedBox(height: 12),
          _tf('pg.sleep', 'Sleep'),
          _tf('pg.stoolUrine', 'Stool / Urine'),
          _tf('pg.energy', 'Energy'),
        ],
      );

  Widget _buildPastHistoryStep() =>
      _tf('h.past', 'Past history', maxLines: 4);

  Widget _buildFamilyHistoryStep() =>
      _tf('h.family', 'Family history', maxLines: 4);

  Widget _buildExaminationStep() =>
      _tf('exam', 'Examination / Investigations', maxLines: 5);

  Widget _buildTotalityStep() => Column(children: [
        _tf('tot.mental', 'Mental symptoms — one per line', maxLines: 3),
        _tf('tot.physical', 'Physical generals — one per line', maxLines: 3),
        _tf('tot.particulars', 'Particulars — one per line', maxLines: 3),
      ]);

  Widget _buildPrescriptionStep() => Column(children: [
        _tf('rx.remedy', 'Remedy'),
        Row(children: [
          Expanded(child: _tf('rx.potency', 'Potency', hint: '30C / 200C / 1M')),
          const SizedBox(width: 12),
          Expanded(child: _tf('rx.dose', 'Dose')),
        ]),
        _tf('rx.advice', 'Advice', maxLines: 3),
      ]);

  Widget _buildFollowUpStep() => Column(children: [
        _tf('fu.date', 'Follow-up date (YYYY-MM-DD)',
            keyboard: TextInputType.datetime),
        _tf('fu.changes', 'Changes observed', maxLines: 3),
        _tf('fu.remedy', 'Remedy'),
        Row(children: [
          Expanded(child: _tf('fu.potency', 'Potency')),
          const SizedBox(width: 12),
          Expanded(child: _tf('fu.dose', 'Dose')),
        ]),
      ]);

  Widget _buildReviewStep() {
    final cs = Theme.of(context).colorScheme;
    Widget row(String label, String value) => value.isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 110,
                  child: Text(label,
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(color: cs.onSurfaceVariant)),
                ),
                Expanded(child: Text(value)),
              ],
            ),
          );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            row('Patient', _v('p.name')),
            row('Case No.', _v('caseNo')),
            row('Complaint', _v('cc.complaint')),
            row('Nature', _nature.join(', ')),
            row('GNM phase', _gnmPhase),
            row('Remedy',
                [_v('rx.remedy'), _v('rx.potency'), _v('rx.dose')]
                    .where((s) => s.isNotEmpty)
                    .join(' · ')),
            const SizedBox(height: 6),
            Text('Tap "Save Case" below to store this record locally.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // AI remedy suggestion (view mode)
  // -------------------------------------------------------------------------

  Future<void> _suggestRemedy() async {
    final c = widget.existingCase!;
    setState(() => _analyzing = true);
    try {
      // Only the clinically relevant context — CC, Mind, Totality — is sent.
      final caseData = <String, dynamic>{
        'chiefComplaint': c.chiefComplaint.toMap(),
        'mind': c.mind.toMap(),
        'totality': c.totality.toMap(),
      };

      final s = await OpenAIService.instance.getSuggestion(caseData);
      if (!mounted) return;

      final apply = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('AI Suggestion'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${s.remedy} · ${s.potency} · ${s.dose}',
                    style: Theme.of(ctx)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Text(s.reasoning,
                    style: Theme.of(ctx).textTheme.bodyMedium),
                const SizedBox(height: 10),
                Text(
                  'Suggestion only — review before applying. Applying '
                  'overwrites the current prescription fields.',
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: Theme.of(ctx).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Dismiss'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Apply'),
            ),
          ],
        ),
      );

      if (apply == true && mounted) {
        // Sync BOTH the controllers (edit mode) and the object (view mode).
        _c('rx.remedy').text = s.remedy;
        _c('rx.potency').text = s.potency;
        _c('rx.dose').text = s.dose;
        c.prescription
          ..remedy = s.remedy
          ..potency = s.potency
          ..dose = s.dose;
        await DatabaseHelper.instance.updateCase(c);
        if (!mounted) return;
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prescription updated')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Analysis failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  // -------------------------------------------------------------------------
  // Quick follow-up entry (view mode) — bottom sheet
  // -------------------------------------------------------------------------

  final _fuSheetFormKey = GlobalKey<FormState>();

  Future<void> _showAddFollowUpSheet() async {
    final c = widget.existingCase!;

    // Reset sheet fields on every open; date defaults to today (YYYY-MM-DD).
    _c('nfu.date').text = DateTime.now().toIso8601String().split('T').first;
    for (final k in ['nfu.changes', 'nfu.remedy', 'nfu.potency', 'nfu.dose']) {
      _c(k).clear();
    }

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true, // keeps fields above the keyboard
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 4,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Form(
          key: _fuSheetFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add Follow-up',
                  style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 12),
              _tf('nfu.date', 'Date (YYYY-MM-DD) *',
                  keyboard: TextInputType.datetime,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Date is required'
                      : null),
              _tf('nfu.changes', 'Changes observed', maxLines: 3),
              _tf('nfu.remedy', 'Remedy'),
              Row(children: [
                Expanded(child: _tf('nfu.potency', 'Potency')),
                const SizedBox(width: 12),
                Expanded(child: _tf('nfu.dose', 'Dose')),
              ]),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save Follow-up'),
                  onPressed: () {
                    if (!(_fuSheetFormKey.currentState?.validate() ?? false)) {
                      return;
                    }
                    Navigator.pop(ctx, true);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (saved != true || !mounted) return;

    final entry = FollowUp(
      date: _v('nfu.date'),
      changes: _v('nfu.changes'),
      prescription: Prescription(
        remedy: _v('nfu.remedy'),
        potency: _v('nfu.potency'),
        dose: _v('nfu.dose'),
      ),
    );

    c.followUps.add(entry);
    try {
      await DatabaseHelper.instance.updateCase(c);
      if (!mounted) return;
      setState(() {}); // read-only view re-renders with the new card
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Follow-up added')),
      );
    } catch (e) {
      c.followUps.remove(entry); // roll back the in-memory append on failure
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    }
  }

  // -------------------------------------------------------------------------
  // Delete
  // -------------------------------------------------------------------------

  Future<void> _confirmDelete() async {
    final c = widget.existingCase!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete case?'),
        content: Text(
            'This permanently deletes "${c.patient.name}" (#${c.caseNo}) '
            'from local storage. Consider running a backup first.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await DatabaseHelper.instance.deleteCase(c.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Case deleted')),
    );
    Navigator.pop(context);
  }

  // -------------------------------------------------------------------------
  // Read-only detail view (view mode)
  // -------------------------------------------------------------------------

  Widget _kv(String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: cs.onSurfaceVariant)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _viewSection(String title, List<Widget> rows) {
    // _kv() renders empty values as SizedBox.shrink — hide empty sections.
    if (rows.whereType<Padding>().isEmpty) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(color: Theme.of(context).colorScheme.primary)),
            const SizedBox(height: 8),
            ...rows,
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyView() {
    final c = widget.existingCase!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 96), // clear the FAB
      children: [
        _viewSection('Patient', [
          _kv('Name', c.patient.name),
          _kv(
              'Age / Sex',
              [
                if (c.patient.age != null) '${c.patient.age}y',
                if (c.patient.sex.isNotEmpty) c.patient.sex,
              ].join(' / ')),
          _kv('Occupation', c.patient.occupation),
          _kv('Case No.', c.caseNo),
          _kv('Date', c.date.split('T').first),
        ]),
        _viewSection('Chief Complaint (LSMC)', [
          _kv('Complaint', c.chiefComplaint.complaint),
          _kv('Location', c.chiefComplaint.location),
          _kv('Sensation', c.chiefComplaint.sensation),
          _kv('Modalities', c.chiefComplaint.modalities),
          _kv('Concomitants', c.chiefComplaint.concomitants),
          _kv('Duration', c.chiefComplaint.duration),
          _kv('Onset / From', c.chiefComplaint.onsetAilmentsFrom),
        ]),
        _viewSection('Mind', [
          _kv('Nature', c.mind.nature.join(', ')),
          _kv('Conflict', c.mind.mainEmotionalConflict),
          _kv('Fears', c.mind.fears.join(', ')),
          _kv('Stress / Trigger', c.mind.stressTriggerEvent),
          _kv('Relationships', c.mind.relationships),
        ]),
        _viewSection('GNM Assessment', [
          _kv('DHS / Conflict', c.gnm.dhsBiologicalConflict),
          _kv('Theme', c.gnm.conflictTheme),
          _kv('Phase', c.gnm.phase),
        ]),
        _viewSection('Physical Generals', [
          _kv('Appetite', c.physicalGenerals.appetite),
          _kv('Thirst', c.physicalGenerals.thirst),
          _kv('Desires / Aversions', c.physicalGenerals.desiresAversions),
          _kv('Thermals', c.physicalGenerals.thermals),
          _kv('Sleep', c.physicalGenerals.sleep),
          _kv('Stool / Urine', c.physicalGenerals.stoolUrine),
          _kv('Energy', c.physicalGenerals.energy),
        ]),
        _viewSection('History', [
          _kv('Past', c.history.pastHistory),
          _kv('Family', c.history.familyHistory),
        ]),
        _viewSection('Examination / Investigations', [
          _kv('Findings', c.examinationInvestigations),
        ]),
        _viewSection('Totality', [
          _kv('Mental', c.totality.mental.join('; ')),
          _kv('Physical', c.totality.physical.join('; ')),
          _kv('Particulars', c.totality.particulars.join('; ')),
        ]),
        _viewSection('Prescription', [
          _kv('Remedy', c.prescription.remedy),
          _kv('Potency', c.prescription.potency),
          _kv('Dose', c.prescription.dose),
          _kv('Advice', c.prescription.advice),
        ]),
        for (var i = 0; i < c.followUps.length; i++)
          _viewSection('Follow-up ${i + 1}', [
            _kv('Date', c.followUps[i].date),
            _kv('Changes', c.followUps[i].changes),
            _kv(
                'Prescription',
                [
                  c.followUps[i].prescription.remedy,
                  c.followUps[i].prescription.potency,
                  c.followUps[i].prescription.dose,
                ].where((s) => s.isNotEmpty).join(' · ')),
          ]),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Stepper scaffold
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final steps = <(String, Widget)>[
      ('Patient Details', _buildPatientStep()),
      ('Chief Complaint (LSMC)', _buildChiefComplaintStep()),
      ('Mind Assessment', _buildMindStep()),
      ('GNM Assessment', _buildGnmStep()),
      ('Physical Generals', _buildPhysicalGeneralsStep()),
      ('Past History', _buildPastHistoryStep()),
      ('Family History', _buildFamilyHistoryStep()),
      ('Examination / Investigations', _buildExaminationStep()),
      ('Totality', _buildTotalityStep()),
      ('Prescription', _buildPrescriptionStep()),
      ('Follow-up (Initial)', _buildFollowUpStep()),
      ('Review & Save', _buildReviewStep()),
    ];
    final lastIndex = steps.length - 1;

    final existing = widget.existingCase;
    return Scaffold(
      appBar: AppBar(
        title: Text(existing == null
            ? 'New Case'
            : (_viewMode ? existing.patient.name : 'Edit Case')),
        actions: [
          if (existing != null && _viewMode)
            IconButton(
              icon: _analyzing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.auto_awesome_outlined),
              tooltip: 'Analyze (AI remedy suggestion)',
              onPressed: _analyzing ? null : _suggestRemedy,
            ),
          if (existing != null && _viewMode)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit case',
              onPressed: () => setState(() => _viewMode = false),
            ),
          if (existing != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete case',
              onPressed: _confirmDelete,
            ),
        ],
      ),
      floatingActionButton: (existing != null && _viewMode)
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.post_add_outlined),
              label: const Text('Add Follow-up'),
              onPressed: _showAddFollowUpSheet,
            )
          : null,
      body: _viewMode
          ? _buildReadOnlyView()
          : Form(
        key: _formKey,
        child: Stepper(
          type: StepperType.vertical,
          currentStep: _currentStep,
          onStepTapped: (i) => setState(() => _currentStep = i),
          onStepContinue: () {
            if (_currentStep < lastIndex) {
              setState(() => _currentStep++);
            } else {
              _saveCase();
            }
          },
          onStepCancel: _currentStep == 0
              ? null
              : () => setState(() => _currentStep--),
          controlsBuilder: (context, details) {
            final isLast = _currentStep == lastIndex;
            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(children: [
                FilledButton.icon(
                  onPressed: _saving ? null : details.onStepContinue,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(isLast ? Icons.save_outlined : Icons.arrow_forward),
                  label: Text(isLast
                      ? (widget.existingCase == null
                          ? 'Save Case'
                          : 'Update Case')
                      : 'Continue'),
                ),
                const SizedBox(width: 8),
                if (details.onStepCancel != null)
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: const Text('Back'),
                  ),
              ]),
            );
          },
          steps: [
            for (var i = 0; i < steps.length; i++)
              Step(
                title: Text(steps[i].$1),
                content: steps[i].$2,
                isActive: _currentStep >= i,
                state: _currentStep > i
                    ? StepState.complete
                    : (_currentStep == i
                        ? StepState.editing
                        : StepState.indexed),
              ),
          ],
        ),
      ),
    );
  }
}
