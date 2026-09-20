import 'event_envelope.dart';
import 'voice_feedback.dart';
import 'voice_intents.dart';

/// 语音域事件（架构 4.4）。
sealed class VoiceEvent extends AppEvent {
  VoiceEvent({required super.sourceAgent, super.trace});
}

/// 唤醒词命中。
class WakeWordDetected extends VoiceEvent {
  WakeWordDetected({
    required super.sourceAgent,
    required this.phrase,
    super.trace,
  });

  final String phrase;

  @override
  EventPriority get priority => EventPriority.userCommand;
}

/// 检测到用户开始说话。
class SpeechStarted extends VoiceEvent {
  SpeechStarted({required super.sourceAgent, super.trace});
}

/// 检测到用户说话结束。
class SpeechEnded extends VoiceEvent {
  SpeechEnded({required super.sourceAgent, super.trace});
}

/// 流式 ASR 中间结果。
class AsrPartial extends VoiceEvent {
  AsrPartial({required super.sourceAgent, required this.text, super.trace});

  final String text;

  @override
  EventPriority get priority => EventPriority.content;
}

/// ASR 最终结果。
class AsrFinal extends VoiceEvent {
  AsrFinal({required super.sourceAgent, required this.text, super.trace});

  final String text;

  @override
  EventPriority get priority => EventPriority.userCommand;
}

/// 意图识别完成。
class IntentRecognized extends VoiceEvent {
  IntentRecognized({
    required super.sourceAgent,
    required this.intent,
    super.trace,
  });

  final VoiceIntent intent;

  @override
  EventPriority get priority => EventPriority.userCommand;
}

/// TTS 播报生命周期。
class TtsStarted extends VoiceEvent {
  TtsStarted({required super.sourceAgent, required this.handle, super.trace});

  final String handle;
}

class TtsCompleted extends VoiceEvent {
  TtsCompleted({required super.sourceAgent, required this.handle, super.trace});

  final String handle;
}

class TtsInterrupted extends VoiceEvent {
  TtsInterrupted({
    required super.sourceAgent,
    required this.handle,
    super.trace,
  });

  final String handle;
}

/// 副语言情绪检出（架构 7.3）。
class VoiceEmotionDetected extends VoiceEvent {
  VoiceEmotionDetected({
    required super.sourceAgent,
    required this.feedback,
    super.trace,
  });

  final VoiceFeedback feedback;
}
