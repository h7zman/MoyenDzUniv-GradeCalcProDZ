import 'dart:math';

enum UniversitySystemType {
  engineering('engineering', 'Engineering Track'),
  lmd('lmd', 'LMD System');

  const UniversitySystemType(this.storageValue, this.label);

  final String storageValue;
  final String label;

  static UniversitySystemType fromStorage(Object? value) {
    final normalized = value?.toString().trim().toLowerCase();
    for (final type in values) {
      if (type.storageValue == normalized || type.name == normalized) {
        return type;
      }
    }
    return UniversitySystemType.engineering;
  }
}

enum TeachingUnitType {
  fundamental('fundamental', 'Fundamental'),
  discovery('discovery', 'Discovery'),
  methodological('methodological', 'Methodological'),
  transversal('transversal', 'Transversal');

  const TeachingUnitType(this.storageValue, this.label);

  final String storageValue;
  final String label;

  static TeachingUnitType fromStorage(Object? value) {
    final normalized = value?.toString().trim().toLowerCase();
    for (final type in values) {
      if (type.storageValue == normalized || type.name == normalized) {
        return type;
      }
    }
    return TeachingUnitType.fundamental;
  }
}

class Subject {
  const Subject({
    required this.id,
    required this.name,
    required this.coefficient,
    required this.credits,
    required this.tdGrade,
    required this.examGrade,
    this.rattrapageGrade,
  });

  final String id;
  final String name;
  final double coefficient;
  final double credits;
  final double? tdGrade;
  final double? examGrade;
  final double? rattrapageGrade;

  static Subject? fromModule(Module module) {
    final errors = <String>[];
    final calc = ModuleCalc.fromModule(module);
    final coefficient = _parseCoefficient(module.coeff, errors);
    final credits = _parseCredits(module.credits, errors);
    if (coefficient == null || credits == null) {
      return null;
    }

    return Subject(
      id: module.id,
      name: module.name,
      coefficient: coefficient,
      credits: credits,
      tdGrade: calc.cc,
      examGrade: calc.exam,
      rattrapageGrade: calc.rattrapage,
    );
  }
}

class TeachingUnit {
  const TeachingUnit({
    required this.id,
    required this.name,
    required this.type,
    required this.subjects,
  });

  final String id;
  final String name;
  final TeachingUnitType type;
  final List<Subject> subjects;

  double get totalCredits =>
      subjects.fold(0.0, (sum, subject) => sum + max(0.0, subject.credits));

  double get totalCoefficients =>
      subjects.fold(0.0, (sum, subject) => sum + max(0.0, subject.coefficient));
}

class Module {
  Module({
    required this.id,
    required this.name,
    required this.coeff,
    required this.td,
    required this.tp,
    required this.exam,
    required this.examPercentage,
    required this.ccPercentage,
    required this.splitMode,
    this.credits = '0',
    this.rattrapage = '',
    this.unitId = 'ue_default',
    this.unitName = 'General UE',
    this.unitType = TeachingUnitType.fundamental,
    this.isLocked = false,
    this.isCollapsed = false,
  });

