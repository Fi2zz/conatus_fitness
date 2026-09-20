/// 语音意图（架构 7.1）。上下文感知：同一句“换一首”在训练中/播报中含义不同。
sealed class VoiceIntent {
  const VoiceIntent();
}

/// 记录一组：“深蹲 100 公斤 5 次”。
class LogSetIntent extends VoiceIntent {
  const LogSetIntent({this.exercise, this.weight, this.reps});

  final String? exercise;
  final double? weight;
  final int? reps;
}

/// 调整计划。
class AdjustPlanIntent extends VoiceIntent {
  const AdjustPlanIntent({required this.action, this.params = const {}});

  final String action;
  final Map<String, Object?> params;
}

/// 音乐控制：“换歌”“小点声”。
class MusicControlIntent extends VoiceIntent {
  const MusicControlIntent({required this.action, this.params = const {}});

  final String action;
  final Map<String, Object?> params;
}

/// 提问：“下一组多少来着？”
class QueryIntent extends VoiceIntent {
  const QueryIntent(this.question);

  final String question;
}

/// 主观反馈：“太重了”“破纪录了”。
class FeedbackIntent extends VoiceIntent {
  const FeedbackIntent({required this.rating, this.target});

  final String rating;
  final String? target;
}

/// 自由聊天。
class ChatIntent extends VoiceIntent {
  const ChatIntent(this.message);

  final String message;
}

/// 无法识别，保留原文待澄清。
class UnknownIntent extends VoiceIntent {
  const UnknownIntent(this.rawText);

  final String rawText;
}
