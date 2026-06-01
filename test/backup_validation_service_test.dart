import 'package:flutter_test/flutter_test.dart';
import 'package:gradecalcprodz/services/backup_validation_service.dart';
import 'package:gradecalcprodz/services/semester_text_codec.dart';

Map<String, dynamic> _module({
  String id = 'm1',
  String name = 'Physics',
  String coeff = '2',
  String td = '12',
  String tp = '',
  String exam = '10',
  String rattrapage = '',
  String credits = '0',
  String unitType = 'fundamental',
  int examPercentage = 60,
  int ccPercentage = 40,
  String splitMode = '60_40',
}) {
  return {
    'id': id,
    'name': name,
    'coeff': coeff,
    'td': td,
    'tp': tp,
    'exam': exam,
    'rattrapage': rattrapage,
    'credits': credits,
    'unitId': 'ue_default',
    'unitName': 'General UE',
    'unitType': unitType,
    'examPercentage': examPercentage,
    'ccPercentage': ccPercentage,
    'splitMode': splitMode,
    'isLocked': false,
    'isCollapsed': false,
  };
}

Map<String, dynamic> _semester({
  String id = 's1',
  String name = 'S1',
  List<Map<String, dynamic>>? modules,
}) {
  return {
    'id': id,
    'name': name,
    'modules': modules ?? [_module()],
  };
}

Map<String, dynamic> _backup({
  List<Map<String, dynamic>>? semesters,
  List<Map<String, dynamic>>? templates,
}) {
  return {
    'themeIndex': 0,
    'languageCode': 'en',
    'selectedTabIndex': 0,
    'semesters': semesters ?? [_semester()],
    'templates': templates ?? const [],
  };
}

void main() {
  const validator = BackupValidationService();

  test('accepts a valid app backup payload', () {
    expect(() => validator.validateStateJson(_backup()), returnsNormally);
  });

  test('rejects backups with too many semesters', () {
    final backup = _backup(
      semesters: List.generate(
        BackupValidationService.maxSemesters + 1,
        (index) => _semester(id: 's$index'),
      ),
    );

    expect(
      () => validator.validateStateJson(backup),
      throwsA(isA<SemesterImportException>()),
    );
  });

  test('rejects backups with too many modules in one semester', () {
    final backup = _backup(
      semesters: [
        _semester(
          modules: List.generate(
            BackupValidationService.maxModulesPerCollection + 1,
            (index) => _module(id: 'm$index'),
          ),
        ),
      ],
    );

    expect(
      () => validator.validateStateJson(backup),
      throwsA(isA<SemesterImportException>()),
    );
  });

  test('rejects invalid module grades and percentages', () {
    final backup = _backup(
      semesters: [
        _semester(
          modules: [_module(td: '21', examPercentage: 70, ccPercentage: 20)],
        ),
      ],
    );

    expect(
      () => validator.validateStateJson(backup),
      throwsA(isA<SemesterImportException>()),
    );
  });

  test('rejects invalid LMD metadata', () {
    final backup = _backup(
      semesters: [
        _semester(
          modules: [_module(credits: '31', unitType: 'invalid')],
        ),
      ],
    );

    expect(
      () => validator.validateStateJson(backup),
      throwsA(isA<SemesterImportException>()),
    );
  });

  test('rejects oversized text fields', () {
    final backup = _backup(
      semesters: [
        _semester(
          modules: [
            _module(
              name: List.filled(
                BackupValidationService.maxModuleNameLength + 1,
                'A',
              ).join(),
            ),
          ],
        ),
      ],
    );

    expect(
      () => validator.validateStateJson(backup),
      throwsA(isA<SemesterImportException>()),
    );
  });
}
