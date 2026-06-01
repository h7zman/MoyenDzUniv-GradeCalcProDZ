import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../models/grade_models.dart';
import '../services/semester_file_service.dart';
import '../services/semester_text_codec.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'module_edit_sheet.dart';
import 'prediction_page.dart';
import 'widgets/animations.dart';
import 'widgets/donut_chart.dart';
import 'widgets/modern_module_card.dart';
import 'widgets/official_result_table.dart';
import 'widgets/result_page.dart';
import 'widgets/segmented_tab_control.dart';
import 'widgets/standard_calculator_section.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static final Uri _githubProfileUri = Uri.https('github.com', '/h7zman');
  static final Uri _telegramUri = Uri.https('t.me', '/H7Zme');
  static final Uri _supportEmailUri = Uri(
    scheme: 'mailto',
    path: 'userhelping7z@gmail.com',
    queryParameters: {'subject': 'GradeCalcDZ feedback'},
  );

  static const String _githubProfileText = 'github.com/h7zman';
  static const String _telegramText = 't.me/H7Zme';
  static const String _supportEmailText = 'userhelping7z@gmail.com';

  late final PageController _tabsPageController;
  final SemesterFileService _semesterFileService = const SemesterFileService();
  AppState? _observedState;

  @override
  void initState() {
    super.initState();
    _tabsPageController = PageController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = AppStateScope.of(context);
    if (_observedState == state) return;
    _observedState?.removeListener(_syncPageFromState);
    _observedState = state;
    _observedState!.addListener(_syncPageFromState);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_tabsPageController.hasClients) return;
      _tabsPageController.jumpToPage(
        state.selectedTabIndex.clamp(0, _tabCount(state) - 1).toInt(),
      );
    });
  }

  @override
  void dispose() {
    _observedState?.removeListener(_syncPageFromState);
    _tabsPageController.dispose();
    super.dispose();
  }

  int _tabCount(AppState state) => state.semesters.length + 1;

  void _syncPageFromState() {
    final state = _observedState;
    if (state == null || !_tabsPageController.hasClients) return;

    final target = state.selectedTabIndex
        .clamp(0, _tabCount(state) - 1)
        .toInt();
    final current = (_tabsPageController.page ?? 0).round();
    if (target == current) return;

    _tabsPageController.animateToPage(
      target,
      duration: Motion.page,
      curve: Motion.curve,
    );
  }

  void _onPageChanged(int index) {
    HapticFeedback.selectionClick();
    FocusManager.instance.primaryFocus?.unfocus();
    _observedState?.setSelectedTabIndex(index);
  }

  void _showThemePicker(BuildContext context) {
    final state = _observedState;
    if (state == null) return;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView.builder(
            shrinkWrap: true,
            itemExtent: 56,
            itemCount: AppThemes.choices.length,
            addAutomaticKeepAlives: true,
            addRepaintBoundaries: true,
            itemBuilder: (_, index) {
              final choice = AppThemes.choices[index];
              final selected = index == state.themeIndex;
              return Builder(
                builder: (tileContext) {
                  return ListTile(
                    onTap: () {
                      final box = tileContext.findRenderObject() as RenderBox?;
                      final origin = box?.localToGlobal(
                        box.size.center(Offset.zero),
                      );
                      Navigator.of(sheetContext).pop();
                      state.setTheme(
                        index,
                        maxThemes: AppThemes.choices.length,
                        revealOrigin: origin,
                      );
                    },
                    leading: CircleAvatar(backgroundColor: choice.preview),
                    title: Text(choice.name),
                    trailing: selected
                        ? const Icon(Icons.check_circle_rounded)
                        : null,
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  void _showLanguagePicker(BuildContext context) {
    final state = _observedState;
    if (state == null) return;
    final text = AppText.of(context);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            addAutomaticKeepAlives: true,
            addRepaintBoundaries: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Text(
                  text.chooseLanguage,
                  style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              for (final language in AppLanguage.values)
                ListTile(
                  leading: const Icon(Icons.language_rounded),
                  title: Text(language.nativeName),
                  subtitle: Text(language.englishName),
                  trailing: state.language == language
                      ? const Icon(Icons.check_circle_rounded)
                      : null,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    state.setLanguage(language);
                  },
                ),
              const SizedBox(height: 6),
            ],
          ),
        );
      },
    );
  }

  void _openStandardCalculator(BuildContext context) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const StandardCalculatorPage()),
    );
  }

  Future<void> _openOfficialTable(
    BuildContext context,
    Semester semester,
  ) async {
    HapticFeedback.selectionClick();
    await showOfficialResultTableSheet(
      context,
      semester: semester,
      onDownload: (sheetContext) =>
          _downloadSemesterPdf(sheetContext, semester),
      onShare: (sheetContext) => _shareSemesterPdf(sheetContext, semester),
    );
  }

  Future<void> _showSemesterFileActions(
    BuildContext context,
    AppState state,
    Semester? semester,
  ) async {
    final text = AppText.of(context);
    final action = await showModalBottomSheet<_SemesterFileAction>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final colorScheme = theme.colorScheme;
        final maxSheetHeight = MediaQuery.sizeOf(sheetContext).height * 0.72;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxSheetHeight),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 6),
              addAutomaticKeepAlives: true,
              addRepaintBoundaries: true,
              children: [
                ListTile(
                  leading: const Icon(Icons.download_rounded),
                  title: Text(text.downloadTextFile),
                  subtitle: semester == null ? null : Text(semester.name),
                  enabled: semester != null,
                  onTap: semester == null
                      ? null
                      : () => Navigator.of(
                          sheetContext,
                        ).pop(_SemesterFileAction.download),
                ),
                ListTile(
                  leading: const Icon(Icons.ios_share_rounded),
                  title: Text(text.shareTextFile),
                  subtitle: semester == null ? null : Text(semester.name),
                  enabled: semester != null,
                  onTap: semester == null
                      ? null
                      : () => Navigator.of(
                          sheetContext,
                        ).pop(_SemesterFileAction.share),
                ),
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf_rounded),
                  title: Text(text.downloadPdfReport),
                  subtitle: semester == null ? null : Text(semester.name),
                  enabled: semester != null,
                  onTap: semester == null
                      ? null
                      : () => Navigator.of(
                          sheetContext,
                        ).pop(_SemesterFileAction.downloadPdf),
                ),
                ListTile(
                  leading: const Icon(Icons.share_rounded),
                  title: Text(text.sharePdfReport),
                  subtitle: semester == null ? null : Text(semester.name),
                  enabled: semester != null,
                  onTap: semester == null
                      ? null
                      : () => Navigator.of(
                          sheetContext,
                        ).pop(_SemesterFileAction.sharePdf),
                ),
                ListTile(
                  leading: const Icon(Icons.insights_rounded),
                  title: Text(text.predictionMode),
                  subtitle: semester == null ? null : Text(semester.name),
                  enabled: semester != null && semester.modules.isNotEmpty,
                  onTap: semester == null || semester.modules.isEmpty
                      ? null
                      : () => Navigator.of(
                          sheetContext,
                        ).pop(_SemesterFileAction.predict),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.upload_file_rounded),
                  title: Text(text.importSemesterTextFile),
                  onTap: () => Navigator.of(
                    sheetContext,
                  ).pop(_SemesterFileAction.import),
                ),
                ListTile(
                  leading: const Icon(Icons.backup_rounded),
                  title: Text(text.exportJsonBackup),
                  onTap: () => Navigator.of(
                    sheetContext,
                  ).pop(_SemesterFileAction.exportBackup),
                ),
                ListTile(
                  leading: const Icon(Icons.restore_rounded),
                  title: Text(text.importJsonBackup),
                  onTap: () => Navigator.of(
                    sheetContext,
                  ).pop(_SemesterFileAction.importBackup),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                  child: Text(
                    text.developerAndSupport,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                ListTile(
                  leading: const FaIcon(FontAwesomeIcons.github, size: 21),
                  title: Text(text.githubPage),
                  subtitle: const Text(_githubProfileText),
                  trailing: const Icon(Icons.open_in_new_rounded),
                  onTap: () => Navigator.of(
                    sheetContext,
                  ).pop(_SemesterFileAction.github),
                ),
                ListTile(
                  leading: const FaIcon(FontAwesomeIcons.telegram, size: 21),
                  title: Text(text.telegramChannel),
                  subtitle: const Text('@H7Zme'),
                  trailing: const Icon(Icons.open_in_new_rounded),
                  onTap: () => Navigator.of(
                    sheetContext,
                  ).pop(_SemesterFileAction.telegram),
                ),
                ListTile(
                  leading: const Icon(Icons.alternate_email_rounded),
                  title: Text(text.suggestionsEmail),
                  subtitle: const Text(_supportEmailText),
                  trailing: const Icon(Icons.open_in_new_rounded),
                  onTap: () =>
                      Navigator.of(sheetContext).pop(_SemesterFileAction.email),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || !context.mounted || action == null) {
      return;
    }

    switch (action) {
      case _SemesterFileAction.download:
        if (semester != null) {
          await _downloadSemester(context, semester);
        }
        break;
      case _SemesterFileAction.share:
        if (semester != null) {
          await _shareSemester(context, semester);
        }
        break;
      case _SemesterFileAction.downloadPdf:
        if (semester != null) {
          await _downloadSemesterPdf(context, semester);
        }
        break;
      case _SemesterFileAction.sharePdf:
        if (semester != null) {
          await _shareSemesterPdf(context, semester);
        }
        break;
      case _SemesterFileAction.predict:
        if (semester != null) {
          await _openPrediction(context, semester);
        }
        break;
      case _SemesterFileAction.import:
        await _importSemester(context, state);
        break;
      case _SemesterFileAction.exportBackup:
        await _exportJsonBackup(context, state);
        break;
      case _SemesterFileAction.importBackup:
        await _importJsonBackup(context, state);
        break;
      case _SemesterFileAction.github:
        await _openExternalLink(
          context,
          _githubProfileUri,
          fallbackText: _githubProfileText,
        );
        break;
      case _SemesterFileAction.telegram:
        await _openExternalLink(
          context,
          _telegramUri,
          fallbackText: _telegramText,
        );
        break;
      case _SemesterFileAction.email:
        await _openExternalLink(
          context,
          _supportEmailUri,
          fallbackText: _supportEmailText,
        );
        break;
    }
  }

  Future<void> _downloadSemester(
    BuildContext context,
    Semester semester,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await _semesterFileService.saveSemester(semester);
      if (!mounted || result.isCanceled) return;
      _showSnack(messenger, result.message);
    } on SemesterFileException catch (error) {
      if (!mounted) return;
      _showSnack(messenger, error.message);
    }
  }

  Future<void> _shareSemester(BuildContext context, Semester semester) async {
    final messenger = ScaffoldMessenger.of(context);
    final box = context.findRenderObject() as RenderBox?;
    final shareOrigin = box == null
        ? null
        : box.localToGlobal(Offset.zero) & box.size;

    try {
      final result = await _semesterFileService.shareSemester(
        semester,
        sharePositionOrigin: shareOrigin,
      );
      if (!mounted || result.isCanceled) return;
      _showSnack(messenger, result.message);
    } on SemesterFileException catch (error) {
      if (!mounted) return;
      _showSnack(messenger, error.message);
    }
  }

  Future<void> _downloadSemesterPdf(
    BuildContext context,
    Semester semester,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await _semesterFileService.saveSemesterPdf(semester);
      if (!mounted || result.isCanceled) return;
      _showSnack(messenger, result.message);
    } on SemesterFileException catch (error) {
      if (!mounted) return;
      _showSnack(messenger, error.message);
    }
  }

  Future<void> _shareSemesterPdf(
    BuildContext context,
    Semester semester,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final box = context.findRenderObject() as RenderBox?;
    final shareOrigin = box == null
        ? null
        : box.localToGlobal(Offset.zero) & box.size;

    try {
      final result = await _semesterFileService.shareSemesterPdf(
        semester,
        sharePositionOrigin: shareOrigin,
      );
      if (!mounted || result.isCanceled) return;
      _showSnack(messenger, result.message);
    } on SemesterFileException catch (error) {
      if (!mounted) return;
      _showSnack(messenger, error.message);
    }
  }

  Future<void> _exportJsonBackup(BuildContext context, AppState state) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await _semesterFileService.saveJsonBackup(state.toJson());
      if (!mounted || result.isCanceled) return;
      _showSnack(messenger, result.message);
    } on SemesterFileException catch (error) {
      if (!mounted) return;
      _showSnack(messenger, error.message);
    }
  }

  Future<void> _importSemester(BuildContext context, AppState state) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await _semesterFileService.importSemester();
      if (!mounted || result.isCanceled || result.semester == null) return;
      state.importSemester(result.semester!);
      _showSnack(messenger, result.message);
    } on SemesterImportException catch (error) {
      if (!mounted) return;
      _showSnack(messenger, error.message);
    } on SemesterFileException catch (error) {
      if (!mounted) return;
      _showSnack(messenger, error.message);
    }
  }

  Future<void> _importJsonBackup(BuildContext context, AppState state) async {
    final messenger = ScaffoldMessenger.of(context);
    final text = AppText.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(text.importJsonBackupQuestion),
          content: Text(text.importJsonBackupWarning),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(text.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(text.import),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) return;

    try {
      final result = await _semesterFileService.importJsonBackup();
      if (!mounted || result.isCanceled || result.backupJson == null) return;
      state.restoreFromBackup(
        result.backupJson!,
        maxThemes: AppThemes.choices.length,
      );
      _showSnack(messenger, result.message);
    } on SemesterImportException catch (error) {
      if (!mounted) return;
      _showSnack(messenger, error.message);
    } on SemesterFileException catch (error) {
      if (!mounted) return;
      _showSnack(messenger, error.message);
    }
  }

  Future<void> _openPrediction(BuildContext context, Semester semester) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PredictionPage(semester: semester),
      ),
    );
  }

  Future<void> _openExternalLink(
    BuildContext context,
    Uri uri, {
    required String fallbackText,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final text = AppText.of(context);

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) return;
    } catch (_) {
      // Fall through to the clipboard fallback below.
    }

    try {
      await Clipboard.setData(ClipboardData(text: fallbackText));
      if (!mounted) return;
      _showSnack(messenger, text.linkCopiedToClipboard(fallbackText));
    } catch (_) {
      if (!mounted) return;
      _showSnack(messenger, text.couldNotOpenLink);
    }
  }

  void _showSnack(ScaffoldMessengerState messenger, String message) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showAddSemesterOptions(
    BuildContext context,
    AppState state,
  ) async {
    final text = AppText.of(context);
    final action = await showModalBottomSheet<_AddSemesterAction>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            addAutomaticKeepAlives: true,
            addRepaintBoundaries: true,
            children: [
              ListTile(
                leading: const Icon(Icons.add_rounded),
                title: Text(text.blankSemester),
                onTap: () => Navigator.of(
                  sheetContext,
                ).pop(const _AddSemesterAction.blank()),
              ),
              if (state.templates.isNotEmpty) const Divider(height: 1),
              ...state.templates.map((template) {
                return ListTile(
                  leading: const Icon(Icons.bookmark_rounded),
                  title: Text(template.name),
                  subtitle: Text(text.modulesCount(template.modules.length)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded),
                    tooltip: text.deleteTemplate,
                    onPressed: () => Navigator.of(
                      sheetContext,
                    ).pop(_AddSemesterAction.deleteTemplate(template.id)),
                  ),
                  onTap: () => Navigator.of(
                    sheetContext,
                  ).pop(_AddSemesterAction.fromTemplate(template.id)),
                );
              }),
              const SizedBox(height: 6),
            ],
          ),
        );
      },
    );

    if (action == null || !context.mounted) return;
    switch (action.type) {
      case _AddSemesterActionType.blank:
        state.addSemester();
        break;
      case _AddSemesterActionType.fromTemplate:
        state.addSemesterFromTemplate(action.templateId!);
        break;
      case _AddSemesterActionType.deleteTemplate:
        state.deleteTemplate(action.templateId!);
        _showSnack(ScaffoldMessenger.of(context), text.templateDeleted);
        break;
    }
  }

  Future<void> _showSemesterActions(
    BuildContext context,
    AppState state,
    Semester semester,
  ) async {
    final text = AppText.of(context);
    final action = await showModalBottomSheet<_SemesterAction>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_rounded),
                title: Text(text.renameSemester),
                onTap: () {
                  Navigator.of(sheetContext).pop(_SemesterAction.rename);
                },
              ),
              ListTile(
                leading: const Icon(Icons.bookmark_add_rounded),
                title: Text(text.saveAsTemplate),
                enabled: semester.modules.isNotEmpty,
                onTap: semester.modules.isEmpty
                    ? null
                    : () => Navigator.of(
                        sheetContext,
                      ).pop(_SemesterAction.saveTemplate),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded),
                title: Text(text.deleteSemester),
                enabled: state.semesters.length > 1,
                onTap: state.semesters.length > 1
                    ? () =>
                          Navigator.of(sheetContext).pop(_SemesterAction.delete)
                    : null,
              ),
              const SizedBox(height: 6),
            ],
          ),
        );
      },
    );

    if (!context.mounted) return;

    if (action == null) {
      return;
    }

    if (action == _SemesterAction.delete) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(text.deleteSemesterQuestion),
            content: Text(text.semesterRemovedMessage(semester.name)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(text.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(text.delete),
              ),
            ],
          );
        },
      );

      if (confirmed == true) {
        state.deleteSemester(semester.id);
      }
      return;
    }

    if (action == _SemesterAction.saveTemplate) {
      await _saveSemesterAsTemplate(context, state, semester);
      return;
    }

    if (!context.mounted) return;

    final controller = TextEditingController(text: semester.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(text.renameSemester),
          content: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(hintText: text.semesterNameHint),
            onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(text.cancel),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: Text(text.save),
            ),
          ],
        );
      },
    );

    final trimmed = (newName ?? '').trim();
    if (trimmed.isEmpty || trimmed == semester.name) {
      return;
    }
    state.renameSemester(semester.id, trimmed);
  }

  Future<void> _saveSemesterAsTemplate(
    BuildContext context,
    AppState state,
    Semester semester,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final text = AppText.of(context);
    final controller = TextEditingController(text: '${semester.name} Template');
    final templateName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(text.saveSemesterTemplate),
          content: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(hintText: text.templateNameHint),
            onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(text.cancel),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: Text(text.save),
            ),
          ],
        );
      },
    );

    final trimmed = (templateName ?? '').trim();
    if (trimmed.isEmpty) {
      return;
    }
    state.saveSemesterTemplate(semester.id, trimmed);
    _showSnack(messenger, text.templateSavedMessage(trimmed));
  }

  Future<void> _openModuleEditor(
    BuildContext context,
    AppState state,
    Semester semester, {
    Module? module,
  }) async {
    final text = AppText.of(context);
    if (module?.isLocked == true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(text.unlockModuleBeforeEditing)));
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ModuleEditSheet(
          module: module,
          systemType: semester.systemType,
          onSave: (saved) {
            if (module == null) {
              state.addModule(semester.id, module: saved);
            } else {
              state.updateModule(
                semester.id,
                module.id,
                name: saved.name,
                coeff: saved.coeff,
                td: saved.td,
                tp: saved.tp,
                exam: saved.exam,
                examPercentage: saved.examPercentage,
                ccPercentage: saved.ccPercentage,
                splitMode: saved.splitMode,
                credits: saved.credits,
                rattrapage: saved.rattrapage,
                unitId: saved.unitId,
                unitName: saved.unitName,
                unitType: saved.unitType,
              );
            }
          },
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AppState state,
    Semester semester,
    Module module,
  ) async {
    final text = AppText.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(text.deleteModuleQuestion),
          content: Text(text.moduleRemovedMessage(module.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(text.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(text.delete),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      state.deleteModule(semester.id, module.id);
    }
  }

  _DashboardStats _statsForSelection(AppState state) {
    if (state.selectedTabIndex < state.semesters.length) {
      final semester = state.semesters[state.selectedTabIndex];
      final calc = SemesterCalc.fromSemester(semester);
      return _DashboardStats(
        average: calc.average,
        totalModules: calc.totalModules,
        gradedModules: calc.gradedModules,
        passedModules: calc.passedModules,
      );
    }

    final overall = OverallCalc.fromSemesters(state.semesters);
    return _DashboardStats(
      average: overall.average,
      totalModules: overall.totalModules,
      gradedModules: overall.gradedModules,
      passedModules: overall.passedModules,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final tokens = AppThemeTokens.of(context);
    final text = AppText.of(context);
    final tabs = [...state.semesters.map((s) => s.name), text.finalResult];
    final selectedIndex = state.selectedTabIndex
        .clamp(0, tabs.length - 1)
        .toInt();
    final selectedSemester = selectedIndex < state.semesters.length
        ? state.semesters[selectedIndex]
        : null;
    final stats = _statsForSelection(state);

    final showFab = selectedSemester != null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [tokens.bgTop, tokens.bgBottom],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _TopNavigationBar(
                  tabs: tabs,
                  selectedIndex: selectedIndex,
                  onTabChanged: (index) {
                    HapticFeedback.selectionClick();
                    state.setSelectedTabIndex(index);
                  },
                  onSemesterLongPress: (index) {
                    if (index >= state.semesters.length) {
                      return;
                    }
                    HapticFeedback.selectionClick();
                    _showSemesterActions(
                      context,
                      state,
                      state.semesters[index],
                    );
                  },
                  onAddSemesterPressed: () {
                    HapticFeedback.mediumImpact();
                    _showAddSemesterOptions(context, state);
                  },
                  onStandardCalculatorPressed: () =>
                      _openStandardCalculator(context),
                  onThemePressed: () => _showThemePicker(context),
                  onLanguagePressed: () => _showLanguagePicker(context),
                  onFilePressed: () => _showSemesterFileActions(
                    context,
                    state,
                    selectedSemester,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (selectedSemester != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _SystemControlBar(
                    systemType: selectedSemester.systemType,
                    onChanged: (systemType) => state.updateSemesterSystemType(
                      selectedSemester.id,
                      systemType,
                    ),
                    onViewTable: () =>
                        _openOfficialTable(context, selectedSemester),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _OverallStatsCard(stats: stats),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: PageView.builder(
                  controller: _tabsPageController,
                  allowImplicitScrolling: true,
                  onPageChanged: _onPageChanged,
                  itemCount: tabs.length,
                  itemBuilder: (context, index) {
                    if (index < state.semesters.length) {
                      final semester = state.semesters[index];
                      return _SemesterModulesView(
                        semester: semester,
                        onEdit: (module) => _openModuleEditor(
                          context,
                          state,
                          semester,
                          module: module,
                        ),
                        onDelete: (module) =>
                            _confirmDelete(context, state, semester, module),
                        onDuplicate: (module) {
                          state.duplicateModule(semester.id, module.id);
                        },
                        onToggleLock: (module) {
                          state.updateModule(
                            semester.id,
                            module.id,
                            isLocked: !module.isLocked,
                          );
                        },
                        onReorder: (oldIndex, newIndex) {
                          state.reorderModules(semester.id, oldIndex, newIndex);
                        },
                      );
                    }
                    return ResultPage(semesters: state.semesters);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: AnimatedSlide(
        duration: Motion.item,
        curve: Curves.easeOutCubic,
        offset: showFab ? Offset.zero : const Offset(0, 1.6),
        child: AnimatedOpacity(
          duration: Motion.item,
          opacity: showFab ? 1 : 0,
          child: IgnorePointer(
            ignoring: !showFab,
            child: FloatingActionButton.extended(
              onPressed: selectedSemester == null
                  ? null
                  : () => _openModuleEditor(context, state, selectedSemester),
              icon: const Icon(FontAwesomeIcons.plus, size: 18),
              label: Text(text.addModule),
            ),
          ),
        ),
      ),
    );
  }
}

enum _SemesterFileAction {
  download,
  share,
  downloadPdf,
  sharePdf,
  predict,
  import,
  exportBackup,
  importBackup,
  github,
  telegram,
  email,
}

enum _SemesterAction { rename, saveTemplate, delete }

enum _AddSemesterActionType { blank, fromTemplate, deleteTemplate }

class _AddSemesterAction {
  const _AddSemesterAction._(this.type, [this.templateId]);

  const _AddSemesterAction.blank() : this._(_AddSemesterActionType.blank);

  const _AddSemesterAction.fromTemplate(String templateId)
    : this._(_AddSemesterActionType.fromTemplate, templateId);

  const _AddSemesterAction.deleteTemplate(String templateId)
    : this._(_AddSemesterActionType.deleteTemplate, templateId);

  final _AddSemesterActionType type;
  final String? templateId;
}

class _DashboardStats {
  const _DashboardStats({
    required this.average,
    required this.totalModules,
    required this.gradedModules,
    required this.passedModules,
  });

  final double? average;
  final int totalModules;
  final int gradedModules;
  final int passedModules;
}

class _TopNavigationBar extends StatelessWidget {
  const _TopNavigationBar({
    required this.tabs,
    required this.selectedIndex,
    required this.onTabChanged,
    required this.onSemesterLongPress,
    required this.onAddSemesterPressed,
    required this.onStandardCalculatorPressed,
    required this.onThemePressed,
    required this.onLanguagePressed,
    required this.onFilePressed,
  });

  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;
  final ValueChanged<int> onSemesterLongPress;
  final VoidCallback onAddSemesterPressed;
  final VoidCallback onStandardCalculatorPressed;
  final VoidCallback onThemePressed;
  final VoidCallback onLanguagePressed;
  final VoidCallback onFilePressed;

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final text = AppText.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: tokens.card.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: tokens.fieldBorder.withValues(alpha: 0.65)),
        boxShadow: [
          BoxShadow(
            color: tokens.shadow.withValues(alpha: 0.2),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const SpringParticleText(
            lines: ['GradeCalcProDz'],
            height: 44,
            semanticsLabel: 'GradeCalcProDz',
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton.filledTonal(
                onPressed: onStandardCalculatorPressed,
                icon: const Icon(Icons.calculate_rounded),
                tooltip: 'Standard Calculator',
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: onFilePressed,
                icon: const Icon(Icons.folder_open_rounded),
                tooltip: text.importAndExport,
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: onLanguagePressed,
                icon: const Icon(Icons.language_rounded),
                tooltip: text.language,
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: onThemePressed,
                icon: const Icon(Icons.palette_outlined),
                tooltip: text.themes,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SegmentedTabControl(
                  tabs: tabs,
                  selectedIndex: selectedIndex,
                  onChanged: onTabChanged,
                  onLongPress: onSemesterLongPress,
                  scrollable: true,
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: onAddSemesterPressed,
                tooltip: text.addSemester,
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SystemControlBar extends StatelessWidget {
  const _SystemControlBar({
    required this.systemType,
    required this.onChanged,
    required this.onViewTable,
  });

  final UniversitySystemType systemType;
  final ValueChanged<UniversitySystemType> onChanged;
  final VoidCallback onViewTable;

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: tokens.card.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.fieldBorder.withValues(alpha: 0.65)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _CompactSystemToggle(
              selectedSystemType: systemType,
              onChanged: onChanged,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 36,
            child: FilledButton.icon(
              onPressed: onViewTable,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: const Size(0, 36),
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.table_chart_rounded, size: 18),
              label: Text(
                'Table',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactSystemToggle extends StatelessWidget {
  const _CompactSystemToggle({
    required this.selectedSystemType,
    required this.onChanged,
  });

  static const List<UniversitySystemType> _options = [
    UniversitySystemType.engineering,
    UniversitySystemType.lmd,
  ];

  final UniversitySystemType selectedSystemType;
  final ValueChanged<UniversitySystemType> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);

    return Container(
      height: 36,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: tokens.cardAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.fieldBorder.withValues(alpha: 0.75)),
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          children: [
            for (final systemType in _options)
              _CompactSystemOption(
                label: _systemShortLabel(systemType),
                selected: selectedSystemType == systemType,
                onTap: () => onChanged(systemType),
              ),
          ],
        ),
      ),
    );
  }
}

String _systemShortLabel(UniversitySystemType systemType) {
  return switch (systemType) {
    UniversitySystemType.engineering => 'Eng',
    UniversitySystemType.lmd => 'LMD',
  };
}

class _CompactSystemOption extends StatelessWidget {
  const _CompactSystemOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    final foreground = selected
        ? theme.colorScheme.onPrimary
        : tokens.textMuted;

    return Expanded(
      child: Material(
        color: selected ? tokens.accent : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OverallStatsCard extends StatelessWidget {
  const _OverallStatsCard({required this.stats});

  final _DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);
    final text = AppText.of(context);
    final isNarrow = MediaQuery.sizeOf(context).width < 370;
    final donutSize = isNarrow ? 108.0 : 124.0;

    return AnimatedContainer(
      duration: Motion.page,
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.fromLTRB(
        isNarrow ? 12 : 16,
        14,
        isNarrow ? 12 : 16,
        14,
      ),
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: tokens.shadow.withValues(alpha: 0.85),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          DonutChart(
            score: stats.average ?? 0,
            maxScore: 20,
            size: donutSize,
            thickness: isNarrow ? 12 : 14,
          ),
          SizedBox(width: isNarrow ? 12 : 16),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text.overallStats,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                _CompactLegendItem(
                  label: text.total,
                  value: stats.totalModules,
                  bulletColor: tokens.accent,
                ),
                const SizedBox(height: 8),
                _CompactLegendItem(
                  label: text.graded,
                  value: stats.gradedModules,
                  bulletColor: tokens.accent.withValues(alpha: 0.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactLegendItem extends StatelessWidget {
  const _CompactLegendItem({
    required this.label,
    required this.value,
    required this.bulletColor,
  });

  final String label;
  final int value;
  final Color bulletColor;

  @override
  Widget build(BuildContext context) {
    final tokens = AppThemeTokens.of(context);
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: bulletColor,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: tokens.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$value',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _SemesterModulesView extends StatefulWidget {
  const _SemesterModulesView({
    required this.semester,
    required this.onEdit,
    required this.onDelete,
    required this.onDuplicate,
    required this.onToggleLock,
    required this.onReorder,
  });

  final Semester semester;
  final ValueChanged<Module> onEdit;
  final ValueChanged<Module> onDelete;
  final ValueChanged<Module> onDuplicate;
  final ValueChanged<Module> onToggleLock;
  final void Function(int oldIndex, int newIndex) onReorder;

  @override
  State<_SemesterModulesView> createState() => _SemesterModulesViewState();
}

class _SemesterModulesViewState extends State<_SemesterModulesView>
    with AutomaticKeepAliveClientMixin {
  int? _heldIndex;

  @override
  bool get wantKeepAlive => true;

  void _onReorderStart(int index) {
    HapticFeedback.mediumImpact();
    setState(() => _heldIndex = index);
  }

  void _onReorderEnd(int _) {
    if (!mounted) return;
    setState(() => _heldIndex = null);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final tokens = AppThemeTokens.of(context);
    final text = AppText.of(context);

    if (widget.semester.modules.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              FontAwesomeIcons.boxOpen,
              color: tokens.textMuted.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 10),
            Text(
              text.noModulesYet,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: tokens.textMuted),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap “Add Module” to start.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: tokens.textMuted),
            ),
          ],
        ),
      );
    }

    return _buildReorderableModuleList();
  }

  Widget _buildReorderableModuleList() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      itemCount: widget.semester.modules.length,
      addAutomaticKeepAlives: true,
      addRepaintBoundaries: true,
      gridDelegate: _moduleGridDelegate(context),
      itemBuilder: (context, index) {
        final module = widget.semester.modules[index];
        return _DraggableModuleTile(
          key: ValueKey(module.id),
          index: index,
          isHeld: _heldIndex == index,
          onDragStarted: _onReorderStart,
          onDragEnded: _onReorderEnd,
          onMove: _moveModule,
          child: _buildModuleCard(module, index),
        );
      },
    );
  }

  SliverGridDelegateWithFixedCrossAxisCount _moduleGridDelegate(
    BuildContext context,
  ) {
    final width = MediaQuery.sizeOf(context).width;
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: width >= 720 ? 3 : 2,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1,
    );
  }

  void _moveModule(int oldIndex, int targetIndex) {
    if (oldIndex == targetIndex) return;
    final reorderTarget = oldIndex < targetIndex
        ? targetIndex + 1
        : targetIndex;
    widget.onReorder(oldIndex, reorderTarget);
    if (!mounted) return;
    setState(() => _heldIndex = targetIndex);
  }

  Widget _buildModuleCard(Module module, int index) {
    return ModernModuleCard(
      module: module,
      moduleIndex: index + 1,
      isHeld: _heldIndex == index,
      onEdit: module.isLocked ? null : () => widget.onEdit(module),
      onDelete: () => widget.onDelete(module),
      onDuplicate: () => widget.onDuplicate(module),
      onToggleLock: () => widget.onToggleLock(module),
    );
  }
}

class _DraggableModuleTile extends StatelessWidget {
  const _DraggableModuleTile({
    super.key,
    required this.index,
    required this.isHeld,
    required this.onDragStarted,
    required this.onDragEnded,
    required this.onMove,
    required this.child,
  });

  final int index;
  final bool isHeld;
  final ValueChanged<int> onDragStarted;
  final ValueChanged<int> onDragEnded;
  final void Function(int oldIndex, int targetIndex) onMove;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DragTarget<int>(
      onWillAcceptWithDetails: (details) => details.data != index,
      onAcceptWithDetails: (details) => onMove(details.data, index),
      builder: (context, candidateData, rejectedData) {
        final isTargeted = candidateData.isNotEmpty;
        final tile = AnimatedScale(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          scale: isTargeted ? 0.96 : 1,
          child: Opacity(opacity: isHeld ? 0.45 : 1, child: child),
        );

        return LongPressDraggable<int>(
          data: index,
          onDragStarted: () => onDragStarted(index),
          onDragEnd: (_) => onDragEnded(index),
          onDraggableCanceled: (_, _) => onDragEnded(index),
          feedback: Material(
            type: MaterialType.transparency,
            child: SizedBox(width: 168, height: 168, child: child),
          ),
          childWhenDragging: Opacity(opacity: 0.28, child: child),
          child: tile,
        );
      },
    );
  }
}
