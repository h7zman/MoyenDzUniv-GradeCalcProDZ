import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gradecalcprodz/main.dart';

void main() {
  testWidgets('App bootstraps and shows onboarding first', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const GradeCalcApp());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Set Custom'), findsOneWidget);
    expect(find.text('Coefficients'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });

  testWidgets('App shows home when onboarding already completed', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({'has_seen_onboarding': true});

    await tester.pumpWidget(const GradeCalcApp());
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.bySemanticsLabel('GradeCalcProDz'), findsOneWidget);
    expect(find.text('S1'), findsOneWidget);
    expect(find.text('Final Result'), findsOneWidget);
  });

  testWidgets('Arabic mode keeps LMD selection tied to LMD result table', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'has_seen_onboarding': true,
      'language_code_v1': 'ar',
    });

    await tester.pumpWidget(const GradeCalcApp());
    await tester.pump(const Duration(milliseconds: 600));

    await tester.tap(find.text('LMD'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Table'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.textContaining('LMD System'), findsOneWidget);
  });
}
