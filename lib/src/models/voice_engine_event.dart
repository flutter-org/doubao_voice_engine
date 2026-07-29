import 'voice_engine_defines.dart';

/// 引擎事件数据模型
class VoiceEngineEvent {
  /// 事件类型
  final VoiceEngineEventType type;

  /// 文本数据（ASR 结果、Chat 回复、错误信息等）
  final String? text;

  /// 二进制音频数据
  final List<int>? audio;

  /// 原始 JSON 数据（用于引擎状态等）
  final Map<String, dynamic>? json;

  const VoiceEngineEvent({
    required this.type,
    this.text,
    this.audio,
    this.json,
  });

  factory VoiceEngineEvent.fromMap(Map<String, dynamic> map) {
    final typeStr = map['type'] as String;
    final type = VoiceEngineEventType.values.firstWhere(
      (e) => eventTypeStrings[e] == typeStr,
      orElse: () => throw ArgumentError('Unknown event type: $typeStr'),
    );

    return VoiceEngineEvent(
      type: type,
      text: map['text'] as String?,
      audio: map['audio'] is List ? List<int>.from(map['audio']) : null,
      json: map['json'] as Map<String, dynamic>?,
    );
  }

  @override
  String toString() => 'VoiceEngineEvent(type: $type, text: $text)';
}
