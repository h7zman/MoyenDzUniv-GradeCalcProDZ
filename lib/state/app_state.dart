import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../models/grade_models.dart';

class AppState extends ChangeNotifier {
  AppState({
    required this.semesters,
    required this.selectedTabIndex,
    required this.themeIndex,
    List<SemesterTemplate>? templates,
    this.language = AppLanguage.english,
    this.hasSeenOnboarding = false,
  }) : templates = templates ?? [];

  static const String prefsKey = 'gradecalc_state_v1';
  static const String _onboardingKey = 'has_seen_onboarding';
  static const String _themeIndexKey = 'theme_index_v1';
  static const String _languageCodeKey = 'language_code_v1';

  List<Semester> semesters;
  List<SemesterTemplate> templates;
  int selectedTabIndex;
  int themeIndex;
  AppLanguage language;
  bool hasSeenOnboarding;
  Offset? themeRevealOrigin;
  int themeRevealSerial = 0;

  SharedPreferences? _prefs;
  Timer? _saveTimer;
  static int _idSerial = 0;
  final ValueNotifier<int> _themeChangeTick = ValueNotifier<int>(0);
  final ValueNotifier<int> _languageChangeTick = ValueNotifier<int>(0);

  ValueNotifier<int> get themeChanges => _themeChangeTick;
  ValueNotifier<int> get languageChanges => _languageChangeTick;

  factory AppState.seeded() {
    return AppState(
      semesters: [
        Semester(id: _newId(), name: 'S1', modules: []),
        Semester(id: _newId(), name: 'S2', modules: []),
      ],
      selectedTabIndex: 0,
      themeIndex: 0,
    );
  }

  Future<void> loadFromPrefs({int? maxThemes}) async {
    _prefs ??= await SharedPreferences.getInstance();
    hasSeenOnboarding = _prefs!.getBool(_onboardingKey) ?? false;

    final previousTheme = themeIndex;
    final previousLanguage = language;
    final storedTheme = _prefs!.getInt(_themeIndexKey);
    if (storedTheme != null) {
      themeIndex = _clampThemeIndex(storedTheme, maxThemes);
    }
    final storedLanguage = _prefs!.getString(_languageCodeKey);
    if (storedLanguage != null) {
      language = AppLanguage.fromCode(storedLanguage);
    }

    final raw = _prefs!.getString(prefsKey);
    if (raw == null || raw.isEmpty) {
      if (themeIndex != previousTheme) {
        _themeChangeTick.value += 1;
      }
      if (language != previousLanguage) {
        _languageChangeTick.value += 1;
      }
      notifyListeners();
      return;
    }

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _applyFromJson(decoded, maxThemes: maxThemes);
    } catch (_) {
      // Ignore corrupted state while keeping recoverable values.
    }

