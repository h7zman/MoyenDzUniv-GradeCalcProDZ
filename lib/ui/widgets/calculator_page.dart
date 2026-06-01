import 'package:flutter/material.dart';
import 'package:gradecalcprodz/l10n/app_localizations.dart';
import 'package:gradecalcprodz/theme/app_theme.dart';

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage>
    with AutomaticKeepAliveClientMixin {
  final _tdController = TextEditingController();
  final _tpController = TextEditingController();
  final _examController = TextEditingController();
  double? _result;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _tdController.dispose();
    _tpController.dispose();
    _examController.dispose();
    super.dispose();
  }

  void _calculate() {
    final td = double.tryParse(_tdController.text);
    final tp = double.tryParse(_tpController.text);
    final exam = double.tryParse(_examController.text);

    // Default 60/40 logic for calculator
    if (exam != null) {
      double cc = 0;
      if (td != null && tp != null) {
        cc = (td + tp) / 2;
      } else if (td != null) {
        cc = td;
      } else if (tp != null) {
        cc = tp;
      }

      setState(() {
        _result = exam * 0.6 + cc * 0.4;
      });
    } else {
      setState(() {
        _result = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    final text = AppText.of(context);

    // Reuse styling from the app theme
    return ListView(
      padding: const EdgeInsets.all(24),
      addAutomaticKeepAlives: true,
      addRepaintBoundaries: true,
      children: [
        Text(
          text.quickCalculator,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          text.quickCalculatorSubtitle,
          style: theme.textTheme.bodyMedium?.copyWith(color: tokens.textMuted),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: tokens.card,
            borderRadius: BorderRadius.circular(tokens.cardRadius),
            boxShadow: [
              BoxShadow(
                color: tokens.shadow.withValues(alpha: 0.05),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              TextField(
                controller: _tdController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: text.tdScore),
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _tpController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: text.tpScore),
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 10),
              _TdTpNote(text: text),
              const SizedBox(height: 16),
              TextField(
                controller: _examController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: text.examScore),
                onChanged: (_) => _calculate(),
              ),
              const SizedBox(height: 24),
              if (_result != null) ...[
                Divider(color: tokens.fieldBorder),
                const SizedBox(height: 16),
                Text(
                  text.result,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: tokens.textMuted,
                  ),
                ),
                Text(
                  _result!.toStringAsFixed(2),
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _result! >= 10 ? tokens.success : tokens.danger,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _TdTpNote extends StatelessWidget {
  const _TdTpNote({required this.text});

  final AppText text;

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.accent.withValues(alpha: 0.18)),
      ),
      child: Text(
        '${text.tdTpNoteTitle}: ${text.tdTpNoteBody}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: tokens.textMuted,
          fontWeight: FontWeight.w600,
          height: 1.35,
        ),
      ),
    );
  }
}
