/// yyyy-MM-dd（无 intl 依赖的轻量格式化）。
String dateText(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
