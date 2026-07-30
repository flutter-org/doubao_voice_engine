import 'voice_engine_defines.dart';

/// 引擎事件数据模型
class VoiceEngineEvent {
  /// 事件类型
  final VoiceEngineEventType type;

  /// 文本数据（ASR 结果、Chat 回复、错误信息等）
  final String? text;

  /// 二进制音频数据
  final List<int>? audio;

  const VoiceEngineEvent({
    required this.type,
    this.text,
    this.audio,
  });

  @override
  String toString() => 'VoiceEngineEvent(type: $type, text: $text)';
}
