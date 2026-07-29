/// 引擎名称
/// ⚠️ 必须为大写 'DIALOG_ENGINE'，与 SDK 常量 SpeechEngineDefines.DIALOG_ENGINE / SE_DIALOG_ENGINE 的值一致。
/// 之前误写为小写 'dialog_engine'，导致 SDK 找不到引擎实现，initEngine() 返回 -202。
const String dialogEngine = 'DIALOG_ENGINE';

// ============================================================
// 参数 Key 定义（与 Native SDK 一一对应）
// ============================================================

/// 引擎基础配置
const String paramsKeyEngineName = 'PARAMS_KEY_ENGINE_NAME_STRING';
const String paramsKeyDebugPath = 'PARAMS_KEY_DEBUG_PATH_STRING';
const String paramsKeyLogLevel = 'PARAMS_KEY_LOG_LEVEL_STRING';

/// 鉴权配置
const String paramsKeyAppId = 'PARAMS_KEY_APP_ID_STRING';
const String paramsKeyAppKey = 'PARAMS_KEY_APP_KEY_STRING';
const String paramsKeyAppToken = 'PARAMS_KEY_APP_TOKEN_STRING';
const String paramsKeyResourceId = 'PARAMS_KEY_RESOURCE_ID_STRING';
const String paramsKeyUid = 'PARAMS_KEY_UID_STRING';
const String paramsKeyDialogAddress = 'PARAMS_KEY_DIALOG_ADDRESS_STRING';
const String paramsKeyDialogUri = 'PARAMS_KEY_DIALOG_URI_STRING';

/// AEC 回声消除
const String paramsKeyEnableAec = 'PARAMS_KEY_ENABLE_AEC_BOOL';
const String paramsKeyAecModelPath = 'PARAMS_KEY_AEC_MODEL_PATH_STRING';

/// 录音机 & 输入音频
const String paramsKeyRecorderType = 'PARAMS_KEY_RECORDER_TYPE_STRING';
const String paramsKeyDialogRecorderPath = 'PARAMS_KEY_DIALOG_RECORDER_PATH_STRING';
const String paramsKeyEnableRecorderAudioCallback =
    'PARAMS_KEY_DIALOG_ENABLE_RECORDER_AUDIO_CALLBACK_BOOL';

/// 播放器 & 输出音频
const String paramsKeyEnablePlayer = 'PARAMS_KEY_DIALOG_ENABLE_PLAYER_BOOL';
const String paramsKeyEnablePlayerAudioCallback =
    'PARAMS_KEY_DIALOG_ENABLE_PLAYER_AUDIO_CALLBACK_BOOL';
const String paramsKeyEnableDecoderAudioCallback =
    'PARAMS_KEY_DIALOG_ENABLE_DECODER_AUDIO_CALLBACK_BOOL';
const String paramsKeyDialogPlayerPath = 'PARAMS_KEY_DIALOG_PLAYER_PATH_STRING';

/// 工作模式
const String paramsKeyDialogWorkMode = 'PARAMS_KEY_DIALOG_WORK_MODE_INT';

/// 自定义音频重采样
const String paramsKeyEnableResampler = 'PARAMS_KEY_ENABLE_RESAMPLER_BOOL';
const String paramsKeyCustomSampleRate = 'PARAMS_KEY_CUSTOM_SAMPLE_RATE_INT';
const String paramsKeyCustomChannel = 'PARAMS_KEY_CUSTOM_CHANNEL_INT';

// ============================================================
// 枚举值
// ============================================================

/// 录音类型
const String recorderTypeRecorder = 'RECORDER_TYPE_RECORDER';
const String recorderTypeStream = 'RECORDER_TYPE_STREAM';

/// 日志级别
const String logLevelTrace = 'LOG_LEVEL_TRACE';
const String logLevelDebug = 'LOG_LEVEL_DEBUG';
const String logLevelInfo = 'LOG_LEVEL_INFO';
const String logLevelWarn = 'LOG_LEVEL_WARN';
const String logLevelError = 'LOG_LEVEL_ERROR';

/// 工作模式
const int dialogWorkModeDefault = 0;
const int dialogWorkModeDelegateChatTtsText = 1;

// ============================================================
// 指令（Directive）定义
// ============================================================

