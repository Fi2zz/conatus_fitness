/// 监听模式（架构 8.5）。
enum AsrMode {
  /// 只监听唤醒词，训练中默认。
  passive,

  /// 唤醒词/按钮触发后的持续监听。
  active,

  /// 长语音输入。
  dictation,

  /// 只提取副语言信息，不执行指令。
  ambient,

  /// 关闭麦克风。
  silent,
}

/// TTS 风格标签，供引擎选择音色/语速。
class TtsStyle {
  const TtsStyle({this.engine = TtsEngine.local, this.speed = 1.0});

  final TtsEngine engine;
  final double speed;
}

enum TtsEngine { local, cloud }

/// 音频输出通道。
enum OutputChannel { speaker, bluetooth, earpiece }

/// ASR 识别结果。
class AsrResult {
  const AsrResult({required this.text, required this.isFinal, this.confidence = 1.0});

  final String text;
  final bool isFinal;
  final double confidence;
}

/// 一次 TTS 播报的句柄，用于打断/完成追踪。
class TtsHandle {
  const TtsHandle(this.id);

  final String id;
}

/// 唤醒事件。
class WakeEvent {
  const WakeEvent(this.phrase);

  final String phrase;
}

/// Voice I/O 统一 API（架构 8.4）。
///
/// 三域共享的基础设施缝；具体引擎（Whisper.cpp / flutter_tts / Porcupine）
/// 由 Phase 5 起注入实现。
abstract class VoiceIO {
  Stream<AsrResult> listen({AsrMode mode = AsrMode.active});
  Future<void> stopListening();
  bool get isListening;

  Future<TtsHandle> speak(String text, {TtsStyle style = const TtsStyle()});
  Future<void> stopSpeaking();

  Stream<WakeEvent> get onWakeWord;

  void setDucking(bool enabled);
  void setOutputChannel(OutputChannel channel);
}
