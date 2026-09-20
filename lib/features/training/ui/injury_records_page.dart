import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/profile_dao.dart';
import '../providers.dart';

/// 伤病史编辑页：每行一条记录，写入画像 injuries 字段。
class InjuryRecordsPage extends ConsumerStatefulWidget {
  const InjuryRecordsPage({super.key});

  @override
  ConsumerState<InjuryRecordsPage> createState() => _InjuryRecordsPageState();
}

class _InjuryRecordsPageState extends ConsumerState<InjuryRecordsPage> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await ref.read(profileProvider.future);
    _controller.text = profile?.injuries ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final field = CupertinoTextField(
      controller: _controller,
      placeholder: '如：\n膝盖旧伤\n肩袖拉伤（2025）',
      maxLines: 8,
      minLines: 8,
    );
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('伤病史')),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              '伤病史',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const Text(
              '每行一条，供伤病防护与计划生成参考',
              style: TextStyle(color: CupertinoColors.secondaryLabel),
            ),
            const SizedBox(height: 12),
            field,
            const SizedBox(height: 24),
            CupertinoButton.filled(onPressed: _save, child: const Text('保存')),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final text = _controller.text.trim();
    final dao = await ref.read(profileDaoProvider.future);
    final current = await dao.load();
    await dao.save(
      UserProfile(
        goal: current?.goal ?? '',
        fitnessLevel: current?.fitnessLevel ?? '',
        daysPerWeek: current?.daysPerWeek ?? 0,
        equipment: current?.equipment ?? '',
        injuries: text.isEmpty ? '无' : text,
      ),
    );
    ref.invalidate(profileProvider);
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // 返回即已保存
  }
}
