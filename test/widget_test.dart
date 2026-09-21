import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:conatus_fitness/app.dart';

void main() {
  // 启动期要读配置与密钥（shared_preferences / flutter_secure_storage），
  // 测试环境须先装插件替身，否则这两个读操作永不返回。
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  testWidgets('首页渲染三个 Tab 与训练空态', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FitnessApp()));
    await tester.pumpAndSettle();

    expect(find.text('训练'), findsWidgets);
    expect(find.text('音乐'), findsWidgets);
    expect(find.text('我的'), findsWidgets);
    expect(find.text('AI 训练计划'), findsOneWidget);
  });
}
