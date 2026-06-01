import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/grade_models.dart';
import '../theme/app_theme.dart';
import '../utils/grade_formatters.dart';

class PredictionPage extends StatefulWidget {
  const PredictionPage({super.key, required this.semester});

  final Semester semester;

  @override
  State<PredictionPage> createState() => _PredictionPageState();
}

class _PredictionPageState extends State<PredictionPage> {
  late final List<double> _scores;
  double? _predictedAverage;
  bool _passed = false;

  @override
  void initState() {
    super.initState();
    final official = UniversityGradeEngine.calculateSemester(widget.semester);
    _scores = [
      for (final subject in official.flatSubjects)
        (subject.average ?? 10).clamp(0, 20).toDouble(),
    ];
    _recalculatePrediction();
  }

  void _recalculatePrediction() {
    var weightedSum = 0.0;
    var coefficients = 0.0;
    for (var i = 0; i < widget.semester.modules.length; i += 1) {
      final coefficient = double.tryParse(
        widget.semester.modules[i].coeff.replaceAll(',', '.'),
      );
      if (coefficient == null || coefficient <= 0) {
        continue;
      }
      weightedSum += _scores[i] * coefficient;
      coefficients += coefficient;
    }
    _predictedAverage = coefficients > 0 ? weightedSum / coefficients : null;
    _passed = _predictedAverage != null && _predictedAverage! >= 10;
  }

  void _setScore(int index, double value) {
    setState(() {
      _scores[index] = value;
      _recalculatePrediction();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    final text = AppText.of(context);

    return Scaffold(
      backgroundColor: tokens.bgBottom,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          text.predictionModeTitle,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          addAutomaticKeepAlives: true,
          addRepaintBoundaries: true,
          children: [
            _PredictionSummary(
              semesterName: widget.semester.name,
              average: _predictedAverage,
              passed: _passed,
            ),
            const SizedBox(height: 14),
            ...List.generate(widget.semester.modules.length, (index) {
              final module = widget.semester.modules[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PredictionModuleSlider(
                  module: module,
                  score: _scores[index],
                  onChanged: (value) => _setScore(index, value),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _PredictionSummary extends StatelessWidget {
  const _PredictionSummary({
    required this.semesterName,
    required this.average,
    required this.passed,
  });

  final String semesterName;
  final double? average;
  final bool passed;

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    final text = AppText.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: tokens.shadow.withValues(alpha: 0.32),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  semesterName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  text.predictedAverage,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: tokens.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: (passed ? tokens.success : tokens.danger).withValues(
                alpha: 0.12,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              '${formatGradeOrDash(average)}/20',
              style: theme.textTheme.titleLarge?.copyWith(
                color: passed ? tokens.success : tokens.danger,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PredictionModuleSlider extends StatelessWidget {
  const _PredictionModuleSlider({
    required this.module,
    required this.score,
    required this.onChanged,
  });

  final Module module;
  final double score;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    final text = AppText.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.fieldBorder.withValues(alpha: 0.75)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  module.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${formatGrade(score)}/20',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: score >= 10 ? tokens.success : tokens.danger,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            text.coeffShortValue(
              module.coeff.trim().isEmpty ? '--' : module.coeff.trim(),
            ),
            style: theme.textTheme.bodySmall?.copyWith(color: tokens.textMuted),
          ),
          Slider(
            value: score,
            min: 0,
            max: 20,
            divisions: 80,
            label: formatGrade(score),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
