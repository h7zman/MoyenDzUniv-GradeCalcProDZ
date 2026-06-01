import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/grade_models.dart';
import '../utils/grade_formatters.dart';

class SemesterReportService {
  const SemesterReportService();

  Future<Uint8List> buildSemesterPdf(Semester semester) async {
    final calc = SemesterCalc.fromSemester(semester);
    final official = UniversityGradeEngine.calculateSemester(semester);
    final document = pw.Document(
      title: '${semester.name} GradeCalcDZ report',
      author: 'GradeCalcDZ',
    );

    document.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(28),
          theme: pw.ThemeData.withFont(),
        ),
        build: (context) => [
          _buildHeader(semester, calc),
          pw.SizedBox(height: 18),
          _buildSummary(calc),
          pw.SizedBox(height: 18),
          _buildModuleTable(official),
        ],
      ),
    );

    return document.save();
  }

  pw.Widget _buildHeader(Semester semester, SemesterCalc calc) {
    final passed = (calc.average ?? 0) >= 10;
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'GradeCalcDZ',
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              '${semester.name} semester report',
              style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
            ),
          ],
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: pw.BoxDecoration(
            color: passed ? PdfColors.green50 : PdfColors.red50,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Text(
            passed ? 'Admitted' : 'Not admitted',
            style: pw.TextStyle(
              color: passed ? PdfColors.green800 : PdfColors.red800,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildSummary(SemesterCalc calc) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _summaryItem('Average', '${formatGradeOrDash(calc.average)}/20'),
          _summaryItem('System', calc.systemType.label),
          _summaryItem(
            'Modules',
            '${calc.gradedModules}/${calc.totalModules} graded',
          ),
          _summaryItem('Passed', '${calc.passedModules}/${calc.totalModules}'),
          if (calc.systemType == UniversitySystemType.lmd)
            _summaryItem(
              'Credits',
              '${calc.earnedCredits}/${calc.totalCredits}',
            ),
          _summaryItem('Coeff', formatGrade(calc.gradedCoefficients)),
        ],
      ),
    );
  }

  pw.Widget _summaryItem(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  pw.Widget _buildModuleTable(SemesterGradeResult result) {
    final showCredits = result.systemType == UniversitySystemType.lmd;
    final headers = showCredits
        ? ['Subject', 'Credits', 'Coeff', 'Average', 'Status']
        : ['Subject', 'Coeff', 'Average', 'Status'];

    final rows = <List<String>>[];
    for (final subject in result.flatSubjects) {
      rows.add(
        showCredits
            ? [
                subject.module.name,
                '${subject.earnedCredits}/${subject.totalCredits}',
                subject.coefficient == null
                    ? '--'
                    : formatGrade(subject.coefficient!),
                formatGradeOrDash(subject.average),
                subject.isPassed ? 'Passed' : 'Failed',
              ]
            : [
                subject.module.name,
                subject.coefficient == null
                    ? '--'
                    : formatGrade(subject.coefficient!),
                formatGradeOrDash(subject.average),
                subject.isPassed ? 'Passed' : 'Failed',
              ],
      );
    }

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellAlignment: pw.Alignment.centerLeft,
      headerAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 6),
    );
  }
}
