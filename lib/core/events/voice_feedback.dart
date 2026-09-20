/// 副语言反馈（架构 7.3）：只存特征值，视为敏感数据。
class VoiceFeedback {
  const VoiceFeedback({
    this.sentiment,
    this.fatigueLevel,
    this.motivationLevel,
    this.isStruggling,
    this.confidence,
  });

  /// positive / negative / neutral。
  final String? sentiment;

  /// 0-1。
  final double? fatigueLevel;

  /// 0-1。
  final double? motivationLevel;
  final bool? isStruggling;

  /// < 0.5 表示不可信，消费方应忽略。
  final double? confidence;
}
