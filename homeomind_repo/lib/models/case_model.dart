// case_model.dart
// HomeoMind — Case data model.
// Strategy: top-level indexed fields (id, caseNo, patientName, date) as real
// SQLite columns; each clinical section stored as a JSON TEXT column so the
// schema stays flexible as the case format evolves.

import 'dart:convert';

// ---------------------------------------------------------------------------
// Section sub-models
// ---------------------------------------------------------------------------

class PatientDetails {
  String name;
  int? age;
  String sex; // 'M' | 'F' | 'Other'
  String occupation;

  PatientDetails({
    this.name = '',
    this.age,
    this.sex = '',
    this.occupation = '',
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'age': age,
        'sex': sex,
        'occupation': occupation,
      };

  factory PatientDetails.fromMap(Map<String, dynamic> m) => PatientDetails(
        name: m['name'] ?? '',
        age: m['age'],
        sex: m['sex'] ?? '',
        occupation: m['occupation'] ?? '',
      );
}

class ChiefComplaint {
  String complaint;
  String location;
  String sensation;
  String modalities; // < worse / > better
  String concomitants;
  String duration;
  String onsetAilmentsFrom;

  ChiefComplaint({
    this.complaint = '',
    this.location = '',
    this.sensation = '',
    this.modalities = '',
    this.concomitants = '',
    this.duration = '',
    this.onsetAilmentsFrom = '',
  });

  Map<String, dynamic> toMap() => {
        'complaint': complaint,
        'location': location,
        'sensation': sensation,
        'modalities': modalities,
        'concomitants': concomitants,
        'duration': duration,
        'onsetAilmentsFrom': onsetAilmentsFrom,
      };

  factory ChiefComplaint.fromMap(Map<String, dynamic> m) => ChiefComplaint(
        complaint: m['complaint'] ?? '',
        location: m['location'] ?? '',
        sensation: m['sensation'] ?? '',
        modalities: m['modalities'] ?? '',
        concomitants: m['concomitants'] ?? '',
        duration: m['duration'] ?? '',
        onsetAilmentsFrom: m['onsetAilmentsFrom'] ?? '',
      );
}

class MindAssessment {
  /// Multi-select from: Mild, Irritable, Reserved, Sensitive, Ambitious,
  /// Fastidious, Responsible, Anxious (plus free-text additions).
  List<String> nature;
  String mainEmotionalConflict;
  List<String> fears;
  String stressTriggerEvent;
  String relationships;

  MindAssessment({
    List<String>? nature,
    this.mainEmotionalConflict = '',
    List<String>? fears,
    this.stressTriggerEvent = '',
    this.relationships = '',
  })  : nature = nature ?? [],
        fears = fears ?? [];

  Map<String, dynamic> toMap() => {
        'nature': nature,
        'mainEmotionalConflict': mainEmotionalConflict,
        'fears': fears,
        'stressTriggerEvent': stressTriggerEvent,
        'relationships': relationships,
      };

  factory MindAssessment.fromMap(Map<String, dynamic> m) => MindAssessment(
        nature: List<String>.from(m['nature'] ?? []),
        mainEmotionalConflict: m['mainEmotionalConflict'] ?? '',
        fears: List<String>.from(m['fears'] ?? []),
        stressTriggerEvent: m['stressTriggerEvent'] ?? '',
        relationships: m['relationships'] ?? '',
      );
}

class GnmAssessment {
  String dhsBiologicalConflict;
  String conflictTheme;
  String phase; // 'Conflict Active' | 'Healing'

  GnmAssessment({
    this.dhsBiologicalConflict = '',
    this.conflictTheme = '',
    this.phase = '',
  });

  Map<String, dynamic> toMap() => {
        'dhsBiologicalConflict': dhsBiologicalConflict,
        'conflictTheme': conflictTheme,
        'phase': phase,
      };

