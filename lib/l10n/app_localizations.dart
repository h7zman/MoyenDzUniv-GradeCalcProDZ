import 'package:flutter/material.dart';

enum AppLanguage {
  english('en'),
  arabic('ar');

  const AppLanguage(this.code);

  final String code;

  static AppLanguage fromCode(String? code) {
    return code == arabic.code ? arabic : english;
  }

  Locale get locale => Locale(code);

  TextDirection get textDirection {
    return this == arabic ? TextDirection.rtl : TextDirection.ltr;
  }

  String get nativeName {
    return this == arabic ? 'العربية' : 'English';
  }

  String get englishName {
    return this == arabic ? 'Arabic' : 'English';
  }
}

class AppText {
  const AppText(this.appLanguage);

  static const supportedLocales = [Locale('en'), Locale('ar')];

  final AppLanguage appLanguage;

  bool get isArabic => appLanguage == AppLanguage.arabic;

  TextDirection get direction => appLanguage.textDirection;

  static AppText of(BuildContext context) => AppTextScope.of(context).text;

  String pick(String english, String arabic) => isArabic ? arabic : english;

  String get appName => 'GradeCalcDZ';
  String get byH7Zman => pick('By H7Z man', 'بواسطة H7Z man');
  String get english => 'English';
  String get arabic => 'العربية';
  String get language => pick('Language', 'اللغة');
  String get chooseLanguage => pick('Choose language', 'اختر اللغة');
  String get finalResult => pick('Final Result', 'النتيجة النهائية');
  String get importAndExport => pick('Import and export', 'الاستيراد والتصدير');
  String get themes => pick('Themes', 'الألوان');
  String get addSemester => pick('Add semester', 'إضافة سداسي');
  String get addModule => pick('Add Module', 'إضافة مادة');
  String get overallStats => pick('Overall Stats', 'إحصائيات عامة');
  String get total => pick('Total', 'المجموع');
  String get graded => pick('Graded', 'مقيّمة');
  String get modulesWord => pick('modules', 'مواد');
  String get moduleNameHint => pick('Module name', 'اسم المادة');
  String get noModulesYet => pick('No modules yet', 'لا توجد مواد بعد');
  String get tapAddModuleToStart =>
      pick('Tap "Add Module" to start.', 'اضغط "إضافة مادة" للبدء.');
  String get searchModules => pick('Search modules', 'ابحث عن مادة');
  String get noModulesFound =>
      pick('No modules found', 'لم يتم العثور على مواد');

  String modulesCount(int count) => pick('$count modules', '$count مادة');
  String modulesValue(int count) => pick('modules: $count', 'المواد: $count');

  String get downloadTextFile => pick('Download text file', 'تنزيل ملف نصي');
  String get shareTextFile => pick('Share text file', 'مشاركة ملف نصي');
  String get downloadPdfReport =>
      pick('Download PDF report', 'تنزيل تقرير PDF');
  String get sharePdfReport => pick('Share PDF report', 'مشاركة تقرير PDF');
  String get predictionMode => pick('Prediction mode', 'وضع التوقع');
  String get importSemesterTextFile =>
      pick('Import semester from text file', 'استيراد سداسي من ملف نصي');
  String get exportJsonBackup => pick('Export JSON backup', 'تصدير نسخة JSON');
  String get importJsonBackup =>
      pick('Import JSON backup', 'استيراد نسخة JSON');
  String get developerAndSupport =>
      pick('Developer and support', 'المطور والدعم');
  String get githubPage => pick('GitHub page', 'صفحة GitHub');
  String get telegramChannel => pick('Telegram', 'Telegram');
  String get suggestionsEmail =>
      pick('Suggestions and notes', 'الاقتراحات والملاحظات');
  String linkCopiedToClipboard(String value) => pick(
    'Could not open the link. Copied $value instead.',
    'تعذر فتح الرابط. تم نسخ $value بدلا من ذلك.',
  );
  String get couldNotOpenLink =>
      pick('Could not open this link.', 'تعذر فتح هذا الرابط.');
  String get importJsonBackupQuestion =>
      pick('Import JSON backup?', 'استيراد نسخة JSON؟');
  String get importJsonBackupWarning => pick(
    'This replaces your current semesters and saved templates.',
    'سيتم استبدال السداسيات والقوالب المحفوظة حاليا.',
  );
  String get cancel => pick('Cancel', 'إلغاء');
  String get import => pick('Import', 'استيراد');
  String get save => pick('Save', 'حفظ');
  String get delete => pick('Delete', 'حذف');
  String get blankSemester => pick('Blank semester', 'سداسي فارغ');
  String get deleteTemplate => pick('Delete template', 'حذف القالب');
  String get templateDeleted => pick('Template deleted.', 'تم حذف القالب.');
  String get renameSemester => pick('Rename semester', 'تغيير اسم السداسي');
  String get saveAsTemplate => pick('Save as template', 'حفظ كقالب');
  String get deleteSemester => pick('Delete semester', 'حذف السداسي');
  String get deleteSemesterQuestion => pick('Delete semester?', 'حذف السداسي؟');
  String get semesterNameHint => pick('Semester name', 'اسم السداسي');
  String get saveSemesterTemplate =>
      pick('Save semester template', 'حفظ قالب السداسي');
  String get templateNameHint => pick('Template name', 'اسم القالب');
  String get unlockModuleBeforeEditing => pick(
    'Unlock this module before editing.',
    'افتح قفل هذه المادة قبل تعديلها.',
  );
  String get deleteModuleQuestion => pick('Delete module?', 'حذف المادة؟');

