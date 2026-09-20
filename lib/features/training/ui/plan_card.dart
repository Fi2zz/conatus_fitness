import 'package:flutter/cupertino.dart';

import '../../../app.dart';
import '../data/plans_dao.dart';

/// 历史计划卡片：周数标题 + 会话/安全状态摘要。
class PlanCard extends StatelessWidget {
  const PlanCard({super.key, required this.stored});

  final StoredPlan stored;

  @override
  Widget build(BuildContext context) {
    final plan = stored.plan;
    final weekCount = plan.weeks.length;
    var sessionCount = 0;
    for (final week in plan.weeks) {
      sessionCount += week.sessions.length;
    }
    final title = '$weekCount 周训练计划';
    final status = stored.safetyStatus == 'rewritten' ? '已安全调整' : '已通过安全校验';
    final created =
        '${stored.createdAt.month} 月 ${stored.createdAt.day} 日生成';
    final subtitle = '$sessionCount 次训练 · $status · $created';
    return GestureDetector(
      onTap: () => Navigator.of(context, rootNavigator: true).pushNamed(
        AppRoutes.planDetail,
        arguments: stored.id,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.label,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: CupertinoColors.secondaryLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
