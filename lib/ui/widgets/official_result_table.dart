import 'package:flutter/material.dart';

import '../../models/grade_models.dart';
import '../../theme/app_theme.dart';
import '../../utils/grade_formatters.dart';

typedef OfficialTableAction = Future<void> Function(BuildContext context);

Future<void> showOfficialResultTableSheet(
  BuildContext context, {
  required Semester semester,
  OfficialTableAction? onDownload,
  OfficialTableAction? onShare,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (sheetContext) {
      final height = MediaQuery.sizeOf(sheetContext).height * 0.88;
      return SafeArea(
        child: SizedBox(
          height: height,
          child: OfficialResultTableSheet(
            semester: semester,
            onDownload: onDownload,
            onShare: onShare,
          ),
        ),
      );
    },
  );
}

class OfficialResultTableSheet extends StatelessWidget {
  const OfficialResultTableSheet({
    super.key,
    required this.semester,
    this.onDownload,
    this.onShare,
  });

  final Semester semester;
  final OfficialTableAction? onDownload;
  final OfficialTableAction? onShare;

  @override
  Widget build(BuildContext context) {
    final result = UniversityGradeEngine.calculateSemester(semester);
    final tokens = AppThemeTokens.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: _OfficialTableHeader(
            semester: semester,
            result: result,
            onDownload: onDownload,
            onShare: onShare,
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: tokens.fieldBorder),
              boxShadow: [
                BoxShadow(
                  color: tokens.shadow.withValues(alpha: 0.14),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: OfficialResultTable(semester: semester, result: result),
          ),
        ),
      ],
    );
  }
}

class _OfficialTableHeader extends StatelessWidget {
  const _OfficialTableHeader({
    required this.semester,
    required this.result,
    this.onDownload,
    this.onShare,
  });

  final Semester semester;
  final SemesterGradeResult result;
  final OfficialTableAction? onDownload;
  final OfficialTableAction? onShare;

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    final average = formatGradeOrDash(result.average);
    final showCredits = result.systemType == UniversitySystemType.lmd;
    final credits =
        '${result.earnedCredits}/${UniversityGradeEngine.lmdSemesterCredits}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Official Table',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (onDownload != null)
              IconButton.filledTonal(
                onPressed: () => onDownload!(context),
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 20),
                tooltip: 'Download PDF report',
                visualDensity: VisualDensity.compact,
              ),
            if (onShare != null) ...[
              const SizedBox(width: 4),
              IconButton.filledTonal(
                onPressed: () => onShare!(context),
                icon: const Icon(Icons.ios_share_rounded, size: 20),
                tooltip: 'Share PDF report',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _HeaderChip(
              label: '${semester.name} Average',
              value: '$average /20',
              color: _gradeColor(tokens, result.average),
            ),
            if (showCredits)
              _HeaderChip(
                label: 'Credits',
                value: credits,
                color: tokens.success,
              ),
            _HeaderChip(
              label: 'System',
              value: result.systemType.label,
              color: tokens.accent,
            ),
            if (result.hasEliminatoryFailure &&
                result.eliminatoryThreshold != null)
              _HeaderChip(
                label: 'Eliminatory',
                value: '< ${formatGrade(result.eliminatoryThreshold!)}',
                color: tokens.danger,
              ),
          ],
        ),
        for (final notice in result.notices) ...[
          const SizedBox(height: 8),
          _HeaderNotice(message: notice),
        ],
      ],
    );
  }
}