  String semesterRemovedMessage(String name) => pick(
    '"$name" and all its modules will be removed.',
    'سيتم حذف "$name" وكل مواده.',
  );

  String moduleRemovedMessage(String name) =>
      pick('"$name" will be removed permanently.', 'سيتم حذف "$name" نهائيا.');

  String templateSavedMessage(String name) =>
      pick('Template "$name" saved.', 'تم حفظ القالب "$name".');

  String get moduleScoreEntry =>
      pick('Module Score Entry', 'إدخال علامات المادة');
  String get locked => pick('Locked', 'مقفلة');
  String get weightingSplit => pick('Weighting/Split', 'الأوزان والتقسيم');
  String get custom => pick('Custom', 'مخصص');
  String get examPercent => pick('Exam %', 'نسبة الامتحان');
  String get ccPercent => pick('CC %', 'نسبة الأعمال');
  String get coeffInputLabel => pick('Coeff (1.0)', 'المعامل (1.0)');
  String tdPercentLabel(int percent) => 'TD ($percent%)';
  String tpPercentLabel(int percent) => 'TP ($percent%)';
  String examInputLabel(int percent) =>
      pick('Exam ($percent%)', 'الامتحان ($percent%)');
  String get tdTpNoteTitle => pick('TD/TP note', 'ملاحظة TD/TP');
  String get tdTpNoteBody => pick(
    'If the module has only TD or only TP, leave the other field empty, or enter the same mark in both fields.',
    'إذا كانت المادة تحتوي على TD فقط أو TP فقط، اترك الخانة الأخرى فارغة، أو اكتب نفس العلامة في الخانتين.',
  );
  String get calculator => pick('Calculator', 'الحاسبة');
  String liveCalculation(int examPercent, int ccPercent) => pick(
    'Live calculation using Exam $examPercent% and CC $ccPercent%',
    'حساب مباشر باستعمال الامتحان $examPercent% والأعمال $ccPercent%',
  );
  String get cc => 'CC';
  String get moduleAverage => pick('Module Avg', 'معدل المادة');
  String get average => pick('Average', 'المعدل');
  String get weightedAverage => pick('Avg x Coeff', 'المعدل x المعامل');
  String get howItWorks => pick('How it works', 'طريقة الحساب');
  String get exactFormula => pick(
    'See the exact calculation formula',
    'اطلع على معادلة الحساب الدقيقة',
  );
  String get formulaCc => pick(
    '1) CC = (TD + TP) / 2 (or TD / TP if only one exists).',
    '1) CC = (TD + TP) / 2 (أو TD / TP إذا كانت واحدة فقط موجودة).',
  );
  String formulaModuleAverage(int examPercent, int ccPercent) => pick(
    '2) Module average = Exam x $examPercent% + CC x $ccPercent% (percentages / 100).',
    '2) معدل المادة = الامتحان x $examPercent% + CC x $ccPercent% (النسب / 100).',
  );
  String get formulaSemesterAverage => pick(
    '3) Semester average = sum(Module average x Coeff) / sum(Coeff).',
    '3) معدل السداسي = مجموع(معدل المادة x المعامل) / مجموع المعاملات.',
  );
  String get lockedModule => pick('Locked Module', 'مادة مقفلة');
  String get saveModule => pick('Save Module', 'حفظ المادة');

