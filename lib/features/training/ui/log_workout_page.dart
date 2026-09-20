import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../common/app_dialogs.dart';
import '../data/workout_logs_dao.dart';
import '../providers.dart';
import 'log_set_form.dart';

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
  DateTime _date = DateTime.now();
  int _savedSets = 0;
  final String _sessionId = const Uuid().v4();

  @override
  Widget build(BuildContext context) {
    final form = LogSetForm(
      exercise: _exerciseController,
      weight: _weightController,
      reps: _repsController,
      rpe: _rpe,
      recordRpe: _recordRpe,
      date: _date,
      onDateChanged: (value) => setState(() => _date = value),
      onToggleRpe: (value) => setState(() => _recordRpe = value),
      onRpeChanged: (value) => setState(() => _rpe = value),
      savedSets: _savedSets,
    );
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('记录训练')),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            form,
            const SizedBox(height: 32),
            CupertinoButton.filled(
              onPressed: _submit,
              child: const Text('记录这一组'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final exercise = _exerciseController.text.trim();
    final weight = double.tryParse(_weightController.text.trim());
    final reps = int.tryParse(_repsController.text.trim());
    final valid =
        exercise.isNotEmpty &&
        weight != null &&
        weight > 0 &&
        reps != null &&
        reps > 0;
    if (!valid) {
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
        performedAt: _date,
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