    if (themeIndex != previousTheme) {
      _themeChangeTick.value += 1;
    }
    if (language != previousLanguage) {
      _languageChangeTick.value += 1;
    }
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    hasSeenOnboarding = true;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setBool(_onboardingKey, true);
    notifyListeners();
  }

  void setSelectedTabIndex(int index) {
    selectedTabIndex = index.clamp(0, semesters.length);
    _scheduleSave();
    notifyListeners();
  }

  void setThemeIndex(int index, int maxThemes) {
    setTheme(index, maxThemes: maxThemes);
  }

  void setLanguage(AppLanguage nextLanguage) {
    if (language == nextLanguage) {
      return;
    }
    language = nextLanguage;
    _languageChangeTick.value += 1;
    _scheduleSave();
    notifyListeners();
  }

  void setTheme(int index, {required int maxThemes, Offset? revealOrigin}) {
    final next = _clampThemeIndex(index, maxThemes);
    if (themeIndex == next) {
      return;
    }
    themeIndex = next;
    themeRevealOrigin = revealOrigin;
    themeRevealSerial += 1;
    _themeChangeTick.value += 1;
    _scheduleSave();
    notifyListeners();
  }

  void addSemester() {
    final name = _nextSemesterName();
    semesters.add(Semester(id: _newId(), name: name, modules: []));
    selectedTabIndex = semesters.length - 1;
    _scheduleSave();
    notifyListeners();
  }

  void addSemesterFromTemplate(String templateId) {
    final template = templates.firstWhere((t) => t.id == templateId);
    final templateName = template.name.trim();
    final semester = Semester(
      id: _newId(),
      name: templateName.isEmpty ? _nextSemesterName() : templateName,
      systemType: template.systemType,
      modules: [
        for (final module in template.modules)
          _cloneModule(module, clearGrades: true),
      ],
    );
    semesters.add(semester);
    selectedTabIndex = semesters.length - 1;
    _scheduleSave();
    notifyListeners();
  }

  void importSemester(Semester semester) {
    semesters.add(semester);
    selectedTabIndex = semesters.length - 1;
    _scheduleSave();
    notifyListeners();
  }

  void restoreFromBackup(Map<String, dynamic> json, {int? maxThemes}) {
    final previousTheme = themeIndex;
    final previousLanguage = language;
    _applyFromJson(json, maxThemes: maxThemes);
    if (themeIndex != previousTheme) {
      _themeChangeTick.value += 1;
    }
    if (language != previousLanguage) {
      _languageChangeTick.value += 1;
    }
    _scheduleSave();
    notifyListeners();
  }

  void saveSemesterTemplate(String semesterId, String name) {
    final semester = semesters.firstWhere((s) => s.id == semesterId);
    final templateName = name.trim().isEmpty ? semester.name : name.trim();
    templates.add(
      SemesterTemplate(
        id: _newId(),
        name: templateName,
        systemType: semester.systemType,
        modules: [
          for (final module in semester.modules)
            _cloneModule(module, clearGrades: true),
        ],
      ),
    );
    _scheduleSave();
    notifyListeners();
  }

  void deleteTemplate(String templateId) {
    templates.removeWhere((template) => template.id == templateId);
    _scheduleSave();
    notifyListeners();
  }

  void deleteSemester(String semesterId) {
    final index = semesters.indexWhere((s) => s.id == semesterId);
    if (index == -1) {
      return;
    }
    semesters.removeAt(index);
    if (selectedTabIndex > index) {
      selectedTabIndex -= 1;
    }
    _clampSelected();
    _scheduleSave();
    notifyListeners();
  }

  void renameSemester(String semesterId, String name) {
    final semester = semesters.firstWhere((s) => s.id == semesterId);
    semester.name = name.trim().isEmpty ? semester.name : name.trim();
    _scheduleSave();
    notifyListeners();
  }

  void updateSemesterSystemType(
    String semesterId,
    UniversitySystemType systemType,
  ) {
    final semester = semesters.firstWhere((s) => s.id == semesterId);
    if (semester.systemType == systemType) {
      return;
    }
    semester.systemType = systemType;
    _scheduleSave();
    notifyListeners();
  }

  void addModule(String semesterId, {Module? module}) {
    final semester = semesters.firstWhere((s) => s.id == semesterId);
    if (module != null) {
      semester.modules.add(module);
    } else {
      final index = semester.modules.length + 1;
      semester.modules.add(
        Module(
          id: _newId(),
          name: 'Module $index',
          coeff: '1',
          td: '',
          tp: '',
          exam: '',
          examPercentage: 60,
          ccPercentage: 40,
          splitMode: '60_40',
          credits: '0',
          unitId: 'ue_default',
          unitName: 'General UE',
          unitType: TeachingUnitType.fundamental,
        ),
      );
    }
    _scheduleSave();
    notifyListeners();
  }

  void deleteModule(String semesterId, String moduleId) {
    final semester = semesters.firstWhere((s) => s.id == semesterId);
    semester.modules.removeWhere((m) => m.id == moduleId);
    _scheduleSave();
    notifyListeners();
  }

  void duplicateModule(String semesterId, String moduleId) {
    final semester = semesters.firstWhere((s) => s.id == semesterId);
    final index = semester.modules.indexWhere((m) => m.id == moduleId);
    if (index == -1) {
      return;
    }
    final source = semester.modules[index];
    final duplicate = _cloneModule(
      source,
      name: '${source.name} Copy',
      clearLockedState: true,
    );
    semester.modules.insert(index + 1, duplicate);
    _scheduleSave();
    notifyListeners();
  }

  void reorderModules(String semesterId, int oldIndex, int newIndex) {
    final semester = semesters.firstWhere((s) => s.id == semesterId);
    final modules = semester.modules;
    if (oldIndex < 0 ||
        oldIndex >= modules.length ||
        newIndex < 0 ||
        newIndex > modules.length) {
      return;
    }

    var destination = newIndex;
    if (destination > oldIndex) {
      destination -= 1;
    }
    if (destination == oldIndex) {
      return;
    }

    final moved = modules.removeAt(oldIndex);
    modules.insert(destination, moved);
    _scheduleSave();
    notifyListeners();
  }

  void updateModule(
    String semesterId,
    String moduleId, {
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
    final semester = semesters.firstWhere((s) => s.id == semesterId);
    final module = semester.modules.firstWhere((m) => m.id == moduleId);
    if (name != null) module.name = name;
    if (coeff != null) module.coeff = coeff;
    if (td != null) module.td = td;
    if (tp != null) module.tp = tp;
    if (exam != null) module.exam = exam;
    if (examPercentage != null) module.examPercentage = examPercentage;
    if (ccPercentage != null) module.ccPercentage = ccPercentage;
    if (splitMode != null) module.splitMode = splitMode;
    if (credits != null) module.credits = credits;
    if (rattrapage != null) module.rattrapage = rattrapage;
    if (unitId != null) module.unitId = unitId;
    if (unitName != null) module.unitName = unitName;
    if (unitType != null) module.unitType = unitType;
    if (isLocked != null) module.isLocked = isLocked;
    if (isCollapsed != null) module.isCollapsed = isCollapsed;
    _scheduleSave();
    notifyListeners();
  }

  Map<String, dynamic> toJson() => {
    'themeIndex': themeIndex,
    'languageCode': language.code,
    'selectedTabIndex': selectedTabIndex,
    'semesters': semesters.map((s) => s.toJson()).toList(),
    'templates': templates.map((t) => t.toJson()).toList(),
  };

  void _applyFromJson(Map<String, dynamic> json, {int? maxThemes}) {
    final themes = (json['themeIndex'] as int?) ?? themeIndex;
    final languageCode = json['languageCode'] as String?;
    final selected = (json['selectedTabIndex'] as int?) ?? 0;
    final semestersRaw = json['semesters'];
    final templatesRaw = json['templates'];
    final semestersJson = (semestersRaw as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(Semester.fromJson)
        .toList();
    final templatesJson = (templatesRaw as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(SemesterTemplate.fromJson)
        .toList();

    if (semestersRaw is List) {
      semesters = semestersJson;
    }
    if (templatesRaw is List) {
      templates = templatesJson;
    }
    themeIndex = _clampThemeIndex(themes, maxThemes);
    language = AppLanguage.fromCode(languageCode ?? language.code);
    selectedTabIndex = selected;
    _clampSelected();
  }

  int _clampThemeIndex(int index, int? maxThemes) {
    if (maxThemes == null || maxThemes <= 0) {
      return index < 0 ? 0 : index;
    }
    return index.clamp(0, maxThemes - 1).toInt();
  }

  void _clampSelected() {
    final maxIndex = semesters.length;
    if (selectedTabIndex < 0) {
      selectedTabIndex = 0;
    } else if (selectedTabIndex > maxIndex) {
      selectedTabIndex = maxIndex;
    }
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 300), _saveNow);
  }

  Future<void> _saveNow() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(prefsKey, jsonEncode(toJson()));
    await _prefs!.setInt(_themeIndexKey, themeIndex);
    await _prefs!.setString(_languageCodeKey, language.code);
  }

  String _nextSemesterName() {
    final regex = RegExp(r'^s(\\d+)$', caseSensitive: false);
    var maxIndex = 0;
    for (final semester in semesters) {
      final match = regex.firstMatch(semester.name.trim());
      if (match != null) {
        final value = int.tryParse(match.group(1) ?? '');
        if (value != null && value > maxIndex) {
          maxIndex = value;
        }
      }
    }
    return 'S${maxIndex + 1}';
  }

  static Module _cloneModule(
    Module module, {
    String? name,
    bool clearGrades = false,
    bool clearLockedState = false,
  }) {
    return module.copyWith(
      id: _newId(),
      name: name,
      td: clearGrades ? '' : module.td,
      tp: clearGrades ? '' : module.tp,
      exam: clearGrades ? '' : module.exam,
      rattrapage: clearGrades ? '' : module.rattrapage,
      isLocked: clearLockedState ? false : module.isLocked,
      isCollapsed: false,
    );
  }

  static String _newId() {
    _idSerial += 1;
    return '${DateTime.now().microsecondsSinceEpoch}_$_idSerial';
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _themeChangeTick.dispose();
    _languageChangeTick.dispose();
    super.dispose();
  }
}

class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({super.key, required this.state, required super.child})
    : super(notifier: state);

  final AppState state;

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(scope != null, 'No AppStateScope found in context');
    return scope!.state;
  }
}