  String moduleTitle(int index) => pick('Module $index', 'المادة $index');
  String moduleTitlePrefix(int index) => '${moduleTitle(index)}: ';
  String coeffValue(String value) => pick('Coeff: $value', 'المعامل: $value');
  String get avgPrefix => pick('Avg: ', 'المعدل: ');
  String get edit => pick('Edit', 'تعديل');
  String get copy => pick('Copy', 'نسخ');
  String get unlock => pick('Unlock', 'فتح');
  String get lock => pick('Lock', 'قفل');

  String get fixSplit => pick('Fix split', 'صحح التقسيم');
  String get percentagesMustEqual100 => pick(
    'Exam and CC percentages must equal 100.',
    'يجب أن يكون مجموع نسب الامتحان وCC يساوي 100.',
  );
  String get alreadyPassing => pick('Already passing', 'ناجح حاليا');
  String currentModuleAverage(String grade) => pick(
    'Current module average is $grade/20.',
    'معدل المادة الحالي هو $grade/20.',
  );
  String get belowPassMark => pick('Below pass mark', 'أقل من علامة النجاح');
  String needMorePoints(String points) =>
      pick('You need +$points points.', 'تحتاج إلى +$points نقاط.');
  String get needMoreGrades => pick('Need more grades', 'تحتاج علامات أكثر');
  String get enterExamOrCc => pick(
    'Enter at least one Exam or CC grade to calculate the pass target.',
    'أدخل علامة امتحان أو CC واحدة على الأقل لحساب هدف النجاح.',
  );
  String get passTargetCovered =>
      pick('Pass target covered', 'هدف النجاح مغطى');
  String existingGradesCover(String target) => pick(
    'The existing grades already cover a $target/20 target.',
    'العلامات الحالية تكفي لهدف $target/20.',
  );
  String get targetNotReachable =>
      pick('Target not reachable', 'الهدف غير ممكن');
  String scoreAboveMaximum(String label, String score) => pick(
    '$label would need $score/20, which is above the maximum.',
    '$label يحتاج $score/20، وهذا أعلى من الحد الأقصى.',
  );
  String needScoreIn(String score, String label) =>
      pick('Need $score/20 in $label', 'تحتاج $score/20 في $label');
  String reachesTarget(String target) => pick(
    'This reaches a $target/20 module average.',
    'هذا يوصلك إلى معدل مادة $target/20.',
  );
  String get exam => pick('Exam', 'الامتحان');
  String get ccAverage => pick('CC average', 'معدل CC');

  String get predictionModeTitle => pick('Prediction Mode', 'وضع التوقع');
  String get predictedAverage => pick('Predicted average', 'المعدل المتوقع');
  String coeffShortValue(String value) =>
      pick('Coeff $value', 'المعامل $value');

  String overallResult(String value) =>
      pick('Overall: $value/20', 'العام: $value/20');
  String get admitted => pick('Admitted', 'ناجح');
  String get notAdmitted => pick('Not Admitted', 'غير ناجح');
  String get semesterBreakdown => pick('Semester Breakdown', 'تفصيل السداسيات');

  String get quickCalculator => pick('Quick Calculator', 'حاسبة سريعة');
  String get quickCalculatorSubtitle => pick(
    'Calculate a module grade instantly (60% Exam / 40% CC).',
    'احسب معدل المادة مباشرة (60% امتحان / 40% CC).',
  );
  String get tdScore => pick('TD Score', 'علامة TD');
  String get tpScore => pick('TP Score', 'علامة TP');
  String get examScore => pick('Exam Score', 'علامة الامتحان');
  String get result => pick('Result', 'النتيجة');
}

class AppTextScope extends InheritedWidget {
  const AppTextScope({super.key, required this.text, required super.child});

  final AppText text;

  static AppTextScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppTextScope>();
    assert(scope != null, 'No AppTextScope found in context');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppTextScope oldWidget) {
    return text.appLanguage != oldWidget.text.appLanguage;
  }
}