  factory GnmAssessment.fromMap(Map<String, dynamic> m) => GnmAssessment(
        dhsBiologicalConflict: m['dhsBiologicalConflict'] ?? '',
        conflictTheme: m['conflictTheme'] ?? '',
        phase: m['phase'] ?? '',
      );
}

class PhysicalGenerals {
  String appetite;
  String thirst;
  String desiresAversions;
  String thermals; // Hot / Chilly / Ambithermal
  String sleep;
  String stoolUrine;
  String energy;

  PhysicalGenerals({
    this.appetite = '',
    this.thirst = '',
    this.desiresAversions = '',
    this.thermals = '',
    this.sleep = '',
    this.stoolUrine = '',
    this.energy = '',
  });

  Map<String, dynamic> toMap() => {
        'appetite': appetite,
        'thirst': thirst,
        'desiresAversions': desiresAversions,
        'thermals': thermals,
        'sleep': sleep,
        'stoolUrine': stoolUrine,
        'energy': energy,
      };

  factory PhysicalGenerals.fromMap(Map<String, dynamic> m) => PhysicalGenerals(
        appetite: m['appetite'] ?? '',
        thirst: m['thirst'] ?? '',
        desiresAversions: m['desiresAversions'] ?? '',
        thermals: m['thermals'] ?? '',
        sleep: m['sleep'] ?? '',
        stoolUrine: m['stoolUrine'] ?? '',
        energy: m['energy'] ?? '',
      );
}

class CaseHistory {
  String pastHistory;
  String familyHistory;

  CaseHistory({this.pastHistory = '', this.familyHistory = ''});

  Map<String, dynamic> toMap() =>
      {'pastHistory': pastHistory, 'familyHistory': familyHistory};

  factory CaseHistory.fromMap(Map<String, dynamic> m) => CaseHistory(
        pastHistory: m['pastHistory'] ?? '',
        familyHistory: m['familyHistory'] ?? '',
      );
}

class Totality {
  List<String> mental;
  List<String> physical;
  List<String> particulars;

  Totality({List<String>? mental, List<String>? physical, List<String>? particulars})
      : mental = mental ?? [],
        physical = physical ?? [],
        particulars = particulars ?? [];

  Map<String, dynamic> toMap() =>
      {'mental': mental, 'physical': physical, 'particulars': particulars};

  factory Totality.fromMap(Map<String, dynamic> m) => Totality(
        mental: List<String>.from(m['mental'] ?? []),
        physical: List<String>.from(m['physical'] ?? []),
        particulars: List<String>.from(m['particulars'] ?? []),
      );
}

class Prescription {
  String remedy;
  String potency; // e.g. 30C, 200C, 1M
  String dose;
  String advice;

  Prescription({this.remedy = '', this.potency = '', this.dose = '', this.advice = ''});

  Map<String, dynamic> toMap() =>
      {'remedy': remedy, 'potency': potency, 'dose': dose, 'advice': advice};

  factory Prescription.fromMap(Map<String, dynamic> m) => Prescription(
        remedy: m['remedy'] ?? '',
        potency: m['potency'] ?? '',
        dose: m['dose'] ?? '',
        advice: m['advice'] ?? '',
      );
}

class FollowUp {
  String date; // ISO-8601
  String changes;
  Prescription prescription;

  FollowUp({this.date = '', this.changes = '', Prescription? prescription})
      : prescription = prescription ?? Prescription();

  Map<String, dynamic> toMap() =>
      {'date': date, 'changes': changes, 'prescription': prescription.toMap()};

  factory FollowUp.fromMap(Map<String, dynamic> m) => FollowUp(
        date: m['date'] ?? '',
        changes: m['changes'] ?? '',
        prescription: Prescription.fromMap(
            Map<String, dynamic>.from(m['prescription'] ?? {})),
      );
}

// ---------------------------------------------------------------------------
// Root Case model
// ---------------------------------------------------------------------------

class HomeoCase {
  int? id; // SQLite autoincrement PK
  String caseNo; // indexed, unique
  String date; // case-taking date, ISO-8601
  PatientDetails patient;
  ChiefComplaint chiefComplaint;
  MindAssessment mind;
  GnmAssessment gnm;
  PhysicalGenerals physicalGenerals;
  CaseHistory history;
  String examinationInvestigations;
  Totality totality;
  Prescription prescription;
  List<FollowUp> followUps;
  String createdAt;
  String updatedAt;

