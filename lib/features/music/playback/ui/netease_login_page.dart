import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/domain_placeholder.dart';
import '../netease/netease_providers.dart';
import 'netease_login_session.dart';
import 'netease_login_web.dart';

/// 网易云登录：App 内打开官方授权网页，用户自行登录并授权。
///
/// 授权由服务端按设备下发，故同时轮询票据；拿到令牌即返回 `true`，
/// 调用方据此继续原动作（如开始播放）。
class NeteaseLoginPage extends ConsumerStatefulWidget {
  const NeteaseLoginPage({super.key});

  @override
  ConsumerState<NeteaseLoginPage> createState() => _NeteaseLoginPageState();
}

class _NeteaseLoginPageState extends ConsumerState<NeteaseLoginPage> {
  NeteaseLoginSession? _session;

  @override
  void initState() {
    super.initState();
    final auth = ref.read(neteaseAuthProvider);
    if (auth == null) return;
    final session = NeteaseLoginSession(
      auth: auth,
      onChanged: _refresh,
      onAuthorized: _finish,
    );
    _session = session;
    unawaited(session.start());
  }

  @override
  void dispose() {
    _session?.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _finish() {
    // 换了账号：登录态与会员态都要重取。
    ref.read(neteaseProfileProvider)?.invalidate();
    ref.invalidate(neteaseLoggedInProvider);
    ref.invalidate(neteaseAccountProvider);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('登录网易云'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('关闭'),
        ),
      ),
      child: SafeArea(
        child: session == null
            ? const DomainPlaceholder(
                icon: CupertinoIcons.exclamationmark_triangle,
                title: '登录页打不开',
                subtitle: '还没配置网易云 appId 与私钥',
              )
            : NeteaseLoginWeb(
                controller: session.web,
                error: session.error,
                notice: session.notice,
              ),
      ),
    );
  }
}
