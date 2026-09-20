import 'package:flutter/cupertino.dart';

import 'date_field.dart';

/// 训练录入表单控件集合（无业务逻辑；状态由宿主页持有）。
class LogSetForm extends StatelessWidget {
  const LogSetForm({
    super.key,
    required this.exercise,
    required this.weight,
    required this.reps,
    required this.rpe,
    required this.recordRpe,
    required this.date,
    required this.onDateChanged,
    required this.onToggleRpe,
    required this.onRpeChanged,
    required this.savedSets,
  });

  final TextEditingController exercise;
  final TextEditingController weight;
  final TextEditingController reps;
  final double rpe;
  final bool recordRpe;
  final DateTime date;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<bool> onToggleRpe;
  final ValueChanged<double> onRpeChanged;
  final int savedSets;

  @override
  Widget build(BuildContext context) {
    final exerciseField = CupertinoTextField(
      controller: exercise,
      placeholder: '动作名，如：深蹲',
    );
    final weightField = CupertinoTextField(
      controller: weight,
      placeholder: '重量 kg',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
    );
    final repsField = CupertinoTextField(
      controller: reps,
      placeholder: '次数',
      keyboardType: const TextInputType.numberWithOptions(),
    );
    final rpeToggle = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('记录 RPE', style: TextStyle(fontSize: 15)),
        CupertinoSwitch(value: recordRpe, onChanged: onToggleRpe),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '动作与组',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        exerciseField,
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: weightField),
            const SizedBox(width: 12),
            Expanded(child: repsField),
          ],
        ),
        const SizedBox(height: 24),
        DateField(date: date, onChanged: onDateChanged),
        const SizedBox(height: 12),
        rpeToggle,
        if (recordRpe) ...[
          CupertinoSlider(
            value: rpe,
            min: 0,
            max: 10,
            divisions: 10,
            onChanged: onRpeChanged,
          ),
          Center(child: Text('RPE ${rpe.toStringAsFixed(0)}')),
        ],
        if (savedSets > 0) ...[
          const SizedBox(height: 12),
          Text(
            '本次训练已记录 $savedSets 组',
            style: const TextStyle(color: CupertinoColors.secondaryLabel),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