/// 指令枚举
enum VoiceDirective {
  syncStopEngine, // 同步停止引擎
  startEngine, // 启动引擎
  sayHello, // 播报开场白
  chatTtsText, // 自定义 TTS 回复文本
  useClientTriggerTts, // 使用客户端指定的 TTS 回复
  useServerTriggerTts, // 使用服务自动生成的 TTS 回复
  chatTextQuery, // 发送文本 Query
  chatRagText, // 发送 RAG Query
  clientInterrupt, // 客户端打断
  updateConfig, // 更新 SP 配置
  pausePlayer, // 暂停播放
  resumePlayer, // 恢复播放
  pauseRecorder, // 暂停录音
  resumeRecorder, // 恢复录音
}

/// Directive 常数字符串映射
const Map<VoiceDirective, String> directiveStrings = {
  VoiceDirective.syncStopEngine: 'DIRECTIVE_SYNC_STOP_ENGINE',
  VoiceDirective.startEngine: 'DIRECTIVE_START_ENGINE',
  VoiceDirective.sayHello: 'DIRECTIVE_EVENT_SAY_HELLO',
  VoiceDirective.chatTtsText: 'DIRECTIVE_DIALOG_CHAT_TTS_TEXT',
  VoiceDirective.useClientTriggerTts: 'DIRECTIVE_DIALOG_USE_CLIENT_TRIGGER_TTS',
  VoiceDirective.useServerTriggerTts: 'DIRECTIVE_DIALOG_USE_SERVER_TRIGGER_TTS',
  VoiceDirective.chatTextQuery: 'DIRECTIVE_EVENT_CHAT_TEXT_QUERY',
  VoiceDirective.chatRagText: 'DIRECTIVE_EVENT_CHAT_RAG_TEXT',
  VoiceDirective.clientInterrupt: 'DIRECTIVE_EVENT_CLIENT_INTERRUPT',
  VoiceDirective.updateConfig: 'DIRECTIVE_EVENT_UPDATE_CONFIG',
  VoiceDirective.pausePlayer: 'DIRECTIVE_PAUSE_PLAYER',
  VoiceDirective.resumePlayer: 'DIRECTIVE_RESUME_PLAYER',
  VoiceDirective.pauseRecorder: 'DIRECTIVE_PAUSE_RECORDER',
  VoiceDirective.resumeRecorder: 'DIRECTIVE_RESUME_RECORDER',
};

// ============================================================
// 回调消息类型定义
// ============================================================

/// 引擎事件类型枚举
enum VoiceEngineEventType {
  engineStart, // 引擎启动成功
  engineStop, // 引擎关闭
  engineError, // 错误信息
  asrInfo, // ASR 识别开始
  asrResponse, // ASR 识别结果
  asrEnded, // ASR 识别结束
  chatResponse, // Chat 回复内容
  chatEnded, // Chat 回复结束
  playerAudio, // 播放器音频数据
  decoderAudio, // 解码器音频数据
  recorderAudio, // 录音机音频数据
}

/// Event 类型字符串映射（传给 Native 的 key）
const Map<VoiceEngineEventType, String> eventTypeStrings = {
  VoiceEngineEventType.engineStart: 'MESSAGE_TYPE_ENGINE_START',
  VoiceEngineEventType.engineStop: 'MESSAGE_TYPE_ENGINE_STOP',
  VoiceEngineEventType.engineError: 'MESSAGE_TYPE_ENGINE_ERROR',
  VoiceEngineEventType.asrInfo: 'MESSAGE_TYPE_DIALOG_ASR_INFO',
  VoiceEngineEventType.asrResponse: 'MESSAGE_TYPE_DIALOG_ASR_RESPONSE',
  VoiceEngineEventType.asrEnded: 'MESSAGE_TYPE_DIALOG_ASR_ENDED',
  VoiceEngineEventType.chatResponse: 'MESSAGE_TYPE_DIALOG_CHAT_RESPONSE',
  VoiceEngineEventType.chatEnded: 'MESSAGE_TYPE_DIALOG_CHAT_ENDED',
  VoiceEngineEventType.playerAudio: 'MESSAGE_TYPE_PLAYER_AUDIO_DATA',
  VoiceEngineEventType.decoderAudio: 'MESSAGE_TYPE_DECODER_AUDIO_DATA',
  VoiceEngineEventType.recorderAudio: 'MESSAGE_TYPE_DIALOG_RECORDER_AUDIO',
};

/// Native 方法名常量
const String methodPrepareEnvironment = 'prepareEnvironment';
const String methodCreateEngine = 'createEngine';
const String methodSetOptionString = 'setOptionString';
const String methodSetOptionBool = 'setOptionBool';
const String methodSetOptionInt = 'setOptionInt';
const String methodInitEngine = 'initEngine';
const String methodSendDirective = 'sendDirective';
const String methodFeedAudio = 'feedAudio';
const String methodDestroyEngine = 'destroyEngine';
