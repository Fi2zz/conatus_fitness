import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:conatus_fitness/app.dart';

void main() {
  testWidgets('首页渲染三个 Tab 与训练空态', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FitnessApp()));
    await tester.pumpAndSettle();

    expect(find.text('训练'), findsWidgets);
    expect(find.text('音乐'), findsWidgets);
    expect(find.text('我的'), findsWidgets);
    expect(find.text('AI 训练计划'), findsOneWidget);
  });
}
