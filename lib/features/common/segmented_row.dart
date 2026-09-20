import 'package:flutter/cupertino.dart';

/// 表单行：左侧标签 + 右侧 iOS 滑动分段选择。
class SegmentedRow extends StatelessWidget {
  const SegmentedRow({
    super.key,
    required this.label,
    required this.values,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final List<int> values;
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final children = <int, Widget>{
      for (var index = 0; index < values.length; index++)
        values[index]: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(labels[index]),
        ),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                color: CupertinoColors.label,
              ),
            ),
          ),
          Expanded(
            child: CupertinoSlidingSegmentedControl<int>(
              groupValue: selected,
              children: children,
              onValueChanged: (value) {
                if (value != null) onChanged(value);
              },
            ),
          ),
        ],
      ),
    );
  }
}
