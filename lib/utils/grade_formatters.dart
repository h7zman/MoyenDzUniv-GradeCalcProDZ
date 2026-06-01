String formatGrade(double value, {int decimals = 2}) {
  final fixed = value.toStringAsFixed(decimals);
  if (!fixed.contains('.')) {
    return fixed;
  }

  return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
}

String formatGradeOrDash(double? value, {int decimals = 2}) {
  if (value == null) {
    return '--';
  }
  return formatGrade(value, decimals: decimals);
}
