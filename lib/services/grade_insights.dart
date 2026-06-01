import '../l10n/app_localizations.dart';
import '../models/grade_models.dart';
import '../utils/grade_formatters.dart';

class GradeInsights {
  const GradeInsights._();

  static PassRequirement passRequirement(
    Module module, {
    double target = 10,
    AppText? text,
  }) {
    final strings = text ?? const AppText(AppLanguage.english);
    final calc = ModuleCalc.fromModule(module);
    if (!calc.percentagesValid) {
      return PassRequirement(
        status: PassRequirementStatus.blocked,
        title: strings.fixSplit,
        detail: strings.percentagesMustEqual100,
      );
    }

    final examWeight = module.examPercentage / 100;
    final ccWeight = module.ccPercentage / 100;

    if (calc.finalGrade != null) {
      if (calc.finalGrade! >= target) {
        return PassRequirement(
          status: PassRequirementStatus.passed,
          title: strings.alreadyPassing,
          detail: strings.currentModuleAverage(formatGrade(calc.finalGrade!)),
        );
      }

      if (ccWeight > 0 && calc.effectiveExam != null) {
        final neededCc = (target - calc.effectiveExam! * examWeight) / ccWeight;
        if (calc.td == null && calc.tp != null) {
          return _scoreRequirement(
            'TD',
            neededCc * 2 - calc.tp!,
            target,
            strings,
          );
        }
        if (calc.tp == null && calc.td != null) {
          return _scoreRequirement(
            'TP',
            neededCc * 2 - calc.td!,
            target,
            strings,
          );
        }
      }

      return PassRequirement(
        status: PassRequirementStatus.needsImprovement,
        title: strings.belowPassMark,
        detail:
            '${strings.currentModuleAverage(formatGrade(calc.finalGrade!))} '
            '${strings.needMorePoints(formatGrade(target - calc.finalGrade!))}',
      );
    }

    if (examWeight > 0 && calc.effectiveExam == null && calc.cc != null) {
      final neededExam = (target - calc.cc! * ccWeight) / examWeight;
      return _scoreRequirement(strings.exam, neededExam, target, strings);
    }

    if (ccWeight > 0 && calc.effectiveExam != null && calc.cc == null) {
      final neededCc = (target - calc.effectiveExam! * examWeight) / ccWeight;
      if (calc.td == null && calc.tp == null) {
        return _scoreRequirement(strings.ccAverage, neededCc, target, strings);
      }
      if (calc.td == null && calc.tp != null) {
        return _scoreRequirement(
          'TD',
          neededCc * 2 - calc.tp!,
          target,
          strings,
        );
      }
      if (calc.tp == null && calc.td != null) {
        return _scoreRequirement(
          'TP',
          neededCc * 2 - calc.td!,
          target,
          strings,
        );
      }
    }

    if (examWeight == 0 && ccWeight > 0 && calc.cc == null) {
      return _scoreRequirement(
        strings.ccAverage,
        target / ccWeight,
        target,
        strings,
      );
    }

    if (ccWeight == 0 && examWeight > 0 && calc.exam == null) {
      return _scoreRequirement(
        strings.exam,
        target / examWeight,
        target,
        strings,
      );
    }

    return PassRequirement(
      status: PassRequirementStatus.blocked,
      title: strings.needMoreGrades,
      detail: strings.enterExamOrCc,
    );
  }

  static PassRequirement _scoreRequirement(
    String label,
    double score,
    double target,
    AppText text,
  ) {
    if (score <= 0) {
      return PassRequirement(
        status: PassRequirementStatus.passed,
        title: text.passTargetCovered,
        detail: text.existingGradesCover(formatGrade(target)),
        requiredScore: 0,
      );
    }

    if (score > 20) {
      return PassRequirement(
        status: PassRequirementStatus.impossible,
        title: text.targetNotReachable,
        detail: text.scoreAboveMaximum(label, formatGrade(score)),
        requiredScore: score,
      );
    }

    return PassRequirement(
      status: PassRequirementStatus.actionable,
      title: text.needScoreIn(formatGrade(score), label),
      detail: text.reachesTarget(formatGrade(target)),
      requiredScore: score,
    );
  }
}

class PassRequirement {
  const PassRequirement({
    required this.status,
    required this.title,
    required this.detail,
    this.requiredScore,
  });

  final PassRequirementStatus status;
  final String title;
  final String detail;
  final double? requiredScore;
}

enum PassRequirementStatus {
  actionable,
  passed,
  needsImprovement,
  blocked,
  impossible,
}
