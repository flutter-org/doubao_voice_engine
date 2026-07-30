/// 豆包语音端到端实时语音大模型 Flutter 插件
///
/// 基于 Pigeon 类型安全平台通道封装 Android/iOS 原生 SDK，
/// 提供低延迟、双向流式语音交互能力。
library doubao_voice_engine;

// Main engine
export 'src/doubao_voice_engine_impl.dart';

// Models
export 'src/models/voice_engine_config.dart';
export 'src/models/voice_engine_event.dart';
export 'src/models/voice_engine_defines.dart';

// Pigeon generated (for advanced type access)
export 'src/messages.g.dart' show EngineConfigMessage, DirectiveRequest, EngineEventMessage;
