import 'semester_text_codec.dart';

class BackupValidationService {
  const BackupValidationService();

  static const int maxSemesters = 40;
  static const int maxTemplates = 80;
  static const int maxModulesPerCollection = SemesterTextCodec.maxModules;
  static const int maxTotalModules = 2000;
  static const int maxIdLength = 80;
  static const int maxSemesterNameLength = 80;
  static const int maxTemplateNameLength = 80;
  static const int maxModuleNameLength = 120;
  static const int maxNumericFieldLength = 16;

  void validateStateJson(Map<String, dynamic> stateJson) {
    _validateOptionalInt(
      stateJson,
      'themeIndex',
      min: 0,
      max: 100,
      fallback: 0,
    );
    _validateOptionalInt(
      stateJson,
      'selectedTabIndex',
      min: 0,
      max: 10000,
      fallback: 0,
    );
    _validateOptionalLanguageCode(stateJson['languageCode']);

    final semesters = _requireList(stateJson, 'semesters');
    final templates = _optionalList(stateJson, 'templates');
    if (semesters.length > maxSemesters) {
      throw const SemesterImportException(
        'The backup contains too many semesters to import safely.',
      );
    }
    if (templates.length > maxTemplates) {
      throw const SemesterImportException(
        'The backup contains too many templates to import safely.',
      );
    }

    var totalModules = 0;
    for (var i = 0; i < semesters.length; i += 1) {
      final semester = _requireObject(semesters[i], 'semester ${i + 1}');
      totalModules += _validateModuleCollection(
        semester,
        collectionLabel: 'semester ${i + 1}',
        nameKey: 'name',
        maxNameLength: maxSemesterNameLength,
      );
    }
    for (var i = 0; i < templates.length; i += 1) {
      final template = _requireObject(templates[i], 'template ${i + 1}');
      totalModules += _validateModuleCollection(
        template,
        collectionLabel: 'template ${i + 1}',
        nameKey: 'name',
        maxNameLength: maxTemplateNameLength,
      );
    }
    if (totalModules > maxTotalModules) {
      throw const SemesterImportException(
        'The backup contains too many modules to import safely.',
      );
    }
  }

  int _validateModuleCollection(
    Map<String, dynamic> collection, {
    required String collectionLabel,
    required String nameKey,
    required int maxNameLength,
  }) {
    _validateRequiredString(
      collection,
      'id',
      '$collectionLabel id',
      maxIdLength,
    );
    _validateRequiredString(
      collection,
      nameKey,
      '$collectionLabel name',
      maxNameLength,
    );
    _validateOptionalChoice(
      collection,
      'systemType',
      '$collectionLabel system type',
      const {'engineering', 'lmd'},
    );

    final modules = _requireList(collection, 'modules', owner: collectionLabel);
    if (modules.length > maxModulesPerCollection) {
      throw SemesterImportException(
        'The backup contains too many modules in $collectionLabel.',
      );
    }

    for (var i = 0; i < modules.length; i += 1) {
      final module = _requireObject(
        modules[i],
        '$collectionLabel module ${i + 1}',
      );
      _validateModule(module, '$collectionLabel module ${i + 1}');
    }
    return modules.length;
  }

  void _validateModule(Map<String, dynamic> module, String label) {
    _validateRequiredString(module, 'id', '$label id', maxIdLength);
    _validateRequiredString(module, 'name', '$label name', maxModuleNameLength);
    final coeff = _validateOptionalString(
      module,
      'coeff',
      '$label coefficient',
      maxNumericFieldLength,
      fallback: '',
    );
    final td = _validateOptionalString(
      module,
      'td',
      '$label TD',
      maxNumericFieldLength,
      fallback: '',
    );
    final tp = _validateOptionalString(
      module,
      'tp',
      '$label TP',
      maxNumericFieldLength,
      fallback: '',
    );
    final exam = _validateOptionalString(
      module,
      'exam',
      '$label exam',
      maxNumericFieldLength,
      fallback: '',
    );
    final rattrapage = _validateOptionalString(
      module,
      'rattrapage',
      '$label rattrapage',
      maxNumericFieldLength,
      fallback: '',
    );
    final credits = _validateOptionalString(
      module,
      'credits',
      '$label credits',
      maxNumericFieldLength,
      fallback: '0',
    );
    _validateOptionalString(
      module,
      'unitId',
      '$label unit id',
      maxIdLength,
      fallback: 'ue_default',
    );
    _validateOptionalString(
      module,
      'unitName',
      '$label unit name',
      maxSemesterNameLength,
      fallback: 'General UE',
    );
    _validateOptionalChoice(module, 'unitType', '$label unit type', const {
      'fundamental',
      'discovery',
      'methodological',
      'transversal',
    });
    final examPercentage = _validateOptionalInt(
      module,
      'examPercentage',
      min: 0,
      max: 100,
      fallback: 60,
    );
    final ccPercentage = _validateOptionalInt(
      module,
      'ccPercentage',
      min: 0,
      max: 100,
      fallback: 40,
    );
    final splitMode = _validateOptionalString(
      module,
      'splitMode',
      '$label split mode',
      20,
      fallback: '60_40',
    );

    _validateOptionalBool(module, 'isLocked', label);
    _validateOptionalBool(module, 'isCollapsed', label);
    _validateCoefficient(coeff, label);
    _validateGrade(td, '$label TD');
    _validateGrade(tp, '$label TP');
    _validateGrade(exam, '$label exam');
    _validateGrade(rattrapage, '$label rattrapage');
    _validateCredits(credits, label);

    if (examPercentage + ccPercentage != 100) {
      throw SemesterImportException(
        'The exam and CC percentages in $label must equal 100.',
      );
    }
    if (!const {'60_40', '50_50', 'custom'}.contains(splitMode)) {
      throw SemesterImportException('The split mode in $label is invalid.');
    }
  }