  String id;
  String name;
  String coeff;
  String td;
  String tp;
  String exam;
  int examPercentage;
  int ccPercentage;
  String splitMode;
  String credits;
  String rattrapage;
  String unitId;
  String unitName;
  TeachingUnitType unitType;
  bool isLocked;
  bool isCollapsed;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'coeff': coeff,
    'td': td,
    'tp': tp,
    'exam': exam,
    'examPercentage': examPercentage,
    'ccPercentage': ccPercentage,
    'splitMode': splitMode,
    'credits': credits,
    'rattrapage': rattrapage,
    'unitId': unitId,
    'unitName': unitName,
    'unitType': unitType.storageValue,
    'isLocked': isLocked,
    'isCollapsed': isCollapsed,
  };

  factory Module.fromJson(Map<String, dynamic> json) {
    return Module(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? 'Module',
      coeff: (json['coeff'] as String?) ?? '',
      td: (json['td'] as String?) ?? '',
      tp: (json['tp'] as String?) ?? '',
      exam: (json['exam'] as String?) ?? '',
      examPercentage: (json['examPercentage'] as int?) ?? 60,
      ccPercentage: (json['ccPercentage'] as int?) ?? 40,
      splitMode: (json['splitMode'] as String?) ?? '60_40',
      credits: (json['credits'] as String?) ?? '0',
      rattrapage:
          (json['rattrapage'] as String?) ??
          (json['rattrapageGrade'] as String?) ??
          '',
      unitId: (json['unitId'] as String?) ?? 'ue_default',
      unitName: (json['unitName'] as String?) ?? 'General UE',
      unitType: TeachingUnitType.fromStorage(json['unitType']),
      isLocked: (json['isLocked'] as bool?) ?? false,
      isCollapsed: (json['isCollapsed'] as bool?) ?? false,
    );
  }

  factory Module.fromSubject(Subject subject, TeachingUnit unit) {
    return Module(
      id: subject.id,
      name: subject.name,
      coeff: _numberToEditableText(subject.coefficient),
      td: _nullableNumberToEditableText(subject.tdGrade),
      tp: '',
      exam: _nullableNumberToEditableText(subject.examGrade),
      examPercentage: 60,
      ccPercentage: 40,
      splitMode: '60_40',
      credits: _numberToEditableText(subject.credits),
      rattrapage: _nullableNumberToEditableText(subject.rattrapageGrade),
      unitId: unit.id,
      unitName: unit.name,
      unitType: unit.type,
    );
  }

  Module copyWith({
    String? id,
    String? name,
    String? coeff,
    String? td,
    String? tp,
    String? exam,
    int? examPercentage,
    int? ccPercentage,
    String? splitMode,
    String? credits,
    String? rattrapage,
    String? unitId,
    String? unitName,
    TeachingUnitType? unitType,
    bool? isLocked,
    bool? isCollapsed,
  }) {
    return Module(
      id: id ?? this.id,
      name: name ?? this.name,
      coeff: coeff ?? this.coeff,
      td: td ?? this.td,
      tp: tp ?? this.tp,
      exam: exam ?? this.exam,
      examPercentage: examPercentage ?? this.examPercentage,
      ccPercentage: ccPercentage ?? this.ccPercentage,
      splitMode: splitMode ?? this.splitMode,
      credits: credits ?? this.credits,
      rattrapage: rattrapage ?? this.rattrapage,
      unitId: unitId ?? this.unitId,
      unitName: unitName ?? this.unitName,
      unitType: unitType ?? this.unitType,
      isLocked: isLocked ?? this.isLocked,
      isCollapsed: isCollapsed ?? this.isCollapsed,
    );
  }
}

class Semester {
  Semester({
    required this.id,
    required this.name,
    required this.modules,
    this.systemType = UniversitySystemType.engineering,
  });

  factory Semester.fromUnits({
    required String id,
    required String name,
    required UniversitySystemType systemType,
    required List<TeachingUnit> units,
  }) {
    return Semester(
      id: id,
      name: name,
      systemType: systemType,
      modules: [
        for (final unit in units)
          for (final subject in unit.subjects)
            Module.fromSubject(subject, unit),
      ],
    );
  }

  String id;
  String name;
  List<Module> modules;
  UniversitySystemType systemType;

  List<TeachingUnit> get units {
    final grouped = <String, List<Subject>>{};
    final unitNames = <String, String>{};
    final unitTypes = <String, TeachingUnitType>{};

    for (final module in modules) {
      final subject = Subject.fromModule(module);
      if (subject == null) {
        continue;
      }
      final unitId = module.unitId.trim().isEmpty
          ? 'ue_default'
          : module.unitId.trim();
      grouped.putIfAbsent(unitId, () => <Subject>[]).add(subject);
      unitNames[unitId] = module.unitName.trim().isEmpty
          ? 'General UE'
          : module.unitName.trim();
      unitTypes[unitId] = module.unitType;
    }

    return [
      for (final entry in grouped.entries)
        TeachingUnit(
          id: entry.key,
          name: unitNames[entry.key] ?? 'General UE',
          type: unitTypes[entry.key] ?? TeachingUnitType.fundamental,
          subjects: List<Subject>.unmodifiable(entry.value),
        ),
    ];
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'systemType': systemType.storageValue,
    'modules': modules.map((m) => m.toJson()).toList(),
  };

