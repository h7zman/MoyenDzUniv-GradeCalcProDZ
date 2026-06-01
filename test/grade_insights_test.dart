import 'package:flutter_test/flutter_test.dart';
import 'package:gradecalcprodz/models/grade_models.dart';
import 'package:gradecalcprodz/services/grade_insights.dart';

Module _module({
  String td = '',
  String tp = '',
  String exam = '',
  int examPercentage = 60,
  int ccPercentage = 40,
}) {
  return Module(
    id: 'm1',
    name: 'M1',
    coeff: '1',
    td: td,
    tp: tp,
    exam: exam,
    examPercentage: examPercentage,
    ccPercentage: ccPercentage,
    splitMode: 'custom',
  );
}

void main() {
  test('calculates needed exam score when CC is known', () {
    final insight = GradeInsights.passRequirement(_module(td: '10'));

    expect(insight.status, PassRequirementStatus.actionable);
    expect(insight.requiredScore, closeTo(10, 0.0001));
  });

  test('calculates needed TD score when exam and TP are known', () {
    final insight = GradeInsights.passRequirement(_module(exam: '9', tp: '10'));

    expect(insight.status, PassRequirementStatus.actionable);
    expect(insight.requiredScore, closeTo(13, 0.0001));
  });

  test('marks impossible pass target when required score is above 20', () {
    final insight = GradeInsights.passRequirement(_module(exam: '0', tp: '0'));

    expect(insight.status, PassRequirementStatus.impossible);
  });
}
