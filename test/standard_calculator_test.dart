import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gradecalcprodz/theme/app_theme.dart';
import 'package:gradecalcprodz/ui/widgets/standard_calculator_section.dart';

void main() {
  testWidgets(
    'standard calculator supports decimals, parentheses, and history reuse',
    (WidgetTester tester) async {
      await _pumpCalculator(tester);

      for (final key in ['(', '1', '+', '2', ')', '*', '3', '.', '5', '=']) {
        await tester.tap(find.text(key));
        await tester.pump(const Duration(milliseconds: 40));
      }

      expect(find.text('10.5'), findsWidgets);
      expect(find.text('History'), findsOneWidget);
      expect(find.text('(1+2)*3.5'), findsOneWidget);

      await tester.tap(find.text('='));
      await tester.pump(const Duration(milliseconds: 80));
      expect(find.text('(1+2)*3.5'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 80));
      await _pumpCalculator(tester);
      expect(find.text('(1+2)*3.5'), findsOneWidget);

      await tester.tap(find.text('C'));
      await tester.pump(const Duration(milliseconds: 80));
      await tester.ensureVisible(find.byIcon(Icons.add_rounded).first);
      await tester.pump(const Duration(milliseconds: 80));
      await tester.tap(find.byIcon(Icons.add_rounded).first);
      await tester.pump(const Duration(milliseconds: 80));

      for (final key in ['+', '2', '=']) {
        await tester.tap(find.text(key));
        await tester.pump(const Duration(milliseconds: 40));
      }

      expect(find.text('12.5'), findsWidgets);
      expect(find.byIcon(Icons.add_rounded), findsNWidgets(2));

      final clearHistoryButton = find.byKey(
        const ValueKey('calculator-clear-history'),
      );
      await tester.ensureVisible(clearHistoryButton);
      await tester.pump(const Duration(milliseconds: 80));
      await tester.tap(clearHistoryButton);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('History'), findsOneWidget);
      expect(find.text('No calculations yet.'), findsOneWidget);
    },
  );

  testWidgets('calculator header stays visible and keypad position is stable', (
    WidgetTester tester,
  ) async {
    await _pumpCalculator(tester);

    final header = find.bySemanticsLabel(RegExp('GradeCalcProDz'));
    expect(header, findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('By H7Z man')), findsOneWidget);
    final clearButton = find.text('C');
    final initialClearTopLeft = tester.getTopLeft(clearButton);

    await tester.tap(find.text('7'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(header, findsOneWidget);
    expect(tester.getTopLeft(clearButton), initialClearTopLeft);

    await tester.tap(find.text('='));
    await tester.pump(const Duration(milliseconds: 300));
    expect(header, findsOneWidget);
    expect(tester.getTopLeft(clearButton), initialClearTopLeft);
  });
}

Future<void> _pumpCalculator(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(800, 1200);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppThemes.choices.first.data,
      home: const Scaffold(body: StandardCalculatorSection()),
    ),
  );
}