  HomeoCase({
    this.id,
    this.caseNo = '',
    String? date,
    PatientDetails? patient,
    ChiefComplaint? chiefComplaint,
    MindAssessment? mind,
    GnmAssessment? gnm,
    PhysicalGenerals? physicalGenerals,
    CaseHistory? history,
    this.examinationInvestigations = '',
    Totality? totality,
    Prescription? prescription,
    List<FollowUp>? followUps,
    String? createdAt,
    String? updatedAt,
  })  : date = date ?? DateTime.now().toIso8601String(),
        patient = patient ?? PatientDetails(),
        chiefComplaint = chiefComplaint ?? ChiefComplaint(),
        mind = mind ?? MindAssessment(),
        gnm = gnm ?? GnmAssessment(),
        physicalGenerals = physicalGenerals ?? PhysicalGenerals(),
        history = history ?? CaseHistory(),
        totality = totality ?? Totality(),
        prescription = prescription ?? Prescription(),
        followUps = followUps ?? [],
        createdAt = createdAt ?? DateTime.now().toIso8601String(),
        updatedAt = updatedAt ?? DateTime.now().toIso8601String();

  /// Full JSON representation — used for the zip export and DB round-trip.
  Map<String, dynamic> toJson() => {
        'id': id,
        'caseNo': caseNo,
        'date': date,
        'patient': patient.toMap(),
        'chiefComplaint': chiefComplaint.toMap(),
        'mind': mind.toMap(),
        'gnm': gnm.toMap(),
        'physicalGenerals': physicalGenerals.toMap(),
        'history': history.toMap(),
        'examinationInvestigations': examinationInvestigations,
        'totality': totality.toMap(),
        'prescription': prescription.toMap(),
        'followUps': followUps.map((f) => f.toMap()).toList(),
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  factory HomeoCase.fromJson(Map<String, dynamic> j) => HomeoCase(
        id: j['id'],
        caseNo: j['caseNo'] ?? '',
        date: j['date'],
        patient:
            PatientDetails.fromMap(Map<String, dynamic>.from(j['patient'] ?? {})),
        chiefComplaint: ChiefComplaint.fromMap(
            Map<String, dynamic>.from(j['chiefComplaint'] ?? {})),
        mind: MindAssessment.fromMap(Map<String, dynamic>.from(j['mind'] ?? {})),
        gnm: GnmAssessment.fromMap(Map<String, dynamic>.from(j['gnm'] ?? {})),
        physicalGenerals: PhysicalGenerals.fromMap(
            Map<String, dynamic>.from(j['physicalGenerals'] ?? {})),
        history:
            CaseHistory.fromMap(Map<String, dynamic>.from(j['history'] ?? {})),
        examinationInvestigations: j['examinationInvestigations'] ?? '',
        totality: Totality.fromMap(Map<String, dynamic>.from(j['totality'] ?? {})),
        prescription: Prescription.fromMap(
            Map<String, dynamic>.from(j['prescription'] ?? {})),
        followUps: (j['followUps'] as List? ?? [])
            .map((f) => FollowUp.fromMap(Map<String, dynamic>.from(f)))
            .toList(),
        createdAt: j['createdAt'],
        updatedAt: j['updatedAt'],
      );

  // -------------------------------------------------------------------------
  // SQLite row mapping: indexed columns + one JSON blob per section.
  // -------------------------------------------------------------------------

  Map<String, dynamic> toDbMap() => {
        if (id != null) 'id': id,
        'case_no': caseNo,
        'patient_name': patient.name, // duplicated column for fast LIKE search
        'case_date': date,
        'payload': jsonEncode(toJson()), // full document
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  factory HomeoCase.fromDbMap(Map<String, dynamic> row) {
    final c = HomeoCase.fromJson(
        jsonDecode(row['payload'] as String) as Map<String, dynamic>);
    c.id = row['id'] as int?; // DB id is authoritative
    return c;
  }
}
