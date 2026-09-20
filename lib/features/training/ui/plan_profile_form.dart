import 'package:flutter/cupertino.dart';

import '../../common/segmented_row.dart';

const _levels = ['初级', '中级', '高级'];

/// 训练画像水平档位（供表单页组装时使用）。
List<String> get planLevels => _levels;

/// 训练画像表单：Planner Agent 的输入项。
class PlanProfileForm extends StatelessWidget {
  const PlanProfileForm({
    super.key,
    required this.goal,
    required this.equipment,
    required this.injuries,
    required this.level,
    required this.days,
    required this.weeks,
    required this.onLevel,
    required this.onDays,
    required this.onWeeks,
  });

  final TextEditingController goal;
  final TextEditingController equipment;
  final TextEditingController injuries;
  final int level;
  final int days;
  final int weeks;
  final ValueChanged<int> onLevel;
  final ValueChanged<int> onDays;
  final ValueChanged<int> onWeeks;

  @override
  Widget build(BuildContext context) {
    return CupertinoFormSection.insetGrouped(
      header: const Text('训练画像'),
      children: [
        CupertinoTextFormFieldRow(
          prefix: const Text('目标'),
          controller: goal,
          placeholder: '增肌 / 减脂 / 力量',
        ),
        SegmentedRow(
          label: '水平',
          values: const [0, 1, 2],
          labels: _levels,
          selected: level,
          onChanged: onLevel,
        ),
        SegmentedRow(
          label: '每周',
          values: const [2, 3, 4, 5],
          labels: const ['2 次', '3 次', '4 次', '5 次'],
          selected: days,
          onChanged: onDays,
        ),
        SegmentedRow(
          label: '周数',
          values: const [1, 2, 4],
          labels: const ['1', '2', '4'],
          selected: weeks,
          onChanged: onWeeks,
        ),
        CupertinoTextFormFieldRow(
          prefix: const Text('器械'),
          controller: equipment,
          placeholder: '健身房 / 哑铃 / 徒手',
        ),
        CupertinoTextFormFieldRow(
          prefix: const Text('伤病史'),
          controller: injuries,
          placeholder: '如：膝盖旧伤；无',
        ),
      ],
    );
  }
}
