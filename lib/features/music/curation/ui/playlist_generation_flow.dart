import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/tools/tool.dart';
import '../../../../app.dart';
import '../../../common/app_dialogs.dart';
import '../agents/curator_input.dart';
import '../providers.dart';

/// 生成流程：调用 CuratorAgent → 结果处理（导航/提示）。
Future<void> generatePlaylist(
  BuildContext context,
  WidgetRef ref,
  CuratorInput input,
) async {
  final agent = await ref.read(curatorAgentProvider.future);
  if (!context.mounted) return;
  if (agent == null) {
    await showAppAlert(context, 'LLM 未配置，请检查启动参数');
    return;
  }
  showAppProgress(context, title: '正在策展歌单');
  final result = await agent.generate(input);
  if (!context.mounted) return;
  final navigator = Navigator.of(context, rootNavigator: true);
  navigator.pop(); // 关闭进度弹窗
  switch (result) {
    case Ok(:final value):
      ref.invalidate(playlistsProvider);
      navigator.pop(); // 关闭策展表单页
      navigator.pushNamed(AppRoutes.playlistDetail, arguments: value.id);
    case RetryableError(:final message):
      await showAppAlert(context, message);
    case FatalError(:final message, :final suggestion):
      await showAppAlert(
        context,
        suggestion == null ? message : '$message\n$suggestion',
      );
  }
}
