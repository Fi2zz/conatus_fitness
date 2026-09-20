import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/app_dialogs.dart';
import '../../common/segmented_row.dart';
import '../agents/curator_input.dart';
import 'playlist_generation_flow.dart';

/// 歌单策展表单：Curator Agent 的输入页。
class PlaylistSetupPage extends ConsumerStatefulWidget {
  const PlaylistSetupPage({super.key});

  @override
  ConsumerState<PlaylistSetupPage> createState() => _PlaylistSetupPageState();
}

class _PlaylistSetupPageState extends ConsumerState<PlaylistSetupPage> {
  final _focus = TextEditingController();
  final _vibe = TextEditingController();
  int _minutes = 45;
  bool _generating = false;

  @override
  void dispose() {
    _focus.dispose();
    _vibe.dispose();
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
        middle: const Text('策展歌单'),
        trailing: trailing,
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            CupertinoFormSection.insetGrouped(
              header: const Text('训练情境'),
              children: [
                CupertinoTextFormFieldRow(
                  prefix: const Text('类型'),
                  controller: _focus,
                  placeholder: '下肢力量 / 推拉 / 有氧',
                ),
                SegmentedRow(
                  label: '时长',
                  values: const [30, 45, 60],
                  labels: const ['30 分', '45 分', '60 分'],
                  selected: _minutes,
                  onChanged: (value) => setState(() => _minutes = value),
                ),
                CupertinoTextFormFieldRow(
                  prefix: const Text('氛围'),
                  controller: _vibe,
                  placeholder: '如：炸裂 / 怀旧 / 说唱，可留空',
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '按 热身 → 主项 → 力竭 → 拉伸 四阶段 BPM 曲线生成专属歌单',
                style: TextStyle(
                  fontSize: 13,
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final focus = _focus.text.trim();
    if (focus.isEmpty) {
      await showAppAlert(context, '请填写训练类型');
      return;
    }
    setState(() => _generating = true);
    await generatePlaylist(
      context,
      ref,
      CuratorInput(focus: focus, minutes: _minutes, vibe: _vibe.text.trim()),
    );
    if (mounted) setState(() => _generating = false);
  }
}
