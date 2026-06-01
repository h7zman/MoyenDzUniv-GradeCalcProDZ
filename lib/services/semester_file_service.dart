import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:share_plus/share_plus.dart';

import '../models/grade_models.dart';
import 'backup_validation_service.dart';
import 'semester_report_service.dart';
import 'semester_text_codec.dart';

class SemesterFileService {
  const SemesterFileService({
    this.codec = const SemesterTextCodec(),
    this.reportService = const SemesterReportService(),
    this.backupValidator = const BackupValidationService(),
  });

  static const int maxImportBytes = 512 * 1024;

  final SemesterTextCodec codec;
  final SemesterReportService reportService;
  final BackupValidationService backupValidator;

  Future<SemesterFileResult> saveSemester(Semester semester) async {
    try {
      final fileName = buildFileName(semester);
      final bytes = _bytesForSemester(semester);
      final selectedPath = await FilePicker.saveFile(
        dialogTitle: 'Save semester export',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: const ['txt'],
        bytes: bytes,
      );

      if (selectedPath == null && !kIsWeb) {
        return const SemesterFileResult.canceled();
      }

      return const SemesterFileResult.completed(
        message: 'Semester text file saved.',
      );
    } catch (error) {
      throw SemesterFileException('Could not save the semester: $error');
    }
  }

  Future<SemesterFileResult> saveSemesterPdf(Semester semester) async {
    try {
      final fileName = buildFileName(semester, extension: 'pdf');
      final bytes = await reportService.buildSemesterPdf(semester);
      final selectedPath = await FilePicker.saveFile(
        dialogTitle: 'Save semester PDF report',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
        bytes: bytes,
      );

      if (selectedPath == null && !kIsWeb) {
        return const SemesterFileResult.canceled();
      }

      return const SemesterFileResult.completed(
        message: 'Semester PDF report saved.',
      );
    } catch (error) {
      throw SemesterFileException('Could not save the PDF report: $error');
    }
  }

  Future<SemesterFileResult> saveJsonBackup(
    Map<String, dynamic> stateJson,
  ) async {
    try {
      final fileName = buildBackupFileName();
      final bytes = Uint8List.fromList(
        utf8.encode(
          const JsonEncoder.withIndent('  ').convert(_wrapBackup(stateJson)),
        ),
      );
      final selectedPath = await FilePicker.saveFile(
        dialogTitle: 'Save GradeCalcDZ JSON backup',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: const ['json'],
        bytes: bytes,
      );

      if (selectedPath == null && !kIsWeb) {
        return const SemesterFileResult.canceled();
      }

      return const SemesterFileResult.completed(message: 'JSON backup saved.');
    } catch (error) {
      throw SemesterFileException('Could not save the JSON backup: $error');
    }
  }

  Future<SemesterFileResult> shareSemester(
    Semester semester, {
    Rect? sharePositionOrigin,
  }) async {
    try {
      final fileName = buildFileName(semester);
      final bytes = _bytesForSemester(semester);
      final result = await SharePlus.instance.share(
        ShareParams(
          title: 'GradeCalcDZ semester export',
          subject: '${semester.name} semester export',
          text: 'Semester export from GradeCalcDZ.',
          files: [
            XFile.fromData(
              bytes,
              mimeType: 'text/plain',
              name: fileName,
              length: bytes.length,
            ),
          ],
          fileNameOverrides: [fileName],
          sharePositionOrigin: sharePositionOrigin,
        ),
      );

      if (result.status == ShareResultStatus.dismissed) {
        return const SemesterFileResult.canceled();
      }

      return const SemesterFileResult.completed(
        message: 'Semester export is ready to share.',
      );
    } catch (error) {
      throw SemesterFileException('Could not share the semester: $error');
    }
  }

  Future<SemesterFileResult> shareSemesterPdf(
    Semester semester, {
    Rect? sharePositionOrigin,
  }) async {
    try {
      final fileName = buildFileName(semester, extension: 'pdf');
      final bytes = await reportService.buildSemesterPdf(semester);
      final result = await SharePlus.instance.share(
        ShareParams(
          title: 'GradeCalcDZ PDF report',
          subject: '${semester.name} PDF report',
          text: 'Semester PDF report from GradeCalcDZ.',
          files: [
            XFile.fromData(
              bytes,
              mimeType: 'application/pdf',
              name: fileName,
              length: bytes.length,
            ),
          ],
          fileNameOverrides: [fileName],
          sharePositionOrigin: sharePositionOrigin,
        ),
      );

      if (result.status == ShareResultStatus.dismissed) {
        return const SemesterFileResult.canceled();
      }

      return const SemesterFileResult.completed(
        message: 'PDF report is ready to share.',
      );
    } catch (error) {
      throw SemesterFileException('Could not share the PDF report: $error');
    }
  }

