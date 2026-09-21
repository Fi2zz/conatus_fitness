import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'netease_device.dart';

/// 设备指纹持久化：授权令牌与设备绑定，deviceId 必须跨启动稳定。
abstract final class NeteaseDeviceStore {
  /// 持久化键名（snake_case）。
  static const _key = 'netease_device_id';

  /// 读盘取回本机标识；首次调用生成并落盘。
  static Future<NeteaseDevice> loadOrCreate(SharedPreferences prefs) async {
    final String? stored = prefs.getString(_key);
    if (stored != null && stored.isNotEmpty) {
      return NeteaseDevice(deviceId: stored);
    }
    final String created = 'conatus_${const Uuid().v4().replaceAll('-', '')}';
    await prefs.setString(_key, created);
    return NeteaseDevice(deviceId: created);
  }
}
