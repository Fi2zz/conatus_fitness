import 'package:flutter/cupertino.dart';

import '../../../core/format/date_text.dart';

/// 日期选择行（补录用）：显示当前值，点击弹出日期选择器。
class DateField extends StatelessWidget {
  const DateField({super.key, required this.date, required this.onChanged});

  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final row = GestureDetector(
      onTap: () => _pick(context),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('日期', style: TextStyle(fontSize: 15)),
          Text(
            dateText(date),
            style: const TextStyle(fontSize: 15, color: CupertinoColors.activeBlue),
          ),
        ],
      ),
    );
    return row;
  }

  void _pick(BuildContext context) {
    final picker = CupertinoDatePicker(
      mode: CupertinoDatePickerMode.date,
      initialDateTime: date,
      maximumDate: DateTime.now(),
      onDateTimeChanged: onChanged,
    );
    showCupertinoModalPopup<void>(
      context: context,
      builder: (_) => Container(
        height: 260,
        color: CupertinoColors.systemBackground,
        child: SafeArea(child: picker),
      ),
    );
  }
}