  Future<SemesterFileResult> importSemester() async {
    try {
      final result = await FilePicker.pickFiles(
        dialogTitle: 'Import semester text file',
        type: FileType.custom,
        allowedExtensions: const ['txt'],
        allowMultiple: false,
      );

      if (result == null || result.xFiles.isEmpty) {
        return const SemesterFileResult.canceled();
      }

      final file = result.xFiles.single;
      final bytes = await file.readAsBytes();
      if (bytes.length > maxImportBytes) {
        throw const SemesterImportException(
          'The selected file is too large for a semester import.',
        );
      }

      final text = _decodeUtf8(bytes);
      final semester = codec.decode(text);
      return SemesterFileResult.completed(
        message: '"${semester.name}" imported.',
        semester: semester,
      );
    } on SemesterImportException {
      rethrow;
    } catch (error) {
      throw SemesterFileException('Could not import the semester: $error');
    }
  }

  Future<SemesterFileResult> importJsonBackup() async {
    try {
      final result = await FilePicker.pickFiles(
        dialogTitle: 'Import GradeCalcDZ JSON backup',
        type: FileType.custom,
        allowedExtensions: const ['json'],
        allowMultiple: false,
      );

      if (result == null || result.xFiles.isEmpty) {
        return const SemesterFileResult.canceled();
      }

      final file = result.xFiles.single;
      final bytes = await file.readAsBytes();
      if (bytes.length > maxImportBytes) {
        throw const SemesterImportException(
          'The selected backup is too large to import safely.',
        );
      }

      final decoded = jsonDecode(_decodeUtf8(bytes));
      if (decoded is! Map<String, dynamic>) {
        throw const SemesterImportException('The backup JSON is invalid.');
      }

      final stateJson = _unwrapBackup(decoded);
      backupValidator.validateStateJson(stateJson);
      return SemesterFileResult.completed(
        message: 'JSON backup imported.',
        backupJson: stateJson,
      );
    } on SemesterImportException {
      rethrow;
    } catch (error) {
      throw SemesterFileException('Could not import the JSON backup: $error');
    }
  }

  String buildFileName(Semester semester, {String extension = 'txt'}) {
    final safeName = semester.name
        .trim()
        .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]+'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final normalizedName = safeName.isEmpty ? 'semester' : safeName;
    final now = DateTime.now();
    final date =
        '${now.year.toString().padLeft(4, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}';
    return 'gradecalcdz_${normalizedName}_$date.$extension';
  }

  String buildBackupFileName() {
    final now = DateTime.now();
    final date =
        '${now.year.toString().padLeft(4, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}';
    return 'gradecalcdz_backup_$date.json';
  }

  Uint8List _bytesForSemester(Semester semester) {
    return Uint8List.fromList(utf8.encode(codec.encode(semester)));
  }

  String _decodeUtf8(Uint8List bytes) {
    try {
      return utf8.decode(bytes);
    } on FormatException {
      throw const SemesterImportException(
        'The selected file is not valid UTF-8.',
      );
    }
  }

  Map<String, dynamic> _wrapBackup(Map<String, dynamic> stateJson) {
    return {
      'format': 'gradecalcdz_backup_v1',
      'exportedAt': DateTime.now().toIso8601String(),
      'state': stateJson,
    };
  }

  Map<String, dynamic> _unwrapBackup(Map<String, dynamic> json) {
    final state = json['state'];
    final stateJson = state is Map<String, dynamic> ? state : json;
    if (stateJson['semesters'] is! List) {
      throw const SemesterImportException(
        'The backup does not contain a valid semester list.',
      );
    }
    return stateJson;
  }
}

class SemesterFileResult {
  const SemesterFileResult._({
    required this.isCanceled,
    required this.message,
    this.semester,
    this.backupJson,
  });

  const SemesterFileResult.completed({
    required String message,
    Semester? semester,
    Map<String, dynamic>? backupJson,
  }) : this._(
         isCanceled: false,
         message: message,
         semester: semester,
         backupJson: backupJson,
       );

  const SemesterFileResult.canceled()
    : this._(isCanceled: true, message: '', semester: null, backupJson: null);

  final bool isCanceled;
  final String message;
  final Semester? semester;
  final Map<String, dynamic>? backupJson;
}

class SemesterFileException implements Exception {
  const SemesterFileException(this.message);

  final String message;

  @override
  String toString() => message;
}
