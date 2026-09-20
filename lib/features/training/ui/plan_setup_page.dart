import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/app_dialogs.dart';
import '../agents/planner_input.dart';
import '../providers.dart';
import 'plan_generation_flow.dart';
import 'plan_profile_form.dart';

/// 训练画像录入：Planner Agent 的输入表单。
class PlanSetupPage extends ConsumerStatefulWidget {
  const PlanSetupPage({super.key});

  @override
  ConsumerState<PlanSetupPage> createState() => _PlanSetupPageState();
}

class _PlanSetupPageState extends ConsumerState<PlanSetupPage> {
  final _goal = TextEditingController();
  final _equipment = TextEditingController();
  final _injuries = TextEditingController();
  int _level = 1;
  int _days = 3;
  int _weeks = 1;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    ref.read(profileProvider.future).then((profile) {
      if (profile == null || !mounted) return;
      final levelIndex = planLevels.indexOf(profile.fitnessLevel);
      setState(() {
        _goal.text = profile.goal;
        _equipment.text = profile.equipment;
        _injuries.text = profile.injuries;
        if (levelIndex >= 0) _level = levelIndex;
        _days = profile.daysPerWeek;
      });
    });
  }

  @override
  void dispose() {
    _goal.dispose();
    _equipment.dispose();
    _injuries.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trailing = CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: _generating ? null : _submit,
      child: const Text('生成'),
    );
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('生成训练计划'),
        trailing: trailing,
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            PlanProfileForm(
              goal: _goal,
              equipment: _equipment,
              injuries: _injuries,
              level: _level,
              days: _days,
              weeks: _weeks,
              onLevel: (value) => setState(() => _level = value),
              onDays: (value) => setState(() => _days = value),
              onWeeks: (value) => setState(() => _weeks = value),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final goal = _goal.text.trim();
    if (goal.isEmpty) {
      await showAppAlert(context, '请填写训练目标');
      return;
    }
    setState(() => _generating = true);
    await generatePlan(
      context,
      ref,
      PlannerInput(
        goal: goal,
        fitnessLevel: planLevels[_level],
        daysPerWeek: _days,
        equipment: _equipment.text.trim(),
        injuries: _injuries.text.trim(),
        weeks: _weeks,
      ),
    );
    if (mounted) setState(() => _generating = false);
  }
}
