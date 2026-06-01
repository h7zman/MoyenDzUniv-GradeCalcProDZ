import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../models/grade_models.dart';
import '../services/grade_insights.dart';
import '../theme/app_theme.dart';
import '../utils/grade_formatters.dart';
import 'widgets/segmented_tab_control.dart';

class ModuleEditSheet extends StatefulWidget {
  const ModuleEditSheet({
    super.key,
    this.module,
    required this.systemType,
    required this.onSave,
  });

  final Module? module;
  final UniversitySystemType systemType;
  final ValueChanged<Module> onSave;

  @override
  State<ModuleEditSheet> createState() => _ModuleEditSheetState();
}

class _ModuleEditSheetState extends State<ModuleEditSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _coeffController;
  late final TextEditingController _tdController;
  late final TextEditingController _tpController;
  late final TextEditingController _examController;
  late final TextEditingController _rattrapageController;
  late final TextEditingController _creditsController;
  late final TextEditingController _examPercentController;
  late final TextEditingController _ccPercentController;

  late String _splitMode;
  late int _examPercent;
  late int _ccPercent;

  final _decimalFormatter = FilteringTextInputFormatter.allow(
    RegExp(r'^\d{0,3}([\.,]\d{0,2})?$'),
  );

  bool get _isLocked => widget.module?.isLocked ?? false;

  @override
  void initState() {
    super.initState();

    final module = widget.module;
    _nameController = TextEditingController(text: module?.name ?? 'Module');
    _coeffController = TextEditingController(text: module?.coeff ?? '1');
    _tdController = TextEditingController(text: module?.td ?? '');
    _tpController = TextEditingController(text: module?.tp ?? '');
    _examController = TextEditingController(text: module?.exam ?? '');
    _rattrapageController = TextEditingController(
      text: module?.rattrapage ?? '',
    );
    _creditsController = TextEditingController(text: module?.credits ?? '0');

    _examPercent = module?.examPercentage ?? 60;
    _ccPercent = module?.ccPercentage ?? 40;
    _splitMode = module?.splitMode ?? '60_40';
    if (_splitMode != '60_40' &&
        _splitMode != '50_50' &&
        _splitMode != 'custom') {
      _splitMode = (_examPercent == 50 && _ccPercent == 50) ? '50_50' : '60_40';
    }

    _examPercentController = TextEditingController(text: '$_examPercent');
    _ccPercentController = TextEditingController(text: '$_ccPercent');

    for (final controller in [
      _nameController,
      _coeffController,
      _tdController,
      _tpController,
      _examController,
      _rattrapageController,
      _creditsController,
      _examPercentController,
      _ccPercentController,
    ]) {
      controller.addListener(_refresh);
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _nameController,
      _coeffController,
      _tdController,
      _tpController,
      _examController,
      _rattrapageController,
      _creditsController,
      _examPercentController,
      _ccPercentController,
    ]) {
      controller.removeListener(_refresh);
      controller.dispose();
    }
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  bool get _isLmd => widget.systemType == UniversitySystemType.lmd;

  bool get _isRattrapageAvailable {
    final originalCalc = ModuleCalc.fromModule(
      _buildModule(includeRattrapage: false),
    );
    return originalCalc.finalGrade != null && originalCalc.finalGrade! < 10;
  }

  Module _draftModule() {
    return _buildModule(includeRattrapage: _isRattrapageAvailable);
  }

  Module _buildModule({required bool includeRattrapage}) {
    return Module(
      id: widget.module?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: _nameController.text.trim().isEmpty
          ? 'Module'
          : _nameController.text.trim(),
      coeff: _coeffController.text.trim(),
      td: _tdController.text.trim(),
      tp: _tpController.text.trim(),
      exam: _examController.text.trim(),
      examPercentage: _examPercent,
      ccPercentage: _ccPercent,
      splitMode: _splitMode,
      credits: _isLmd ? _creditsController.text.trim() : '0',
      rattrapage: includeRattrapage ? _rattrapageController.text.trim() : '',
      unitId: 'ue_default',
      unitName: 'General UE',
      unitType: TeachingUnitType.fundamental,
      isLocked: widget.module?.isLocked ?? false,
      isCollapsed: widget.module?.isCollapsed ?? false,
    );
  }

  ModuleCalc get _calc => ModuleCalc.fromModule(_draftModule());

  bool get _isSaveEnabled {
    if (_isLocked) return false;
    final module = _draftModule();
    final hasName = module.name.trim().isNotEmpty;
    final hasCoeff = module.coeff.trim().isNotEmpty;
    return hasName && hasCoeff && _calc.percentagesValid;
  }

  void _changeSplitByIndex(int index) {
    setState(() {
      if (index == 0) {
        _splitMode = '60_40';
        _examPercent = 60;
        _ccPercent = 40;
      } else if (index == 1) {
        _splitMode = '50_50';
        _examPercent = 50;
        _ccPercent = 50;
      } else {
        _splitMode = 'custom';
      }
      _examPercentController.text = '$_examPercent';
      _ccPercentController.text = '$_ccPercent';
    });
  }

  void _onCustomExamChanged(String value) {
    if (_splitMode != 'custom') return;
    final parsed = int.tryParse(value);
    if (parsed == null) return;
    setState(() {
      _examPercent = parsed.clamp(0, 100);
      _ccPercent = (100 - _examPercent).clamp(0, 100);
      _ccPercentController.text = '$_ccPercent';
    });
  }

  void _onCustomCcChanged(String value) {
    if (_splitMode != 'custom') return;
    final parsed = int.tryParse(value);
    if (parsed == null) return;
    setState(() {
      _ccPercent = parsed.clamp(0, 100);
      _examPercent = (100 - _ccPercent).clamp(0, 100);
      _examPercentController.text = '$_examPercent';
    });
  }

  void _save() {
    if (!_isSaveEnabled) return;
    widget.onSave(_draftModule());
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    final text = AppText.of(context);
    final calc = _calc;
    final showRattrapage = _isRattrapageAvailable;
    final avgText = calc.finalGrade == null
        ? '--'
        : formatGrade(calc.finalGrade!);
    final splitIndex = _splitMode == '60_40'
        ? 0
        : _splitMode == '50_50'
        ? 1
        : 2;

    return Scaffold(
      backgroundColor: tokens.bgBottom,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          text.moduleScoreEntry,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                addAutomaticKeepAlives: true,
                addRepaintBoundaries: true,
                children: [
                  _ModuleFormCard(
                    nameController: _nameController,
                    coeffController: _coeffController,
                    tdController: _tdController,
                    tpController: _tpController,
                    examController: _examController,
                    rattrapageController: _rattrapageController,
                    creditsController: _creditsController,
                    examPercent: _examPercent,
                    ccPercent: _ccPercent,
                    splitMode: _splitMode,
                    splitIndex: splitIndex,
                    examPercentController: _examPercentController,
                    ccPercentController: _ccPercentController,
                    decimalFormatter: _decimalFormatter,
                    isLocked: _isLocked,
                    showCredits: _isLmd,
                    showRattrapage: showRattrapage,
                    onSplitChanged: _changeSplitByIndex,
                    onCustomExamChanged: _onCustomExamChanged,
                    onCustomCcChanged: _onCustomCcChanged,
                  ),
                  const SizedBox(height: 12),
                  _CalculatorSection(
                    calc: calc,
                    coeffText: _coeffController.text,
                    examPercent: _examPercent,
                    ccPercent: _ccPercent,
                  ),
                  const SizedBox(height: 12),
                  _PassTargetSection(
                    requirement: GradeInsights.passRequirement(
                      _draftModule(),
                      text: text,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _HowItWorksSection(
                    examPercent: _examPercent,
                    ccPercent: _ccPercent,
                  ),
                  if (calc.errors.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ...calc.errors.map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• $e',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: tokens.danger,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
            _BottomActionBar(
              avgText: avgText,
              enabled: _isSaveEnabled,
              isLocked: _isLocked,
              onSave: _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleFormCard extends StatelessWidget {
  const _ModuleFormCard({
    required this.nameController,
    required this.coeffController,
    required this.tdController,
    required this.tpController,
    required this.examController,
    required this.rattrapageController,
    required this.creditsController,
    required this.examPercent,
    required this.ccPercent,
    required this.splitMode,
    required this.splitIndex,
    required this.examPercentController,
    required this.ccPercentController,
    required this.decimalFormatter,
    required this.isLocked,
    required this.showCredits,
    required this.showRattrapage,
    required this.onSplitChanged,
    required this.onCustomExamChanged,
    required this.onCustomCcChanged,
  });

  final TextEditingController nameController;
  final TextEditingController coeffController;
  final TextEditingController tdController;
  final TextEditingController tpController;
  final TextEditingController examController;
  final TextEditingController rattrapageController;
  final TextEditingController creditsController;
  final int examPercent;
  final int ccPercent;
  final String splitMode;
  final int splitIndex;
  final TextEditingController examPercentController;
  final TextEditingController ccPercentController;
  final TextInputFormatter decimalFormatter;
  final bool isLocked;
  final bool showCredits;
  final bool showRattrapage;
  final ValueChanged<int> onSplitChanged;
  final ValueChanged<String> onCustomExamChanged;
  final ValueChanged<String> onCustomCcChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    final text = AppText.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: tokens.shadow.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: nameController,
                  enabled: !isLocked,
                  textCapitalization: TextCapitalization.words,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: text.moduleNameHint,
                    hintStyle: theme.textTheme.headlineSmall?.copyWith(
                      color: tokens.textMuted,
                    ),
                  ),
                ),
              ),
              if (isLocked)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: tokens.danger.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_rounded, color: tokens.danger, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        text.locked,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: tokens.danger,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          _InputGrid(
            coeffController: coeffController,
            tdController: tdController,
            tpController: tpController,
            examController: examController,
            rattrapageController: rattrapageController,
            creditsController: creditsController,
            examPercent: examPercent,
            ccPercent: ccPercent,
            numberFormatter: decimalFormatter,
            isLocked: isLocked,
            showCredits: showCredits,
            showRattrapage: showRattrapage,
          ),
          const SizedBox(height: 10),
          const _TdTpNote(),
          const SizedBox(height: 16),
          Text(
            text.weightingSplit,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Directionality(
            textDirection: TextDirection.ltr,
            child: SegmentedTabControl(
              tabs: ['60/40', '50/50', text.custom],
              selectedIndex: splitIndex,
              onChanged: isLocked ? (_) {} : onSplitChanged,
            ),
          ),
          if (splitMode == 'custom') ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _PercentField(
                    label: text.examPercent,
                    controller: examPercentController,
                    enabled: !isLocked,
                    onChanged: onCustomExamChanged,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _PercentField(
                    label: text.ccPercent,
                    controller: ccPercentController,
                    enabled: !isLocked,
                    onChanged: onCustomCcChanged,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TdTpNote extends StatelessWidget {
  const _TdTpNote();

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    final text = AppText.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: tokens.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: tokens.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text.tdTpNoteTitle,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: tokens.accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  text.tdTpNoteBody,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: tokens.textMuted,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InputGrid extends StatelessWidget {
  const _InputGrid({
    required this.coeffController,
    required this.tdController,
    required this.tpController,
    required this.examController,
    required this.rattrapageController,
    required this.creditsController,
    required this.examPercent,
    required this.ccPercent,
    required this.numberFormatter,
    required this.isLocked,
    required this.showCredits,
    required this.showRattrapage,
  });

  final TextEditingController coeffController;
  final TextEditingController tdController;
  final TextEditingController tpController;
  final TextEditingController examController;
  final TextEditingController rattrapageController;
  final TextEditingController creditsController;
  final int examPercent;
  final int ccPercent;
  final TextInputFormatter numberFormatter;
  final bool isLocked;
  final bool showCredits;
  final bool showRattrapage;

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final twoCols = constraints.maxWidth >= 290;
        final itemWidth = twoCols
            ? (constraints.maxWidth - 10) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            SizedBox(
              width: itemWidth,
              child: _InputCell(
                label: text.coeffInputLabel,
                controller: coeffController,
                formatter: numberFormatter,
                enabled: !isLocked,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _InputCell(
                label: text.tdPercentLabel((ccPercent / 2).round()),
                controller: tdController,
                formatter: numberFormatter,
                enabled: !isLocked,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _InputCell(
                label: text.tpPercentLabel((ccPercent / 2).round()),
                controller: tpController,
                formatter: numberFormatter,
                enabled: !isLocked,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _InputCell(
                label: text.examInputLabel(examPercent),
                controller: examController,
                formatter: numberFormatter,
                enabled: !isLocked,
              ),
            ),
            if (showRattrapage)
              SizedBox(
                width: itemWidth,
                child: _InputCell(
                  label: 'Rattrapage',
                  controller: rattrapageController,
                  formatter: numberFormatter,
                  enabled: !isLocked,
                ),
              ),
            if (showCredits)
              SizedBox(
                width: itemWidth,
                child: _InputCell(
                  label: 'Credits',
                  controller: creditsController,
                  formatter: numberFormatter,
                  enabled: !isLocked,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _InputCell extends StatelessWidget {
  const _InputCell({
    required this.label,
    required this.controller,
    required this.formatter,
    required this.enabled,
  });

  final String label;
  final TextEditingController controller;
  final TextInputFormatter formatter;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: tokens.textMuted,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [formatter],
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            hintText: '--',
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            filled: true,
            fillColor: tokens.cardAlt,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: tokens.fieldBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: tokens.fieldBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: tokens.accent, width: 1.8),
            ),
          ),
        ),
      ],
    );
  }
}

class _PercentField extends StatelessWidget {
  const _PercentField({
    required this.label,
    required this.controller,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);

    return TextField(
      controller: controller,
      enabled: enabled,
      onChanged: onChanged,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        suffixText: '%',
        filled: true,
        fillColor: tokens.cardAlt,
        isDense: true,
      ),
    );
  }
}

class _CalculatorSection extends StatelessWidget {
  const _CalculatorSection({
    required this.calc,
    required this.coeffText,
    required this.examPercent,
    required this.ccPercent,
  });

  final ModuleCalc calc;
  final String coeffText;
  final int examPercent;
  final int ccPercent;

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    final text = AppText.of(context);

    final coeff = double.tryParse(coeffText.replaceAll(',', '.'));
    final weighted = (calc.finalGrade != null && coeff != null && coeff > 0)
        ? calc.finalGrade! * coeff
        : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.fieldBorder.withValues(alpha: 0.75)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text.calculator,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            text.liveCalculation(examPercent, ccPercent),
            style: theme.textTheme.bodySmall?.copyWith(color: tokens.textMuted),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MiniMetric(
                  label: text.cc,
                  value: calc.cc == null ? '--' : _fmt(calc.cc!),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniMetric(
                  label: text.moduleAverage,
                  value: calc.finalGrade == null
                      ? '--'
                      : _fmt(calc.finalGrade!),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniMetric(
                  label: text.weightedAverage,
                  value: weighted == null ? '--' : _fmt(weighted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _fmt(double v) {
    final s = v.toStringAsFixed(2);
    return s.endsWith('00')
        ? v.toStringAsFixed(0)
        : s.endsWith('0')
        ? v.toStringAsFixed(1)
        : s;
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: tokens.cardAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: tokens.textMuted,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PassTargetSection extends StatelessWidget {
  const _PassTargetSection({required this.requirement});

  final PassRequirement requirement;

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    final color = switch (requirement.status) {
      PassRequirementStatus.passed => tokens.success,
      PassRequirementStatus.actionable => tokens.accent,
      PassRequirementStatus.needsImprovement => tokens.danger,
      PassRequirementStatus.impossible => tokens.danger,
      PassRequirementStatus.blocked => tokens.textMuted,
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.flag_rounded, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  requirement.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  requirement.detail,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: tokens.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HowItWorksSection extends StatelessWidget {
  const _HowItWorksSection({
    required this.examPercent,
    required this.ccPercent,
  });

  final int examPercent;
  final int ccPercent;

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    final text = AppText.of(context);

    return Container(
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.fieldBorder.withValues(alpha: 0.75)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        title: Text(
          text.howItWorks,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          text.exactFormula,
          style: theme.textTheme.bodySmall?.copyWith(color: tokens.textMuted),
        ),
        children: [
          _FormulaLine(text: text.formulaCc),
          _FormulaLine(text: text.formulaModuleAverage(examPercent, ccPercent)),
          _FormulaLine(text: text.formulaSemesterAverage),
        ],
      ),
    );
  }
}

class _FormulaLine extends StatelessWidget {
  const _FormulaLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: tokens.textMuted,
          height: 1.4,
        ),
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.avgText,
    required this.enabled,
    required this.isLocked,
    required this.onSave,
  });

  final String avgText;
  final bool enabled;
  final bool isLocked;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    final text = AppText.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: tokens.bgBottom,
        boxShadow: [
          BoxShadow(
            color: tokens.shadow.withValues(alpha: 0.16),
            blurRadius: 22,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 390;

            final avgCard = Container(
              height: 74,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: tokens.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: tokens.accent.withValues(alpha: 0.55),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text.average,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: tokens.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$avgText /20',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: tokens.accent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            );

            final saveButton = SizedBox(
              height: 74,
              child: FilledButton(
                onPressed: enabled ? onSave : null,
                style: FilledButton.styleFrom(
                  backgroundColor: tokens.accent,
                  foregroundColor: theme.colorScheme.onPrimary,
                  disabledBackgroundColor: tokens.textMuted.withValues(
                    alpha: 0.28,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: FittedBox(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isLocked ? text.lockedModule : text.saveModule,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(isLocked ? Icons.lock_rounded : Icons.check_rounded),
                    ],
                  ),
                ),
              ),
            );

            if (compact) {
              return Column(
                children: [
                  SizedBox(width: double.infinity, child: avgCard),
                  const SizedBox(height: 10),
                  SizedBox(width: double.infinity, child: saveButton),
                ],
              );
            }

            return Row(
              children: [
                Flexible(flex: 4, child: avgCard),
                const SizedBox(width: 10),
                Expanded(flex: 6, child: saveButton),
              ],
            );
          },
        ),
      ),
    );
  }
}
