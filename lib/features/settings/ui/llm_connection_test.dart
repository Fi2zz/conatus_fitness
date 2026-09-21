import 'package:flutter/cupertino.dart';

import 'llm_settings_actions.dart';

/// 连通性测试按钮与结果：把服务端原文摆到界面上，省得只靠终端排障。
class LlmConnectionTest extends StatefulWidget {
  const LlmConnectionTest({
    super.key,
    required this.baseUrl,
    required this.model,
    required this.apiKey,
  });

  /// 直接读输入框：测试的是当前填的值，与是否已保存无关。
  final TextEditingController baseUrl;
  final TextEditingController model;
  final TextEditingController apiKey;

  @override
  State<LlmConnectionTest> createState() => _LlmConnectionTestState();
}

class _LlmConnectionTestState extends State<LlmConnectionTest> {
  String? _result;
  bool _testing = false;

  Future<void> _run() async {
    setState(() {
      _testing = true;
      _result = null;
    });
    final result = await probeLlm(
      baseUrl: widget.baseUrl.text.trim(),
      model: widget.model.text.trim(),
      apiKey: widget.apiKey.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _testing = false;
      _result = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CupertinoButton(
          onPressed: _testing ? null : _run,
          child: Text(_testing ? '测试中…' : '测试连接'),
        ),
        if (result != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              result,
              style: const TextStyle(
                fontSize: 13,
                color: CupertinoColors.secondaryLabel,
              ),
            ),
          ),
      ],
    );
  }
}
