import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/grade_models.dart';
import '../../services/grade_insights.dart';
import '../../theme/app_theme.dart';
import '../../utils/grade_formatters.dart';

class ModernModuleCard extends StatelessWidget {
  const ModernModuleCard({
    super.key,
    required this.module,
    required this.moduleIndex,
    this.isHeld = false,
    this.onEdit,
    required this.onDelete,
    required this.onDuplicate,
    required this.onToggleLock,
  });

  final Module module;
  final int moduleIndex;
  final bool isHeld;
  final VoidCallback? onEdit;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;
  final VoidCallback onToggleLock;

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    final text = AppText.of(context);
    final calc = ModuleCalc.fromModule(module);
    final avg = calc.finalGrade;
    final passRequirement = GradeInsights.passRequirement(module, text: text);
    final moduleName = module.name.trim();
    final title = moduleName.isEmpty
        ? text.moduleTitle(moduleIndex)
        : moduleName;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      transform: isHeld
          ? Matrix4.translationValues(0, -4, 0)
          : Matrix4.identity(),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHeld
            ? Color.alphaBlend(
                tokens.accent.withValues(alpha: 0.1),
                tokens.card,
              )
            : tokens.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: module.isLocked
              ? tokens.danger.withValues(alpha: 0.42)
              : isHeld
              ? tokens.accent.withValues(alpha: 0.58)
              : Colors.transparent,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: tokens.shadow.withValues(alpha: isHeld ? 0.62 : 0.45),
            blurRadius: isHeld ? 30 : 24,
            offset: Offset(0, isHeld ? 14 : 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.08,
                  ),
                ),
              ),
              if (module.isLocked) ...[
                Icon(Icons.lock_rounded, color: tokens.danger, size: 16),
                const SizedBox(width: 4),
              ],
              _ModuleOptionsButton(
                module: module,
                onEdit: onEdit,
                onDelete: onDelete,
                onDuplicate: onDuplicate,
                onToggleLock: onToggleLock,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              text: text.avgPrefix,
              style: theme.textTheme.bodySmall?.copyWith(
                color: tokens.textMuted,
                fontWeight: FontWeight.w700,
              ),
              children: [
                TextSpan(
                  text: '${formatGradeOrDash(avg)}/20',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: avg == null
                        ? theme.colorScheme.onSurface
                        : (avg >= 10 ? tokens.success : tokens.danger),
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            text.coeffValue(module.coeff.trim().isEmpty ? '--' : module.coeff),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: tokens.textMuted,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          _PassRequirementChip(requirement: passRequirement),
        ],
      ),
    );
  }
}

enum _ModuleMenuAction { edit, copy, toggleLock, delete }

class _ModuleOptionsButton extends StatelessWidget {
  const _ModuleOptionsButton({
    required this.module,
    required this.onEdit,
    required this.onDelete,
    required this.onDuplicate,
    required this.onToggleLock,
  });

  final Module module;
  final VoidCallback? onEdit;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;
  final VoidCallback onToggleLock;

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final text = AppText.of(context);

    return PopupMenuButton<_ModuleMenuAction>(
      tooltip: 'Module options',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 168),
      child: SizedBox.square(
        dimension: 30,
        child: Icon(Icons.more_vert_rounded, color: tokens.textMuted, size: 22),
      ),
      onSelected: (action) {
        switch (action) {
          case _ModuleMenuAction.edit:
            onEdit?.call();
            break;
          case _ModuleMenuAction.copy:
            onDuplicate();
            break;
          case _ModuleMenuAction.toggleLock:
            onToggleLock();
            break;
          case _ModuleMenuAction.delete:
            onDelete();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<_ModuleMenuAction>(
          value: _ModuleMenuAction.edit,
          enabled: onEdit != null,
          child: _ModuleMenuRow(icon: Icons.edit_rounded, label: text.edit),
        ),
        PopupMenuItem<_ModuleMenuAction>(
          value: _ModuleMenuAction.copy,
          child: _ModuleMenuRow(icon: Icons.copy_rounded, label: text.copy),
        ),
        PopupMenuItem<_ModuleMenuAction>(
          value: _ModuleMenuAction.toggleLock,
          child: _ModuleMenuRow(
            icon: module.isLocked
                ? Icons.lock_open_rounded
                : Icons.lock_rounded,
            label: module.isLocked ? text.unlock : text.lock,
          ),
        ),
        PopupMenuItem<_ModuleMenuAction>(
          value: _ModuleMenuAction.delete,
          child: _ModuleMenuRow(
            icon: Icons.delete_outline_rounded,
            label: text.delete,
            danger: true,
          ),
        ),
      ],
    );
  }
}

class _ModuleMenuRow extends StatelessWidget {
  const _ModuleMenuRow({
    required this.icon,
    required this.label,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final color = danger
        ? tokens.danger
        : Theme.of(context).colorScheme.onSurface;

    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _PassRequirementChip extends StatelessWidget {
  const _PassRequirementChip({required this.requirement});

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

    final note = '${requirement.title} - ${requirement.detail}';

    return Tooltip(
      message: note,
      child: Semantics(
        label: note,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withValues(alpha: 0.22)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 13, color: color),
              const SizedBox(width: 5),
              Flexible(
                child: Text.rich(
                  TextSpan(
                    text: requirement.title,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                    children: [
                      TextSpan(
                        text: ' - ${requirement.detail}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: tokens.textMuted,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