class _HeaderNotice extends StatelessWidget {
  const _HeaderNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFFE87500);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        '$label: $value',
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class OfficialResultTable extends StatelessWidget {
  const OfficialResultTable({
    super.key,
    required this.semester,
    required this.result,
  });

  final Semester semester;
  final SemesterGradeResult result;

  bool get _showCredits => result.systemType == UniversitySystemType.lmd;

  @override
  Widget build(BuildContext context) {
    final rows = _buildRows();

    if (rows.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No subjects yet.'),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: SizedBox(
              width: constraints.maxWidth,
              child: Table(
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                columnWidths: _columnWidths(),
                children: [
                  _headerRow(),
                  for (final row in rows)
                    row.toTableRow(showCredits: _showCredits),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Map<int, TableColumnWidth> _columnWidths() {
    if (_showCredits) {
      return const {
        0: FlexColumnWidth(2.2),
        1: FixedColumnWidth(54),
        2: FixedColumnWidth(64),
        3: FixedColumnWidth(58),
      };
    }

    return const {
      0: FlexColumnWidth(2.3),
      1: FixedColumnWidth(58),
      2: FixedColumnWidth(64),
    };
  }

  List<_OfficialRowData> _buildRows() {
    return [
      for (final subject in result.flatSubjects)
        _OfficialRowData.subject(
          name: subject.module.name,
          credits: _showCredits
              ? '${subject.earnedCredits}/${subject.totalCredits}'
              : '',
          coefficient: _formatNullable(subject.coefficient),
          grade: subject.average,
          status: subject.status,
        ),
    ];
  }

  TableRow _headerRow() {
    final cells = _showCredits
        ? const [
            '\u0627\u0644\u0645\u0642\u064a\u0627\u0633',
            '\u0627\u0644\u0645\u0639\u0627\u0645\u0644',
            '\u0627\u0644\u0631\u0635\u064a\u062f',
            '\u0627\u0644\u0645\u0639\u062f\u0644',
          ]
        : const [
            '\u0627\u0644\u0645\u0642\u064a\u0627\u0633',
            '\u0627\u0644\u0645\u0639\u0627\u0645\u0644',
            '\u0627\u0644\u0645\u0639\u062f\u0644',
          ];
    return TableRow(
      decoration: const BoxDecoration(color: Color(0xFFF6F7F9)),
      children: [
        for (final cell in cells)
          _OfficialTableCell(
            text: cell,
            isHeader: true,
            alignEnd: cell == '\u0627\u0644\u0645\u0642\u064a\u0627\u0633',
          ),
      ],
    );
  }

  String _formatNullable(double? value) {
    return value == null ? '--' : formatGrade(value);
  }
}

class _OfficialRowData {
  const _OfficialRowData._({
    required this.name,
    required this.credits,
    required this.coefficient,
    required this.grade,
    required this.status,
  });

  factory _OfficialRowData.subject({
    required String name,
    required String credits,
    required String coefficient,
    required double? grade,
    required SubjectGradeStatus status,
  }) {
    return _OfficialRowData._(
      name: name,
      credits: credits,
      coefficient: coefficient,
      grade: grade,
      status: status,
    );
  }

  final String name;
  final String credits;
  final String coefficient;
  final double? grade;
  final SubjectGradeStatus status;

  TableRow toTableRow({required bool showCredits}) {
    final background = _rowBackground();
    final gradeText = formatGradeOrDash(grade);
    final cells = showCredits
        ? [
            _OfficialTableCell(text: name, alignEnd: true),
            _OfficialTableCell(text: coefficient),
            _OfficialTableCell(text: credits),
            _OfficialTableCell(text: gradeText, grade: grade, status: status),
          ]
        : [
            _OfficialTableCell(text: name, alignEnd: true),
            _OfficialTableCell(text: coefficient),
            _OfficialTableCell(text: gradeText, grade: grade, status: status),
          ];

    return TableRow(
      decoration: BoxDecoration(
        color: background,
        border: const Border(bottom: BorderSide(color: Color(0xFFE8EAED))),
      ),
      children: cells,
    );
  }

  Color _rowBackground() {
    return switch (status) {
      SubjectGradeStatus.debt => const Color(0xFFFFF3E0),
      SubjectGradeStatus.eliminatory => const Color(0xFFFFEBEE),
      _ => Colors.white,
    };
  }
}

class _OfficialTableCell extends StatelessWidget {
  const _OfficialTableCell({
    required this.text,
    this.isHeader = false,
    this.alignEnd = false,
    this.grade,
    this.status = SubjectGradeStatus.pending,
  });

  final String text;
  final bool isHeader;
  final bool alignEnd;
  final double? grade;
  final SubjectGradeStatus status;

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final color = _statusColor(tokens, grade, status);
    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: grade == null ? const Color(0xFF4F545A) : color,
      fontSize: 12,
      fontWeight: isHeader ? FontWeight.w900 : FontWeight.w800,
      height: 1.12,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: alignEnd ? TextAlign.right : TextAlign.center,
        style: textStyle,
      ),
    );
  }
}

Color _gradeColor(AppThemeTokens tokens, double? grade) {
  if (grade == null) {
    return tokens.textMuted;
  }
  return grade >= 10 ? const Color(0xFF058B1D) : const Color(0xFFE50914);
}

Color _statusColor(
  AppThemeTokens tokens,
  double? grade,
  SubjectGradeStatus status,
) {
  return switch (status) {
    SubjectGradeStatus.debt => const Color(0xFFE87500),
    SubjectGradeStatus.eliminatory => const Color(0xFFE50914),
    _ => _gradeColor(tokens, grade),
  };
}