  factory Semester.fromJson(Map<String, dynamic> json) {
    final modules = (json['modules'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(Module.fromJson)
        .toList();
    return Semester(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? 'S1',
      modules: modules,
      systemType: UniversitySystemType.fromStorage(json['systemType']),
    );
  }

  Semester copyWith({
    String? id,
    String? name,
    List<Module>? modules,
    UniversitySystemType? systemType,
  }) {
    return Semester(
      id: id ?? this.id,
      name: name ?? this.name,
      modules: modules ?? this.modules,
      systemType: systemType ?? this.systemType,
    );
  }
}

class SemesterTemplate {
  SemesterTemplate({
    required this.id,
    required this.name,
    required this.modules,
    this.systemType = UniversitySystemType.engineering,
  });

  String id;
  String name;
  List<Module> modules;
  UniversitySystemType systemType;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'systemType': systemType.storageValue,
    'modules': modules.map((m) => m.toJson()).toList(),
  };

  factory SemesterTemplate.fromJson(Map<String, dynamic> json) {
    final modules = (json['modules'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(Module.fromJson)
        .toList();
    return SemesterTemplate(
      id:
          (json['id'] as String?) ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: (json['name'] as String?) ?? 'Template',
      modules: modules,
      systemType: UniversitySystemType.fromStorage(json['systemType']),
    );
  }
}

class ModuleCalc {
  const ModuleCalc({
    required this.coefficient,
    required this.td,
    required this.tp,
    required this.exam,
    required this.rattrapage,
    required this.effectiveExam,
    required this.cc,
    required this.finalGrade,
    required this.errors,
    required this.percentagesValid,
  });

  final double? coefficient;
  final double? td;
  final double? tp;
  final double? exam;
  final double? rattrapage;
  final double? effectiveExam;
  final double? cc;
  final double? finalGrade;
  final List<String> errors;
  final bool percentagesValid;

  bool get hasValidFinal => finalGrade != null;

  static ModuleCalc fromModule(Module module) {
    final errors = <String>[];
    final coefficient = _parseCoefficient(module.coeff, errors);
    final td = _parseGrade(module.td, errors, 'TD');
    final tp = _parseGrade(module.tp, errors, 'TP');
    final exam = _parseGrade(module.exam, errors, 'Exam');
    final rattrapage = _parseGrade(module.rattrapage, errors, 'Rattrapage');

    final percentagesValid =
        (module.examPercentage + module.ccPercentage) == 100;
    if (!percentagesValid) {
      errors.add('Split must equal 100');
    }

    double? cc;
    if (td != null && tp != null) {
      cc = (td + tp) / 2;
    } else if (td != null) {
      cc = td;
    } else if (tp != null) {
      cc = tp;
    }

    final originalGrade = _finalGradeForInputs(
      module: module,
      examGrade: exam,
      cc: cc,
      percentagesValid: percentagesValid,
    );
    final canUseRattrapage = originalGrade != null && originalGrade < 10;
    final effectiveExam = canUseRattrapage
        ? _bestExamGrade(exam, rattrapage)
        : exam;
    double? finalGrade;
    if (percentagesValid) {
      finalGrade = _finalGradeForInputs(
        module: module,
        examGrade: effectiveExam,
        cc: cc,
        percentagesValid: percentagesValid,
      );
    }

    return ModuleCalc(
      coefficient: coefficient,
      td: td,
      tp: tp,
      exam: exam,
      rattrapage: rattrapage,
      effectiveExam: effectiveExam,
      cc: cc,
      finalGrade: finalGrade,
      errors: errors,
      percentagesValid: percentagesValid,
    );
  }
}

double? _finalGradeForInputs({
  required Module module,
  required double? examGrade,
  required double? cc,
  required bool percentagesValid,
}) {
  if (!percentagesValid) {
    return null;
  }
  if (examGrade != null && cc == null) {
    return examGrade;
  }
  final requiresExam = module.examPercentage > 0;
  final requiresCc = module.ccPercentage > 0;
  final hasExamForFinal = !requiresExam || examGrade != null;
  final hasCcForFinal = !requiresCc || cc != null;
  if (!hasExamForFinal || !hasCcForFinal) {
    return null;
  }
  return ((examGrade ?? 0) * module.examPercentage / 100) +
      ((cc ?? 0) * module.ccPercentage / 100);
}

enum SubjectGradeStatus {
  pending,
  passed,
  compensated,
  debt,
  failed,
  eliminatory,
}

enum LmdProgressionLevel {
  l1ToL2(30, 'L1 to L2'),
  l2ToL3(90, 'L2 to L3'),
  graduation(180, 'Graduation');

  const LmdProgressionLevel(this.requiredCredits, this.label);

  final int requiredCredits;
  final String label;
}

class LmdProgressionDecision {
  const LmdProgressionDecision({
    required this.level,
    required this.cumulativeCredits,
    required this.requiredCredits,
    required this.isEligible,
  });

  final LmdProgressionLevel level;
  final int cumulativeCredits;
  final int requiredCredits;
  final bool isEligible;
}

class AcademicEngine {
  const AcademicEngine._();

  static const double lmdTdWeight = 0.4;
  static const double lmdExamWeight = 0.6;
  static const int lmdSemesterCredits = 30;
  static const double rachatLowerBound = 9.95;
  static const double engineeringEliminatoryThreshold = 5.0;

  static double subjectAverage({
    required double tdGrade,
    required double examGrade,
  }) {
    _assertGrade(tdGrade, 'tdGrade');
    _assertGrade(examGrade, 'examGrade');
    return (tdGrade * lmdTdWeight) + (examGrade * lmdExamWeight);
  }

  static double requiredExamGrade({
    required double tdGrade,
    double targetAverage = 10,
  }) {
    _assertGrade(tdGrade, 'tdGrade');
    _assertGrade(targetAverage, 'targetAverage');
    return (targetAverage - (tdGrade * lmdTdWeight)) / lmdExamWeight;
  }

  static LmdProgressionDecision evaluateLmdProgression({
    required LmdProgressionLevel level,
    required int cumulativeCredits,
  }) {
    if (cumulativeCredits < 0) {
      throw ArgumentError.value(
        cumulativeCredits,
        'cumulativeCredits',
        'Credits cannot be negative.',
      );
    }
    return LmdProgressionDecision(
      level: level,
      cumulativeCredits: cumulativeCredits,
      requiredCredits: level.requiredCredits,
      isEligible: cumulativeCredits >= level.requiredCredits,
    );
  }

  static SemesterGradeResult calculateSemester(Semester semester) {
    return switch (semester.systemType) {
      UniversitySystemType.lmd => _calculateLmdSemester(semester),
      UniversitySystemType.engineering => _calculateEngineeringSemester(
        semester,
      ),
    };
  }

  static SemesterGradeResult _calculateEngineeringSemester(Semester semester) {
    final subjects = <SubjectGradeResult>[];
    var weightedSum = 0.0;
    var gradedCoefficients = 0.0;
    var totalCoefficients = 0.0;
    var hasEliminatoryFailure = false;

    for (final module in semester.modules) {
      final calc = ModuleCalc.fromModule(module);
      final coefficient = calc.coefficient;
      final originalAverage = _moduleAverageWithExam(module, calc, calc.exam);
      final makeupExam = _bestExamGrade(calc.exam, calc.rattrapage);
      final makeupAverage = _moduleAverageWithExam(module, calc, makeupExam);
      final isMakeupEligible =
          originalAverage != null && originalAverage < 10.0;
      final average = isMakeupEligible
          ? _bestAverage(originalAverage, makeupAverage)
          : originalAverage;
      final usedRattrapage =
          isMakeupEligible &&
          calc.rattrapage != null &&
          average != null &&
          average > originalAverage;
      final isEliminatory =
          average != null && average < engineeringEliminatoryThreshold;
      hasEliminatoryFailure = hasEliminatoryFailure || isEliminatory;

      if (coefficient != null) {
        totalCoefficients += max(0.0, coefficient);
      }
      if (coefficient != null && coefficient > 0 && average != null) {
        weightedSum += average * coefficient;
        gradedCoefficients += coefficient;
      }

      subjects.add(
        SubjectGradeResult(
          module: module,
          coefficient: coefficient,
          credits: null,
          average: average,
          originalAverage: originalAverage,
          earnedCredits: 0,
          errors: calc.errors,
          status: _engineeringSubjectStatus(average, isEliminatory),
          isMakeupEligible: isMakeupEligible,
          usedRattrapage: usedRattrapage,
          isEliminatory: isEliminatory,
        ),
      );
    }

    final average = gradedCoefficients > 0
        ? weightedSum / gradedCoefficients
        : null;
    final isValidated =
        average != null && average >= 10.0 && !hasEliminatoryFailure;

    return SemesterGradeResult(
      systemType: UniversitySystemType.engineering,
      average: average,
      isValidated: isValidated,
      totalCredits: 0,
      earnedCredits: 0,
      totalCoefficients: totalCoefficients,
      gradedCoefficients: gradedCoefficients,
      flatSubjects: subjects,
      units: const [],
      hasEliminatoryFailure: hasEliminatoryFailure,
      eliminatoryThreshold: engineeringEliminatoryThreshold,
    );
  }

  static SemesterGradeResult _calculateLmdSemester(Semester semester) {
    final draftBuckets = <String, _DraftUnitBucket>{};
    var totalCoefficients = 0.0;

    for (final module in semester.modules) {
      final calc = ModuleCalc.fromModule(module);
      final creditErrors = <String>[];
      final credits = _parseCredits(module.credits, creditErrors);
      final coefficient = calc.coefficient;
      final originalAverage = _lmdAverageWithExam(module, calc, calc.exam);
      final makeupExam = _bestExamGrade(calc.exam, calc.rattrapage);
      final makeupAverage = _lmdAverageWithExam(module, calc, makeupExam);

      if (coefficient != null) {
        totalCoefficients += max(0.0, coefficient);
      }

      final unitId = module.unitId.trim().isEmpty
          ? 'ue_default'
          : module.unitId.trim();
      final bucket = draftBuckets.putIfAbsent(
        unitId,
        () => _DraftUnitBucket(
          id: unitId,
          name: module.unitName.trim().isEmpty
              ? 'General UE'
              : module.unitName.trim(),
          type: module.unitType,
        ),
      );
      bucket.subjects.add(
        _SubjectDraft(
          module: module,
          coefficient: coefficient,
          credits: credits,
          originalAverage: originalAverage,
          makeupAverage: makeupAverage,
          rattrapageGrade: calc.rattrapage,
          errors: [...calc.errors, ...creditErrors],
        ),
      );
    }

    final unitBuckets = <_UnitBucket>[];
    for (final draftBucket in draftBuckets.values) {
      final subjects = <SubjectGradeResult>[];

      for (final draft in draftBucket.subjects) {
        final isMakeupEligible =
            draft.originalAverage != null && draft.originalAverage! < 10.0;
        final average = isMakeupEligible
            ? _bestAverage(draft.originalAverage, draft.makeupAverage)
            : draft.originalAverage;
        final usedRattrapage =
            isMakeupEligible &&
            draft.rattrapageGrade != null &&
            average != null &&
            draft.originalAverage != null &&
            average > draft.originalAverage!;

        subjects.add(
          SubjectGradeResult(
            module: draft.module,
            coefficient: draft.coefficient,
            credits: draft.credits,
            average: average,
            originalAverage: draft.originalAverage,
            earnedCredits: 0,
            errors: draft.errors,
            isMakeupEligible: isMakeupEligible,
            usedRattrapage: usedRattrapage,
          ),
        );
      }

      unitBuckets.add(
        _UnitBucket(
          id: draftBucket.id,
          name: draftBucket.name,
          type: draftBucket.type,
          subjects: subjects,
        ),
      );
    }

    final flatBeforeCreditStatus = <SubjectGradeResult>[
      for (final unit in unitBuckets) ...unit.subjects,
    ];
    final semesterAverage = _weightedSubjectAverage(flatBeforeCreditStatus);
    final semesterValidated =
        semesterAverage != null && semesterAverage >= 10.0;
    final isRachatEligible =
        !semesterValidated &&
        semesterAverage != null &&
        semesterAverage >= rachatLowerBound &&
        semesterAverage < 10.0;

    final units = [
      for (final bucket in unitBuckets)
        _buildLmdUnitResult(bucket, semesterValidated),
    ];
    final flatSubjects = <SubjectGradeResult>[
      for (final unit in units) ...unit.subjects,
    ];
    final earnedCredits = semesterValidated
        ? lmdSemesterCredits
        : flatSubjects.fold<int>(
            0,
            (sum, subject) => sum + subject.earnedCredits,
          );

    return SemesterGradeResult(
      systemType: UniversitySystemType.lmd,
      average: semesterAverage,
      isValidated: semesterValidated,
      totalCredits: lmdSemesterCredits,
      earnedCredits: earnedCredits.clamp(0, lmdSemesterCredits).toInt(),
      totalCoefficients: totalCoefficients,
      gradedCoefficients: _gradedSubjectCoefficients(flatSubjects),
      flatSubjects: flatSubjects,
      units: units,
      isRachatEligible: isRachatEligible,
      notices: isRachatEligible
          ? const ['Subject to Pedagogical Jury decision.']
          : const [],
    );
  }

  static TeachingUnitGradeResult _buildLmdUnitResult(
    _UnitBucket bucket,
    bool semesterValidated,
  ) {
    var totalCoefficients = 0.0;
    var totalCredits = 0;

    for (final subject in bucket.subjects) {
      final coefficient = subject.coefficient;
      totalCredits += subject.totalCredits;
      if (coefficient != null) {
        totalCoefficients += max(0.0, coefficient);
      }
    }

    final average = _weightedSubjectAverage(bucket.subjects);
    final unitValidated = average != null && average >= 10.0;
    final subjects = [
      for (final subject in bucket.subjects)
        subject.copyWith(
          earnedCredits: _lmdEarnedCredits(
            subject,
            semesterValidated: semesterValidated,
            unitValidated: unitValidated,
          ),
          status: _lmdSubjectStatus(
            subject,
            semesterValidated: semesterValidated,
            unitValidated: unitValidated,
          ),
        ),
    ];
    final earnedCredits = semesterValidated || unitValidated
        ? totalCredits
        : subjects.fold<int>(0, (sum, subject) => sum + subject.earnedCredits);

    return TeachingUnitGradeResult(
      id: bucket.id,
      name: bucket.name,
      type: bucket.type,
      average: average,
      isValidated: unitValidated,
      totalCredits: totalCredits,
      earnedCredits: earnedCredits,
      totalCoefficients: totalCoefficients,
      gradedCoefficients: _gradedSubjectCoefficients(bucket.subjects),
      subjectCount: bucket.subjects.length,
      subjects: subjects,
    );
  }

  static double? _lmdAverageWithExam(
    Module module,
    ModuleCalc calc,
    double? examGrade,
  ) {
    final cc = calc.cc;
    if (examGrade != null && cc == null && calc.percentagesValid) {
      return examGrade;
    }
    final requiresExam = module.examPercentage > 0;
    final requiresCc = module.ccPercentage > 0;
    final hasExamForFinal = !requiresExam || examGrade != null;
    final hasCcForFinal = !requiresCc || cc != null;
    if (!hasExamForFinal || !hasCcForFinal || !calc.percentagesValid) {
      return null;
    }
    return ((examGrade ?? 0) * module.examPercentage / 100) +
        ((cc ?? 0) * module.ccPercentage / 100);
  }

  static double? _moduleAverageWithExam(
    Module module,
    ModuleCalc calc,
    double? examGrade,
  ) {
    if (examGrade != null && calc.cc == null && calc.percentagesValid) {
      return examGrade;
    }
    final requiresExam = module.examPercentage > 0;
    final requiresCc = module.ccPercentage > 0;
    final hasExamForFinal = !requiresExam || examGrade != null;
    final hasCcForFinal = !requiresCc || calc.cc != null;
    if (!hasExamForFinal || !hasCcForFinal || !calc.percentagesValid) {
      return null;
    }
    return ((examGrade ?? 0) * module.examPercentage / 100) +
        ((calc.cc ?? 0) * module.ccPercentage / 100);
  }

  static double? _bestAverage(double? original, double? makeup) {
    if (original == null) {
      return makeup;
    }
    if (makeup == null) {
      return original;
    }
    return max(original, makeup);
  }

  static double? _weightedSubjectAverage(List<SubjectGradeResult> subjects) {
    var weightedSum = 0.0;
    var coefficients = 0.0;
    for (final subject in subjects) {
      final coefficient = subject.coefficient;
      final average = subject.average;
      if (coefficient != null && coefficient > 0 && average != null) {
        weightedSum += average * coefficient;
        coefficients += coefficient;
      }
    }
    return coefficients > 0 ? weightedSum / coefficients : null;
  }

  static double _gradedSubjectCoefficients(List<SubjectGradeResult> subjects) {
    var coefficients = 0.0;
    for (final subject in subjects) {
      final coefficient = subject.coefficient;
      if (coefficient != null && coefficient > 0 && subject.average != null) {
        coefficients += coefficient;
      }
    }
    return coefficients;
  }

  static int _lmdEarnedCredits(
    SubjectGradeResult subject, {
    required bool semesterValidated,
    required bool unitValidated,
  }) {
    if (semesterValidated || unitValidated || subject.isPassed) {
      return subject.totalCredits;
    }
    return 0;
  }

  static SubjectGradeStatus _lmdSubjectStatus(
    SubjectGradeResult subject, {
    required bool semesterValidated,
    required bool unitValidated,
  }) {
    if (subject.average == null) {
      return SubjectGradeStatus.pending;
    }
    if (subject.isPassed) {
      return SubjectGradeStatus.passed;
    }
    if (semesterValidated || unitValidated) {
      return SubjectGradeStatus.compensated;
    }
    return SubjectGradeStatus.debt;
  }

  static SubjectGradeStatus _engineeringSubjectStatus(
    double? average,
    bool isEliminatory,
  ) {
    if (average == null) {
      return SubjectGradeStatus.pending;
    }
    if (isEliminatory) {
      return SubjectGradeStatus.eliminatory;
    }
    return average >= 10.0
        ? SubjectGradeStatus.passed
        : SubjectGradeStatus.failed;
  }

  static void _assertGrade(double value, String label) {
    if (!value.isFinite || value < 0 || value > 20) {
      throw ArgumentError.value(
        value,
        label,
        'Grade must be between 0 and 20.',
      );
    }
  }
}

class UniversityGradeEngine {
  const UniversityGradeEngine._();

  static const double lmdTdWeight = AcademicEngine.lmdTdWeight;
  static const double lmdExamWeight = AcademicEngine.lmdExamWeight;
  static const int lmdSemesterCredits = AcademicEngine.lmdSemesterCredits;
  static const double rachatLowerBound = AcademicEngine.rachatLowerBound;
  static const double engineeringEliminatoryThreshold =
      AcademicEngine.engineeringEliminatoryThreshold;

  static double subjectAverage({
    required double tdGrade,
    required double examGrade,
  }) {
    return AcademicEngine.subjectAverage(
      tdGrade: tdGrade,
      examGrade: examGrade,
    );
  }

  static double requiredExamGrade({
    required double tdGrade,
    double targetAverage = 10,
  }) {
    return AcademicEngine.requiredExamGrade(
      tdGrade: tdGrade,
      targetAverage: targetAverage,
    );
  }

  static LmdProgressionDecision evaluateLmdProgression({
    required LmdProgressionLevel level,
    required int cumulativeCredits,
  }) {
    return AcademicEngine.evaluateLmdProgression(
      level: level,
      cumulativeCredits: cumulativeCredits,
    );
  }

  static SemesterGradeResult calculateSemester(Semester semester) {
    return AcademicEngine.calculateSemester(semester);
  }
}

class SemesterGradeResult {
  const SemesterGradeResult({
    required this.systemType,
    required this.average,
    required this.isValidated,
    required this.totalCredits,
    required this.earnedCredits,
    required this.totalCoefficients,
    required this.gradedCoefficients,
    required this.flatSubjects,
    required this.units,
    this.isRachatEligible = false,
    this.hasEliminatoryFailure = false,
    this.eliminatoryThreshold,
    this.notices = const [],
  });

  final UniversitySystemType systemType;
  final double? average;
  final bool isValidated;
  final int totalCredits;
  final int earnedCredits;
  final double totalCoefficients;
  final double gradedCoefficients;
  final List<SubjectGradeResult> flatSubjects;
  final List<TeachingUnitGradeResult> units;
  final bool isRachatEligible;
  final bool hasEliminatoryFailure;
  final double? eliminatoryThreshold;
  final List<String> notices;

  int get totalModules => flatSubjects.length;

  int get gradedModules =>
      flatSubjects.where((subject) => subject.average != null).length;

  int get passedModules =>
      flatSubjects.where((subject) => subject.isPassed).length;
}

class TeachingUnitGradeResult {
  const TeachingUnitGradeResult({
    required this.id,
    required this.name,
    required this.type,
    required this.average,
    required this.isValidated,
    required this.totalCredits,
    required this.earnedCredits,
    required this.totalCoefficients,
    required this.gradedCoefficients,
    required this.subjectCount,
    required this.subjects,
  });

  final String id;
  final String name;
  final TeachingUnitType type;
  final double? average;
  final bool isValidated;
  final int totalCredits;
  final int earnedCredits;
  final double totalCoefficients;
  final double gradedCoefficients;
  final int subjectCount;
  final List<SubjectGradeResult> subjects;
}

class SubjectGradeResult {
  const SubjectGradeResult({
    required this.module,
    required this.coefficient,
    required this.credits,
    required this.average,
    required this.earnedCredits,
    required this.errors,
    this.originalAverage,
    this.status = SubjectGradeStatus.pending,
    this.isMakeupEligible = false,
    this.usedRattrapage = false,
    this.isEliminatory = false,
  });

  final Module module;
  final double? coefficient;
  final double? credits;
  final double? average;
  final double? originalAverage;
  final int earnedCredits;
  final List<String> errors;
  final SubjectGradeStatus status;
  final bool isMakeupEligible;
  final bool usedRattrapage;
  final bool isEliminatory;

  int get totalCredits => (credits ?? 0).round().clamp(0, 999).toInt();

  bool get isPassed => average != null && average! >= 10.0;

  bool get isDebt => status == SubjectGradeStatus.debt;

  SubjectGradeResult copyWith({
    int? earnedCredits,
    SubjectGradeStatus? status,
  }) {
    return SubjectGradeResult(
      module: module,
      coefficient: coefficient,
      credits: credits,
      average: average,
      originalAverage: originalAverage,
      earnedCredits: earnedCredits ?? this.earnedCredits,
      errors: errors,
      status: status ?? this.status,
      isMakeupEligible: isMakeupEligible,
      usedRattrapage: usedRattrapage,
      isEliminatory: isEliminatory,
    );
  }
}

class _UnitBucket {
  _UnitBucket({
    required this.id,
    required this.name,
    required this.type,
    required this.subjects,
  });

  final String id;
  final String name;
  final TeachingUnitType type;
  final List<SubjectGradeResult> subjects;
}

class _DraftUnitBucket {
  _DraftUnitBucket({required this.id, required this.name, required this.type});

  final String id;
  final String name;
  final TeachingUnitType type;
  final List<_SubjectDraft> subjects = <_SubjectDraft>[];
}

class _SubjectDraft {
  const _SubjectDraft({
    required this.module,
    required this.coefficient,
    required this.credits,
    required this.originalAverage,
    required this.makeupAverage,
    required this.rattrapageGrade,
    required this.errors,
  });

  final Module module;
  final double? coefficient;
  final double? credits;
  final double? originalAverage;
  final double? makeupAverage;
  final double? rattrapageGrade;
  final List<String> errors;
}

class SemesterCalc {
  const SemesterCalc({
    required this.average,
    required this.totalModules,
    required this.gradedModules,
    required this.passedModules,
    required this.totalCoefficients,
    required this.gradedCoefficients,
    required this.totalCredits,
    required this.earnedCredits,
    required this.systemType,
  });

  final double? average;
  final int totalModules;
  final int gradedModules;
  final int passedModules;
  final double totalCoefficients;
  final double gradedCoefficients;
  final int totalCredits;
  final int earnedCredits;
  final UniversitySystemType systemType;

  static SemesterCalc fromSemester(Semester semester) {
    final result = UniversityGradeEngine.calculateSemester(semester);

    return SemesterCalc(
      average: result.average,
      totalModules: result.totalModules,
      gradedModules: result.gradedModules,
      passedModules: result.passedModules,
      totalCoefficients: result.totalCoefficients,
      gradedCoefficients: result.gradedCoefficients,
      totalCredits: result.totalCredits,
      earnedCredits: result.earnedCredits,
      systemType: result.systemType,
    );
  }
}

class OverallCalc {
  const OverallCalc({
    required this.average,
    required this.totalModules,
    required this.gradedModules,
    required this.passedModules,
    required this.totalCoefficients,
    required this.gradedCoefficients,
  });

  final double? average;
  final int totalModules;
  final int gradedModules;
  final int passedModules;
  final double totalCoefficients;
  final double gradedCoefficients;

  static OverallCalc fromSemesters(List<Semester> semesters) {
    var totalModules = 0;
    var gradedModules = 0;
    var passedModules = 0;
    var totalCoefficients = 0.0;
    var gradedCoefficients = 0.0;
    var weightedSum = 0.0;

    for (final semester in semesters) {
      final calc = SemesterCalc.fromSemester(semester);
      totalModules += calc.totalModules;
      gradedModules += calc.gradedModules;
      passedModules += calc.passedModules;
      totalCoefficients += calc.totalCoefficients;
      gradedCoefficients += calc.gradedCoefficients;
      if (calc.average != null && calc.gradedCoefficients > 0) {
        weightedSum += calc.average! * calc.gradedCoefficients;
      }
    }

    final average = gradedCoefficients > 0
        ? weightedSum / gradedCoefficients
        : null;

    return OverallCalc(
      average: average,
      totalModules: totalModules,
      gradedModules: gradedModules,
      passedModules: passedModules,
      totalCoefficients: totalCoefficients,
      gradedCoefficients: gradedCoefficients,
    );
  }
}

double? _parseOptionalNumber(String raw, List<String> errors, String label) {
  final cleaned = raw.trim();
  if (cleaned.isEmpty) {
    return null;
  }
  final value = double.tryParse(cleaned.replaceAll(',', '.'));
  if (value == null) {
    errors.add('$label is invalid');
    return null;
  }
  return value;
}

double? _parseGrade(String raw, List<String> errors, String label) {
  final value = _parseOptionalNumber(raw, errors, label);
  if (value == null) {
    return null;
  }
  if (value < 0 || value > 20) {
    errors.add('$label must be 0..20');
    return null;
  }
  return value;
}

double? _parseCoefficient(String raw, List<String> errors) {
  final cleaned = raw.trim();
  if (cleaned.isEmpty) {
    errors.add('Coeff required');
    return null;
  }
  final value = _parseOptionalNumber(raw, errors, 'Coeff');
  if (value == null) {
    return null;
  }
  if (value < 1) {
    errors.add('Coeff must be >= 1');
    return null;
  }
  return value;
}

double? _parseCredits(String raw, List<String> errors) {
  final cleaned = raw.trim();
  if (cleaned.isEmpty) {
    return 0;
  }
  final value = _parseOptionalNumber(raw, errors, 'Credits');
  if (value == null) {
    return null;
  }
  if (value < 0 || value > UniversityGradeEngine.lmdSemesterCredits) {
    errors.add('Credits must be 0..30');
    return null;
  }
  return value;
}

double? _bestExamGrade(double? exam, double? rattrapage) {
  if (exam == null) {
    return rattrapage;
  }
  if (rattrapage == null) {
    return exam;
  }
  return max(exam, rattrapage);
}

String _numberToEditableText(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
}

String _nullableNumberToEditableText(double? value) {
  return value == null ? '' : _numberToEditableText(value);
}
