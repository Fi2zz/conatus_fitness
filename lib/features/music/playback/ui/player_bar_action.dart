import 'package:flutter/cupertino.dart';

/// 播放条上的圆形动作按钮。
class PlayerBarAction extends StatelessWidget {
  const PlayerBarAction({
    super.key,
    required this.icon,
    required this.onPressed,
    this.enabled = true,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      minimumSize: const Size(32, 32),
      onPressed: enabled ? onPressed : null,
      child: Icon(icon, size: 22, color: CupertinoColors.systemBlue),
    );
  }
}
