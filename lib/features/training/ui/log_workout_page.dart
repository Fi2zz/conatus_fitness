import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../common/app_dialogs.dart';
import '../data/workout_logs_dao.dart';
import '../providers.dart';

/// 训练记录录入页：一次进入 = 一次训练课（session），连续记录共享。
class LogWorkoutPage extends ConsumerStatefulWidget {
  const LogWorkoutPage({super.key});

  @override
  ConsumerState<LogWorkoutPage> createState() => _LogWorkoutPageState();
}

class _LogWorkoutPageState extends ConsumerState<LogWorkoutPage> {
  final _exerciseController = TextEditingController();
  final _weightController = TextEditingController();
  final _repsController = TextEditingController();
  double _rpe = 8;
  bool _recordRpe = false;
  int _savedSets = 0;
  final String _sessionId = const Uuid().v4();

  @override
  Widget build(BuildContext context) {
    final exerciseField = CupertinoTextField(
      controller: _exerciseController,
      placeholder: '动作名，如：深蹲',
    );
    final weightField = CupertinoTextField(
      controller: _weightController,
      placeholder: '重量 kg',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
    );
    final repsField = CupertinoTextField(
      controller: _repsController,
      placeholder: '次数',
      keyboardType: const TextInputType.numberWithOptions(),
    );
    final rpeToggle = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('记录 RPE', style: TextStyle(fontSize: 15)),
        CupertinoSwitch(
          value: _recordRpe,
          onChanged: (v) => setState(() => _recordRpe = v),
        ),
      ],
    );
    final rpeSlider = CupertinoSlider(
      value: _rpe,
      min: 0,
      max: 10,
      divisions: 10,
      onChanged: (v) => setState(() => _rpe = v),
    );
    final savedText = Text(
      '本次训练已记录 $_savedSets 组',
      style: const TextStyle(color: CupertinoColors.secondaryLabel),
      textAlign: TextAlign.center,
    );
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('记录训练')),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
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
            rpeToggle,
            if (_recordRpe) ...[
              rpeSlider,
              Center(child: Text('RPE ${_rpe.toStringAsFixed(0)}')),
            ],
            const SizedBox(height: 32),
            CupertinoButton.filled(
              onPressed: _submit,
              child: const Text('记录这一组'),
            ),
            if (_savedSets > 0) ...[const SizedBox(height: 12), savedText],
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final exercise = _exerciseController.text.trim();
    final weight = double.tryParse(_weightController.text.trim());
    final reps = int.tryParse(_repsController.text.trim());
    if (exercise.isEmpty ||
        weight == null ||
        weight <= 0 ||
        reps == null ||
        reps <= 0) {
      await showAppAlert(context, '请填写动作名、大于 0 的重量与次数');
      return;
    }
    final dao = await ref.read(workoutLogsDaoProvider.future);
    final setNumber = await dao.nextSetNumber(_sessionId, exercise);
    await dao.save(
      WorkoutSetLog(
        exercise: exercise,
        setNumber: setNumber,
        weight: weight,
        reps: reps,
        rpe: _recordRpe ? _rpe : null,
        sessionId: _sessionId,
        performedAt: DateTime.now(),
      ),
    );
    if (!mounted) return;
    setState(() {
      _savedSets++;
      _weightController.clear();
      _repsController.clear();
    });
  }
}
