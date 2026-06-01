import 'package:flutter/material.dart';
import 'package:gradecalcprodz/l10n/app_localizations.dart';
import 'package:gradecalcprodz/models/grade_models.dart';
import 'package:gradecalcprodz/theme/app_theme.dart';
import 'package:gradecalcprodz/utils/grade_formatters.dart';

class ResultPage extends StatefulWidget {
  const ResultPage({super.key, required this.semesters});

  final List<Semester> semesters;

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage>
    with AutomaticKeepAliveClientMixin {
  late _OverallResultSummary _summary;
  late List<_SemesterBreakdown> _breakdown;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _recalculate();
  }

  @override
  void didUpdateWidget(covariant ResultPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _recalculate();
  }

  void _recalculate() {
    final overall = OverallCalc.fromSemesters(widget.semesters);
    _summary = _OverallResultSummary(average: overall.average ?? 0.0);
    _breakdown = [
      for (final semester in widget.semesters)
        _SemesterBreakdown.fromSemester(semester),
    ];
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    final text = AppText.of(context);

    return ListView(
      padding: const EdgeInsets.all(24),
      addAutomaticKeepAlives: true,
      addRepaintBoundaries: true,
      children: [
        Text(
          text.overallResult(formatGrade(_summary.average)),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _summary.average >= 10
                  ? tokens.success.withValues(alpha: 0.1)
                  : tokens.danger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _summary.average >= 10 ? text.admitted : text.notAdmitted,
              style: theme.textTheme.labelLarge?.copyWith(
                color: _summary.average >= 10 ? tokens.success : tokens.danger,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Semester Breakdown
        Text(
          text.semesterBreakdown,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ..._breakdown.map((semester) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: tokens.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: tokens.fieldBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      semester.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      text.modulesCount(semester.moduleCount),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: tokens.textMuted,
                      ),
                    ),
                  ],
                ),
                Text(
                  semester.averageText,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: semester.isPassing ? tokens.success : tokens.danger,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _OverallResultSummary {
  const _OverallResultSummary({required this.average});

  final double average;
}

class _SemesterBreakdown {
  _SemesterBreakdown.fromSemester(Semester semester)
    : name = semester.name,
      moduleCount = semester.modules.length,
      average = SemesterCalc.fromSemester(semester).average {
    averageText = formatGradeOrDash(average);
  }

  final String name;
  final int moduleCount;
  final double? average;
  late final String averageText;

  bool get isPassing => average != null && average! >= 10;
}
