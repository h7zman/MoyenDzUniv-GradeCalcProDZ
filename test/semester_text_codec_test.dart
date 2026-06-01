import 'package:flutter_test/flutter_test.dart';
import 'package:gradecalcprodz/models/grade_models.dart';
import 'package:gradecalcprodz/services/semester_text_codec.dart';
import 'package:gradecalcprodz/utils/grade_formatters.dart';

Module _module({
  String name = 'Analysis',
  String coeff = '2',
  String td = '10.05',
  String tp = '',
  String exam = '10.05',
  String rattrapage = '',
  String credits = '0',
  String unitId = 'ue_default',
  String unitName = 'General UE',
  int examPercentage = 60,
  int ccPercentage = 40,
  String splitMode = '60_40',
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
    splitMode: splitMode,
  );
}

void main() {
  test('grade formatter keeps two decimal precision when needed', () {
    expect(formatGrade(10.05), '10.05');
    expect(formatGrade(10.5), '10.5');
    expect(formatGrade(10), '10');
  });

  test('exports semester as organized text without one-decimal rounding', () {
    final semester = Semester(id: 's1', name: 'S1', modules: [_module()]);

    final text = const SemesterTextCodec().encode(
      semester,
      generatedAt: DateTime.utc(2026, 5, 18),
    );

    expect(text, contains(SemesterTextCodec.header));
    expect(text, contains('Semester: S1'));
    expect(text, contains('System Type: engineering'));
    expect(text, contains('Average: 10.05/20'));
    expect(text, contains('Final Grade: 10.05/20'));
    expect(text, isNot(contains('Credits:')));
    expect(text, isNot(contains('Unit ID:')));
    expect(text, isNot(contains('Unit Name:')));
    expect(text, isNot(contains('Unit Type:')));
  });

  test('imports a valid exported semester', () {
    final codec = const SemesterTextCodec();
    final original = Semester(
      id: 's1',
      name: 'S3',
      systemType: UniversitySystemType.lmd,
      modules: [
        _module(
          name: 'Physics',
          coeff: '3',
          td: '8',
          exam: '8',
          rattrapage: '13',
          credits: '6',
        ),
      ],
    );

    final imported = codec.decode(codec.encode(original));

    expect(imported.id, isNot(original.id));
    expect(imported.name, original.name);
    expect(imported.systemType, UniversitySystemType.lmd);
    expect(imported.modules, hasLength(1));
    expect(imported.modules.single.name, 'Physics');
    expect(imported.modules.single.coeff, '3');
    expect(imported.modules.single.td, '8');
    expect(imported.modules.single.tp, '');
    expect(imported.modules.single.exam, '8');
    expect(imported.modules.single.rattrapage, '13');
    expect(imported.modules.single.credits, '6');
    expect(imported.modules.single.unitId, 'ue_default');
    expect(imported.modules.single.unitName, 'General UE');
  });

  test('rejects invalid text files', () {
    expect(
      () => const SemesterTextCodec().decode('not a semester export'),
      throwsA(isA<SemesterImportException>()),
    );
  });

  test('rejects percentage splits that do not equal 100', () {
    final text =
        '''
${SemesterTextCodec.header}
Semester: S1
Modules: 1

## Module 1
Name: Broken
Coefficient: 1
TD: 10
TP:
Exam: 10
Exam Percentage: 70
CC Percentage: 20
Split Mode: custom
${SemesterTextCodec.footer}
''';

    expect(
      () => const SemesterTextCodec().decode(text),
      throwsA(isA<SemesterImportException>()),
    );
  });
}
