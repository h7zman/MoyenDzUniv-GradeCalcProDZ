import 'package:flutter_test/flutter_test.dart';

import 'package:gradecalcprodz/models/grade_models.dart';

Module _module({
  String name = 'M1',
  String td = '',
  String tp = '',
  String exam = '',
  String rattrapage = '',
  String coeff = '1',
  String credits = '0',
  String unitId = 'ue_default',
  String unitName = 'General UE',
  int examPercentage = 60,
  int ccPercentage = 40,
}) {
  return Module(
    id: 'm1',
    name: name,
    coeff: coeff,
    td: td,
    tp: tp,
    exam: exam,
    rattrapage: rattrapage,
    credits: credits,
    unitId: unitId,
    unitName: unitName,
    examPercentage: examPercentage,
    ccPercentage: ccPercentage,
    splitMode: 'custom',
  );
}

void main() {
  test('CC computation: TD + TP', () {
    final calc = ModuleCalc.fromModule(_module(td: '12', tp: '16'));
    expect(calc.cc, 14);
  });

  test('CC computation: only TD', () {
    final calc = ModuleCalc.fromModule(_module(td: '10'));
    expect(calc.cc, 10);
  });

  test('CC computation: only TP', () {
    final calc = ModuleCalc.fromModule(_module(tp: '8'));
    expect(calc.cc, 8);
  });

  test('CC computation: none', () {
    final calc = ModuleCalc.fromModule(_module());
    expect(calc.cc, isNull);
  });

  test('Final grade uses percentages', () {
    final calc = ModuleCalc.fromModule(
      _module(td: '12', exam: '10', examPercentage: 60, ccPercentage: 40),
    );
    expect(calc.finalGrade, closeTo(10.8, 0.0001));
  });

  test('Exam-only module is graded without TD or TP', () {
    final calc = ModuleCalc.fromModule(_module(exam: '14'));
    expect(calc.errors, isNot(contains('Missing CC (no TD/TP)')));
    expect(calc.finalGrade, closeTo(14, 0.0001));
  });

  test('No CC required when split is 100/0', () {
    final calc = ModuleCalc.fromModule(
      _module(exam: '14', examPercentage: 100, ccPercentage: 0),
    );
    expect(calc.errors, isNot(contains('Missing CC (no TD/TP)')));
    expect(calc.finalGrade, closeTo(14, 0.0001));
  });

  test('Split must equal 100', () {
    final calc = ModuleCalc.fromModule(
      _module(td: '10', exam: '10', examPercentage: 70, ccPercentage: 20),
    );
    expect(calc.errors, contains('Split must equal 100'));
  });

  test('Grade validation', () {
    final calc = ModuleCalc.fromModule(_module(td: '30'));
    expect(calc.errors, contains('TD must be 0..20'));
  });

  test('Semester average weighted by coefficient', () {
    final s = Semester(
      id: 's1',
      name: 'S1',
      modules: [
        _module(td: '10', exam: '10', coeff: '2'),
        _module(td: '14', exam: '10', coeff: '1'),
      ],
    );
    final calc = SemesterCalc.fromSemester(s);
    expect(calc.average, closeTo(10.5333, 0.0001));
    expect(calc.gradedModules, 2);
  });

  test('Target finder calculates required exam for a 10 average', () {
    final requiredExam = UniversityGradeEngine.requiredExamGrade(tdGrade: 8);
    expect(requiredExam, closeTo(11.3333, 0.0001));
  });

  test('Rattrapage replaces exam only when higher', () {
    final improved = ModuleCalc.fromModule(
      _module(td: '10', exam: '8', rattrapage: '12'),
    );
    final unchanged = ModuleCalc.fromModule(
      _module(td: '10', exam: '8', rattrapage: '6'),
    );
    final alreadyPassed = ModuleCalc.fromModule(
      _module(td: '12', exam: '12', rattrapage: '18'),
    );

    expect(improved.effectiveExam, 12);
    expect(improved.finalGrade, closeTo(11.2, 0.0001));
    expect(unchanged.effectiveExam, 8);
    expect(unchanged.finalGrade, closeTo(8.8, 0.0001));
    expect(alreadyPassed.effectiveExam, 12);
    expect(alreadyPassed.finalGrade, closeTo(12, 0.0001));
  });

  test('LMD validates UE credits by compensation', () {
    final semester = Semester(
      id: 's1',
      name: 'S1',
      systemType: UniversitySystemType.lmd,
      modules: [
        _module(
          name: 'Algorithms',
          td: '9',
          exam: '9',
          coeff: '1',
          credits: '4',
          unitId: 'ue_fundamental',
          unitName: 'Fundamental',
        ),
        _module(
          name: 'Analysis',
          td: '12',
          exam: '12',
          coeff: '1',
          credits: '2',
          unitId: 'ue_fundamental',
          unitName: 'Fundamental',
        ),
        _module(
          name: 'English',
          td: '8',
          exam: '8',
          coeff: '1',
          credits: '3',
          unitId: 'ue_transversal',
          unitName: 'Transversal',
        ),
      ],
    );

    final result = UniversityGradeEngine.calculateSemester(semester);

    expect(result.average, closeTo(9.6666, 0.0001));
    expect(result.isValidated, isFalse);
    expect(result.units.first.isValidated, isTrue);
    expect(result.units.first.earnedCredits, 6);
    expect(result.flatSubjects.first.earnedCredits, 4);
    expect(result.earnedCredits, 6);
  });

  test('LMD semester compensation grants all 30 credits', () {
    final semester = Semester(
      id: 's1',
      name: 'S1',
      systemType: UniversitySystemType.lmd,
      modules: [
        _module(td: '8', exam: '8', coeff: '1', credits: '6'),
        _module(td: '12', exam: '12', coeff: '2', credits: '12'),
      ],
    );

    final result = UniversityGradeEngine.calculateSemester(semester);

    expect(result.average, closeTo(10.6666, 0.0001));
    expect(result.isValidated, isTrue);
    expect(result.earnedCredits, 30);
  });

  test('LMD applies rattrapage only when the module average is below 10', () {
    final semester = Semester(
      id: 's1',
      name: 'S1',
      systemType: UniversitySystemType.lmd,
      modules: [
        _module(
          name: 'Failed UE Makeup',
          td: '8',
          exam: '8',
          rattrapage: '14',
          credits: '5',
          unitId: 'ue_failed',
          unitName: 'Failed UE',
        ),
        _module(
          name: 'Failed UE Peer',
          td: '9',
          exam: '9',
          credits: '5',
          unitId: 'ue_failed',
          unitName: 'Failed UE',
        ),
        _module(
          name: 'Compensated UE Subject',
          td: '9',
          exam: '9',
          rattrapage: '15',
          credits: '5',
          unitId: 'ue_validated',
          unitName: 'Validated UE',
        ),
        _module(
          name: 'Compensating Subject',
          td: '12',
          exam: '12',
          coeff: '3',
          credits: '5',
          unitId: 'ue_validated',
          unitName: 'Validated UE',
        ),
      ],
    );

    final result = UniversityGradeEngine.calculateSemester(semester);
    final makeup = result.flatSubjects.firstWhere(
      (subject) => subject.module.name == 'Failed UE Makeup',
    );
    final compensated = result.flatSubjects.firstWhere(
      (subject) => subject.module.name == 'Compensated UE Subject',
    );

    expect(makeup.isMakeupEligible, isTrue);
    expect(makeup.usedRattrapage, isTrue);
    expect(makeup.average, closeTo(11.6, 0.0001));
    expect(compensated.isMakeupEligible, isTrue);
    expect(compensated.usedRattrapage, isTrue);
    expect(compensated.average, closeTo(12.6, 0.0001));
  });

  test('LMD marks rescue and debt states', () {
    final rachatSemester = Semester(
      id: 's1',
      name: 'S1',
      systemType: UniversitySystemType.lmd,
      modules: [_module(td: '9.96', exam: '9.96', coeff: '1', credits: '6')],
    );
    final debtSemester = Semester(
      id: 's2',
      name: 'S2',
      systemType: UniversitySystemType.lmd,
      modules: [_module(td: '8', exam: '8', coeff: '1', credits: '6')],
    );

    final rachat = UniversityGradeEngine.calculateSemester(rachatSemester);
    final debt = UniversityGradeEngine.calculateSemester(debtSemester);

    expect(rachat.isValidated, isFalse);
    expect(rachat.isRachatEligible, isTrue);
    expect(rachat.notices, contains('Subject to Pedagogical Jury decision.'));
    expect(debt.flatSubjects.single.status, SubjectGradeStatus.debt);
    expect(debt.flatSubjects.single.earnedCredits, 0);
  });

  test('Engineering eliminatory grade fails year regardless average', () {
    final semester = Semester(
      id: 's1',
      name: 'S1',
      systemType: UniversitySystemType.engineering,
      modules: [
        _module(name: 'Eliminatory', td: '4', exam: '4', coeff: '1'),
        _module(name: 'Strong', td: '16', exam: '16', coeff: '2'),
      ],
    );

    final result = UniversityGradeEngine.calculateSemester(semester);

    expect(result.average, closeTo(12, 0.0001));
    expect(result.isValidated, isFalse);
    expect(result.hasEliminatoryFailure, isTrue);
    expect(result.flatSubjects.first.status, SubjectGradeStatus.eliminatory);
  });

  test('Result counts every subject dynamically across UEs', () {
    final semester = Semester(
      id: 's1',
      name: 'S1',
      systemType: UniversitySystemType.lmd,
      modules: [
        for (var index = 0; index < 7; index++)
          _module(
            name: 'Subject $index',
            td: index == 6 ? '' : '10',
            exam: '10',
            credits: '3',
            unitId: index < 4 ? 'ue_a' : 'ue_b',
            unitName: index < 4 ? 'Unit A' : 'Unit B',
          ),
      ],
    );

    final result = UniversityGradeEngine.calculateSemester(semester);

    expect(result.totalModules, 7);
    expect(result.flatSubjects.length, 7);
    expect(result.gradedModules, 7);
    expect(result.units.map((unit) => unit.subjectCount), [4, 3]);
  });

  test('Exam-only module is graded in LMD and Engineering systems', () {
    final modules = [_module(name: 'Exam Only', exam: '13')];
    final lmd = UniversityGradeEngine.calculateSemester(
      Semester(
        id: 's1',
        name: 'S1',
        systemType: UniversitySystemType.lmd,
        modules: modules,
      ),
    );
    final engineering = UniversityGradeEngine.calculateSemester(
      Semester(
        id: 's1',
        name: 'S1',
        systemType: UniversitySystemType.engineering,
        modules: modules,
      ),
    );

    expect(lmd.gradedModules, 1);
    expect(lmd.average, closeTo(13, 0.0001));
    expect(engineering.gradedModules, 1);
    expect(engineering.average, closeTo(13, 0.0001));
  });

  test('LMD progression thresholds match official credit rules', () {
    expect(
      UniversityGradeEngine.evaluateLmdProgression(
        level: LmdProgressionLevel.l1ToL2,
        cumulativeCredits: 30,
      ).isEligible,
      isTrue,
    );
    expect(
      UniversityGradeEngine.evaluateLmdProgression(
        level: LmdProgressionLevel.l2ToL3,
        cumulativeCredits: 89,
      ).isEligible,
      isFalse,
    );
    expect(
      UniversityGradeEngine.evaluateLmdProgression(
        level: LmdProgressionLevel.graduation,
        cumulativeCredits: 180,
      ).isEligible,
      isTrue,
    );
  });
}
