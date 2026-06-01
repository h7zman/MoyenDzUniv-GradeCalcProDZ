import '../models/grade_models.dart';
import '../utils/grade_formatters.dart';

class SemesterTextCodec {
  const SemesterTextCodec();

  static const String header = '# GradeCalcDZ Semester Export v1';
  static const String footer = '# End GradeCalcDZ Semester Export';
  static const int maxModules = 200;

  String encode(Semester semester, {DateTime? generatedAt}) {
    final calc = SemesterCalc.fromSemester(semester);
    final isLmd = semester.systemType == UniversitySystemType.lmd;
    final buffer = StringBuffer()
      ..writeln(header)
      ..writeln('Semester: ${_singleLine(semester.name)}')
      ..writeln('System Type: ${semester.systemType.storageValue}')
      ..writeln(
        'Generated At: ${(generatedAt ?? DateTime.now()).toIso8601String()}',
      )
      ..writeln('Modules: ${semester.modules.length}')
      ..writeln('Average: ${formatGradeOrDash(calc.average)}/20')
      ..writeln('Passed Modules: ${calc.passedModules}/${calc.totalModules}');
    if (isLmd) {
      buffer.writeln('Credits: ${calc.earnedCredits}/${calc.totalCredits}');
    }
    buffer
      ..writeln('Graded Coefficients: ${formatGrade(calc.gradedCoefficients)}')
      ..writeln('Total Coefficients: ${formatGrade(calc.totalCoefficients)}')
      ..writeln();

    for (var i = 0; i < semester.modules.length; i += 1) {
      final module = semester.modules[i];
      final moduleCalc = ModuleCalc.fromModule(module);
      final originalCalc = ModuleCalc.fromModule(
        module.copyWith(rattrapage: ''),
      );
      final showRattrapage =
          originalCalc.finalGrade != null && originalCalc.finalGrade! < 10;
      buffer
        ..writeln('## Module ${i + 1}')
        ..writeln('Name: ${_singleLine(module.name)}')
        ..writeln('Coefficient: ${_singleLine(module.coeff)}')
        ..writeln('TD: ${_singleLine(module.td)}')
        ..writeln('TP: ${_singleLine(module.tp)}')
        ..writeln('Exam: ${_singleLine(module.exam)}');
      if (showRattrapage) {
        buffer.writeln('Rattrapage: ${_singleLine(module.rattrapage)}');
      }
      if (isLmd) {
        buffer.writeln('Credits: ${_singleLine(module.credits)}');
      }
      buffer
        ..writeln('Exam Percentage: ${module.examPercentage}')
        ..writeln('CC Percentage: ${module.ccPercentage}')
        ..writeln('Split Mode: ${module.splitMode}')
        ..writeln('Locked: ${module.isLocked}')
        ..writeln('Collapsed: ${module.isCollapsed}')
        ..writeln('CC Average: ${formatGradeOrDash(moduleCalc.cc)}/20')
        ..writeln('Final Grade: ${formatGradeOrDash(moduleCalc.finalGrade)}/20')
        ..writeln(
          'Errors: ${moduleCalc.errors.isEmpty ? 'none' : moduleCalc.errors.join('; ')}',
        )
        ..writeln();
    }

    buffer.writeln(footer);
    return buffer.toString();
  }

  Semester decode(String source) {
    final normalized = source.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final lines = normalized.split('\n');
    final firstContentLine = lines
        .map((line) => line.trim())
        .firstWhere((line) => line.isNotEmpty, orElse: () => '');

    if (firstContentLine != header) {
      throw const SemesterImportException(
        'This file is not a GradeCalcDZ semester export.',
      );
    }

    final semesterFields = <String, String>{};
    final moduleFields = <Map<String, String>>[];
    Map<String, String>? currentModule;

    for (final rawLine in lines.skip(1)) {
      final line = rawLine.trimRight();
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed == '---') {
        continue;
      }
      if (trimmed == footer) {
        break;
      }
      if (trimmed.startsWith('## Module ')) {
        if (moduleFields.length >= maxModules) {
          throw const SemesterImportException(
            'The file contains too many modules to import safely.',
          );
        }
        currentModule = <String, String>{};
        moduleFields.add(currentModule);
        continue;
      }

      final separator = line.indexOf(':');
      if (separator == -1) {
        continue;
      }

      final key = line.substring(0, separator).trim();
      final value = line.substring(separator + 1).trim();
      if (currentModule == null) {
        semesterFields[key] = value;
      } else {
        currentModule[key] = value;
      }
    }

    final name = _requireText(semesterFields, 'Semester', 'semester');
    final systemType = UniversitySystemType.fromStorage(
      semesterFields['System Type'],
    );
    final declaredModules = _optionalInt(semesterFields['Modules']);
    if (declaredModules != null && declaredModules != moduleFields.length) {
      throw SemesterImportException(
        'Expected $declaredModules modules, but found ${moduleFields.length}.',
      );
    }