  List<dynamic> _requireList(
    Map<String, dynamic> json,
    String key, {
    String? owner,
  }) {
    final value = json[key];
    if (value is! List<dynamic>) {
      final subject = owner == null ? key : '$owner $key';
      throw SemesterImportException('The backup "$subject" field is invalid.');
    }
    return value;
  }

  List<dynamic> _optionalList(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) {
      return const [];
    }
    if (value is! List<dynamic>) {
      throw SemesterImportException('The backup "$key" field is invalid.');
    }
    return value;
  }

  Map<String, dynamic> _requireObject(Object? value, String label) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    throw SemesterImportException('The backup $label entry is invalid.');
  }

  String _validateRequiredString(
    Map<String, dynamic> json,
    String key,
    String label,
    int maxLength,
  ) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) {
      throw SemesterImportException('The backup $label is missing.');
    }
    return _validateStringLength(value, label, maxLength);
  }

  String _validateOptionalString(
    Map<String, dynamic> json,
    String key,
    String label,
    int maxLength, {
    required String fallback,
  }) {
    final value = json[key];
    if (value == null) {
      return fallback;
    }
    if (value is! String) {
      throw SemesterImportException('The backup $label is invalid.');
    }
    return _validateStringLength(value, label, maxLength);
  }

  void _validateOptionalChoice(
    Map<String, dynamic> json,
    String key,
    String label,
    Set<String> allowed,
  ) {
    final value = json[key];
    if (value == null) {
      return;
    }
    if (value is! String || !allowed.contains(value.trim().toLowerCase())) {
      throw SemesterImportException('The backup $label is invalid.');
    }
  }

  String _validateStringLength(String value, String label, int maxLength) {
    if (value.length > maxLength) {
      throw SemesterImportException('The backup $label is too long.');
    }
    if (value.contains(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'))) {
      throw SemesterImportException(
        'The backup $label contains unsupported characters.',
      );
    }
    return value;
  }

  int _validateOptionalInt(
    Map<String, dynamic> json,
    String key, {
    required int min,
    required int max,
    int? fallback,
  }) {
    final value = json[key];
    if (value == null && fallback != null) {
      return fallback;
    }
    if (value is! int || value < min || value > max) {
      throw SemesterImportException('The backup "$key" field is invalid.');
    }
    return value;
  }

  void _validateOptionalBool(
    Map<String, dynamic> json,
    String key,
    String owner,
  ) {
    final value = json[key];
    if (value != null && value is! bool) {
      throw SemesterImportException(
        'The backup "$key" field in $owner is invalid.',
      );
    }
  }

  void _validateOptionalLanguageCode(Object? value) {
    if (value == null) {
      return;
    }
    if (value is! String || !const {'en', 'ar'}.contains(value)) {
      throw const SemesterImportException(
        'The backup language setting is invalid.',
      );
    }
  }

  void _validateCoefficient(String raw, String label) {
    if (raw.trim().isEmpty) {
      return;
    }
    final value = double.tryParse(raw.replaceAll(',', '.'));
    if (value == null || value < 1 || !value.isFinite) {
      throw SemesterImportException('The coefficient in $label is invalid.');
    }
  }

  void _validateGrade(String raw, String label) {
    if (raw.trim().isEmpty) {
      return;
    }
    final value = double.tryParse(raw.replaceAll(',', '.'));
    if (value == null || value < 0 || value > 20 || !value.isFinite) {
      throw SemesterImportException('The grade in $label is invalid.');
    }
  }

  void _validateCredits(String raw, String label) {
    if (raw.trim().isEmpty) {
      return;
    }
    final value = double.tryParse(raw.replaceAll(',', '.'));
    if (value == null || value < 0 || value > 30 || !value.isFinite) {
      throw SemesterImportException('The credits in $label are invalid.');
    }
  }
}
