import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/domain_placeholder.dart';
import '../data/workout_session.dart';
import '../providers.dart';
import 'workout_history_card.dart';

/// 训练历史页：按训练课分组，最新在前。
class WorkoutHistoryPage extends ConsumerWidget {
  const WorkoutHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(workoutHistoryProvider);
    final body = history.when(
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (error, _) => const DomainPlaceholder(
        icon: CupertinoIcons.clock,
        title: '训练历史',
        subtitle: '加载失败，请重试',
      ),
      data: (logs) {
        final sessions = groupBySession(logs);
        if (sessions.isEmpty) {
          return const DomainPlaceholder(
            icon: CupertinoIcons.clock,
            title: '训练历史',
            subtitle: '还没有训练记录，去记录第一组吧',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sessions.length,
          itemBuilder: (context, index) =>
              WorkoutHistoryCard(session: sessions[index]),
        );
      },
    );
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('训练历史')),
      child: SafeArea(child: body),
    );
  }
}
