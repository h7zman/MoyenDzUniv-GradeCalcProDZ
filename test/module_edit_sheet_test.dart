import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gradecalcprodz/l10n/app_localizations.dart';
import 'package:gradecalcprodz/models/grade_models.dart';
import 'package:gradecalcprodz/theme/app_theme.dart';
import 'package:gradecalcprodz/ui/module_edit_sheet.dart';

void main() {
  testWidgets('engineering editor hides credits and teaching units', (
    WidgetTester tester,
  ) async {
    await _pumpSheet(
      tester,
      systemType: UniversitySystemType.engineering,
      module: _module(td: '12', exam: '12', credits: '6'),
    );

    expect(find.textContaining('Coeff'), findsWidgets);
    expect(find.textContaining('TD'), findsWidgets);
    expect(find.textContaining('TP'), findsWidgets);
    expect(find.textContaining('Exam'), findsWidgets);
    expect(find.text('Credits'), findsNothing);
    expect(find.text('Rattrapage'), findsNothing);
    expect(find.text('LMD Teaching Unit'), findsNothing);
  });

  testWidgets(
    'lmd editor keeps credits and shows rattrapage only when failed',
    (WidgetTester tester) async {
      await _pumpSheet(
        tester,
        systemType: UniversitySystemType.lmd,
        module: _module(td: '8', exam: '8', credits: '6'),
      );

      expect(find.text('Credits'), findsOneWidget);
      expect(find.text('Rattrapage'), findsOneWidget);
      expect(find.text('LMD Teaching Unit'), findsNothing);

      await _pumpSheet(
        tester,
        systemType: UniversitySystemType.lmd,
        module: _module(td: '12', exam: '12', credits: '6'),
      );

      expect(find.text('Credits'), findsOneWidget);
      expect(find.text('Rattrapage'), findsNothing);
      expect(find.text('LMD Teaching Unit'), findsNothing);
    },
  );
}

Module _module({
  required String td,
  required String exam,
  String credits = '0',
}) {
  return Module(
    id: 'm1',
    name: 'Module',
    coeff: '1',
    td: td,
    tp: '',
    exam: exam,
    examPercentage: 60,
    ccPercentage: 40,
    splitMode: '60_40',
    credits: credits,
  );
}

Future<void> _pumpSheet(
  WidgetTester tester, {
  required UniversitySystemType systemType,
  required Module module,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppThemes.choices.first.data,
      home: AppTextScope(
        text: const AppText(AppLanguage.english),
        child: ModuleEditSheet(
          key: ValueKey('${systemType.name}-${module.td}-${module.exam}'),
          systemType: systemType,
          module: module,
          onSave: (_) {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
