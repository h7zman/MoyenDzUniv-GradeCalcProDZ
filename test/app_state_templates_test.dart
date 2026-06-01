import 'package:flutter_test/flutter_test.dart';
import 'package:gradecalcprodz/l10n/app_localizations.dart';
import 'package:gradecalcprodz/models/grade_models.dart';
import 'package:gradecalcprodz/state/app_state.dart';

Module _module() {
  return Module(
    id: 'm1',
    name: 'Physics',
    coeff: '2',
    td: '12',
    tp: '14',
    exam: '10',
    examPercentage: 60,
    ccPercentage: 40,
    splitMode: '60_40',
    isLocked: true,
  );
}

void main() {
  test('semester templates copy structure and clear grades', () {
    final semester = Semester(
      id: 's1',
      name: 'S1',
      systemType: UniversitySystemType.lmd,
      modules: [_module()],
    );
    final state = AppState(
      semesters: [semester],
      selectedTabIndex: 0,
      themeIndex: 0,
    );

    state.saveSemesterTemplate('s1', 'Template S1');
    state.addSemesterFromTemplate(state.templates.single.id);

    expect(state.semesters.last.name, 'Template S1');
    expect(state.semesters.last.systemType, UniversitySystemType.lmd);
    expect(state.templates.single.modules.single.name, 'Physics');
    expect(state.templates.single.modules.single.td, isEmpty);
    expect(state.semesters.last.modules.single.exam, isEmpty);
    expect(state.semesters.last.modules.single.isLocked, isTrue);
  });

  test('duplicate module inserts unlocked copy after source', () {
    final state = AppState(
      semesters: [
        Semester(id: 's1', name: 'S1', modules: [_module()]),
      ],
      selectedTabIndex: 0,
      themeIndex: 0,
    );

    state.duplicateModule('s1', 'm1');

    expect(state.semesters.single.modules, hasLength(2));
    expect(state.semesters.single.modules.last.name, 'Physics Copy');
    expect(state.semesters.single.modules.last.isLocked, isFalse);
  });

  test('backup json preserves templates', () {
    final state = AppState(
      semesters: [
        Semester(id: 's1', name: 'S1', modules: [_module()]),
      ],
      selectedTabIndex: 0,
      themeIndex: 0,
      language: AppLanguage.arabic,
    )..saveSemesterTemplate('s1', 'Template S1');

    final restored = AppState.seeded()
      ..restoreFromBackup(state.toJson(), maxThemes: 4);

    expect(restored.templates, hasLength(1));
    expect(restored.templates.single.name, 'Template S1');
    expect(restored.language, AppLanguage.arabic);
  });
}
