import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../di/app_providers.dart';
import 'netease/netease_config.dart';
import 'netease/netease_music_source.dart';
import 'source/music_source.dart';

/// 网易云音源配置：凭据由 env 注入，配置不齐时为 null。
final neteaseConfigProvider = Provider<NeteaseConfig?>((ref) {
  final config = ref.watch(appConfigDefaultsProvider);
  final netease = NeteaseConfig(
    appId: config.neteaseAppId,
    privateKey: config.neteasePrivateKey,
    apiBaseUrl: config.neteaseApiBaseUrl,
  );
  return netease.isComplete ? netease : null;
});

/// 当前音源装配；未配置时为 null（播放器装配与 UI 引导态的判定入口）。
final musicSourceProvider = Provider<MusicSource?>((ref) {
  final netease = ref.watch(neteaseConfigProvider);
  if (netease == null) return null;
  final source = NeteaseMusicSource(netease);
  ref.onDispose(source.dispose);
  return source;
});