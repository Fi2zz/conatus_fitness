import '../voice/voice_io.dart';
import 'reactive_agent.dart';

/// 内置 ASR/TTS 能力的 Agent 基类（架构 4.2）。
///
/// 语音域 Agent（Intent / Dialog / Feedback）继承此类，
/// 通过共享的 [VoiceIO] 基础设施收发声学交互。
abstract class VoiceAgent extends ReactiveAgent {
  VoiceAgent(super.bus, {required super.name, required this.voiceIO});

  final VoiceIO voiceIO;
}
