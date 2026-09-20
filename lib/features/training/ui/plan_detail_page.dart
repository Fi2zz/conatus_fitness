import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/domain_placeholder.dart';
import '../domain/training_plan.dart';
import '../providers.dart';
import 'week_section.dart';

/// 计划详情：按周分组的训练内容展示。
class PlanDetailPage extends ConsumerWidget {
  const PlanDetailPage({super.key, required this.planId});

  final String planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(planDetailProvider(planId));
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('训练计划')),
      child: SafeArea(
        child: detail.when(
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (error, _) => const DomainPlaceholder(
            icon: CupertinoIcons.exclamationmark_triangle,
            title: '加载失败',
            subtitle: '请返回后重试',
          ),
          data: (stored) {
            if (stored == null) {
              return const DomainPlaceholder(
                icon: CupertinoIcons.doc_text_search,
                title: '计划不存在',
                subtitle: '该计划可能已被删除',
              );
            }
            return _PlanListView(plan: stored.plan);
          },
        ),
      ),
    );
  }
}

class _PlanListView extends StatelessWidget {
  const _PlanListView({required this.plan});

  final TrainingPlan plan;

  @override
  Widget build(BuildContext context) {
    final sections = <Widget>[
      for (final week in plan.weeks) WeekSection(week: week),
      if (plan.safetyNotes.isNotEmpty)
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '安全说明：${plan.safetyNotes}',
            style: const TextStyle(
              fontSize: 13,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
        ),
    ];
    return ListView(children: sections);
  }
}
