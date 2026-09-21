import 'package:flutter/cupertino.dart';

/// 设置项文本输入：上方标签 + 输入框。
class SettingsTextField extends StatelessWidget {
  const SettingsTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.placeholder,
    this.obscure = false,
  });

  final TextEditingController controller;
  final String label;
  final String placeholder;
  final bool obscure;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
          const SizedBox(height: 6),
          CupertinoTextField(
            controller: controller,
            placeholder: placeholder,
            obscureText: obscure,
            autocorrect: false,
          ),
        ],
      ),
    );
  }
}