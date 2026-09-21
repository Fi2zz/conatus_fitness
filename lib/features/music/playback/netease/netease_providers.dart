import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../di/app_providers.dart';
import '../../../../di/credentials_providers.dart';
import '../domain/netease_account.dart';
import 'netease_auth.dart';
import 'netease_client.dart';
import 'netease_config.dart';
import 'netease_device.dart';
import 'netease_device_store.dart';
import 'netease_profile.dart';

/// 设备指纹：读盘取回（首次生成后落盘），进程内复用 —— 授权令牌与设备绑定。
final neteaseDeviceProvider = Provider<Future<NeteaseDevice>>(
  (ref) => ref
      .watch(sharedPreferencesProvider.future)
      .then(NeteaseDeviceStore.loadOrCreate),
);

/// 网易云音源配置：appId / 私钥齐备时才可用，否则为 null。
final neteaseConfigProvider = Provider<NeteaseConfig?>((ref) {
  final config = ref.watch(appConfigDefaultsProvider);
  final netease = NeteaseConfig(
    appId: config.neteaseAppId,
    privateKey: config.neteasePrivateKey,
    apiBaseUrl: config.neteaseApiBaseUrl.isEmpty
        ? NeteaseConfig.defaultApiBaseUrl
        : config.neteaseApiBaseUrl,
  );
  return netease.isConfigured ? netease : null;
});

/// 开放平台客户端：音源与登录页共用，生命周期随 App。
final neteaseClientProvider = Provider<NeteaseClient?>((ref) {
  final netease = ref.watch(neteaseConfigProvider);
  if (netease == null) return null;
  final client = NeteaseClient(
    config: netease,
    device: ref.watch(neteaseDeviceProvider),
  );
  ref.onDispose(client.close);
  return client;
});

/// 登录态与登录动作；音源未装配时为 null。
final neteaseAuthProvider = Provider<NeteaseAuth?>((ref) {
  final client = ref.watch(neteaseClientProvider);
  if (client == null) return null;
  return NeteaseAuth(
    client: client,
    credentials: ref.watch(credentialsProvider.future),
  );
});

/// 是否已登录网易云（登录页授权成功后 invalidate 它）。
final neteaseLoggedInProvider = FutureProvider<bool>((ref) async {
  final auth = ref.watch(neteaseAuthProvider);
  return auth != null && await auth.loggedIn();
});

/// 账号资料（含会员态）：进程内缓存一次，登录成功后 invalidate。
final neteaseProfileProvider = Provider<NeteaseProfile?>((ref) {
  final client = ref.watch(neteaseClientProvider);
  final auth = ref.watch(neteaseAuthProvider);
  if (client == null || auth == null) return null;
  return NeteaseProfile(client: client, auth: auth);
});

/// 账号快照（昵称 / 会员态），UI 展示用；未登录或取不到为 null。
final neteaseAccountProvider = FutureProvider<NeteaseAccount?>((ref) {
  final profile = ref.watch(neteaseProfileProvider);
  return profile?.account();
});