    final modules = <Module>[];
    for (var i = 0; i < moduleFields.length; i += 1) {
      modules.add(_decodeModule(moduleFields[i], i));
    }

    return Semester(
      id: _newId('semester', 0),
      name: name,
      modules: modules,
      systemType: systemType,
    );
  }

  Module _decodeModule(Map<String, String> fields, int index) {
    final moduleLabel = 'module ${index + 1}';
    final name = _requireText(fields, 'Name', moduleLabel);
    final coeff = _requireText(fields, 'Coefficient', moduleLabel);
    final td = fields['TD']?.trim() ?? '';
    final tp = fields['TP']?.trim() ?? '';
    final exam = fields['Exam']?.trim() ?? '';
    final rattrapage = fields['Rattrapage']?.trim() ?? '';
    final credits = fields['Credits']?.trim() ?? '0';
    final unitId = fields['Unit ID']?.trim() ?? 'ue_default';
    final unitName = fields['Unit Name']?.trim() ?? 'General UE';
    final unitType = TeachingUnitType.fromStorage(fields['Unit Type']);
    final examPercentage = _requirePercent(
      fields,
      'Exam Percentage',
      moduleLabel,
    );
    final ccPercentage = _requirePercent(fields, 'CC Percentage', moduleLabel);
    final splitMode = _requireText(fields, 'Split Mode', moduleLabel);
    final isLocked = _optionalBool(fields['Locked']) ?? false;
    final isCollapsed = _optionalBool(fields['Collapsed']) ?? false;

    if (examPercentage + ccPercentage != 100) {
      throw SemesterImportException(
        'The exam and CC percentages in $moduleLabel must equal 100.',
      );
    }
    if (!const {'60_40', '50_50', 'custom'}.contains(splitMode)) {
      throw SemesterImportException(
        'The split mode in $moduleLabel is invalid.',
      );
    }

    _validateCoefficient(coeff, moduleLabel);
    _validateGrade(td, 'TD', moduleLabel);
    _validateGrade(tp, 'TP', moduleLabel);
    _validateGrade(exam, 'Exam', moduleLabel);
    _validateGrade(rattrapage, 'Rattrapage', moduleLabel);
    _validateCredits(credits, moduleLabel);

    return Module(
      id: _newId('module', index),
      name: name,
      coeff: coeff,
      td: td,
      tp: tp,
      exam: exam,
      rattrapage: rattrapage,
      credits: credits,
      unitId: unitId.isEmpty ? 'ue_default' : _singleLine(unitId),
      unitName: unitName.isEmpty ? 'General UE' : _singleLine(unitName),
      unitType: unitType,
      examPercentage: examPercentage,
      ccPercentage: ccPercentage,
      splitMode: splitMode,
      isLocked: isLocked,
      isCollapsed: isCollapsed,
    );
  }

  String _requireText(Map<String, String> fields, String key, String section) {
    final value = fields[key]?.trim();
    if (value == null || value.isEmpty) {
      throw SemesterImportException('Missing "$key" in $section.');
    }
    return _singleLine(value);
  }

  int _requirePercent(Map<String, String> fields, String key, String section) {
    final raw = _requireText(fields, key, section);
    final value = int.tryParse(raw);
    if (value == null || value < 0 || value > 100) {
      throw SemesterImportException('"$key" in $section must be 0..100.');
    }
    return value;
  }

  int? _optionalInt(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    return int.tryParse(raw.trim());
  }

  bool? _optionalBool(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    final normalized = raw.trim().toLowerCase();
    if (normalized == 'true') return true;
    if (normalized == 'false') return false;
    throw SemesterImportException('Invalid boolean value "$raw".');
  }

  void _validateCoefficient(String raw, String section) {
    final value = double.tryParse(raw.replaceAll(',', '.'));
    if (value == null || value < 1) {
      throw SemesterImportException('Coefficient in $section must be >= 1.');
    }
  }

  void _validateGrade(String raw, String label, String section) {
    if (raw.trim().isEmpty) {
      return;
    }
    final value = double.tryParse(raw.replaceAll(',', '.'));
    if (value == null || value < 0 || value > 20) {
      throw SemesterImportException('$label in $section must be 0..20.');
    }
  }

  void _validateCredits(String raw, String section) {
    if (raw.trim().isEmpty) {
      return;
    }
    final value = double.tryParse(raw.replaceAll(',', '.'));
    if (value == null || value < 0 || value > 30) {
      throw SemesterImportException('Credits in $section must be 0..30.');
    }
  }

  String _singleLine(String value) {
    return value.replaceAll(RegExp(r'[\r\n\t]+'), ' ').trim();
  }

  String _newId(String label, int index) {
    return '${DateTime.now().microsecondsSinceEpoch}_${label}_$index';
  }
}

class SemesterImportException implements Exception {
  const SemesterImportException(this.message);

  final String message;

  @override
  String toString() => message;
}
