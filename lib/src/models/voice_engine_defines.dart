/// 引擎名称（SDK 真实值 = "dialog"）
const String dialogEngine = 'dialog';

// ============================================================
// 参数 Key 定义
// ⚠️ 注意：这些是 SDK 常量的「值」（如 "appid"），而非常量的「标识符名」（如 "PARAMS_KEY_APP_ID_STRING"）。
// 之前误将标识符名传给 SDK，所有参数被静默丢弃，导致 initEngine() 返回 -202。
// 取自 SDK 二进制文件。
// ============================================================

/// 引擎基础配置
const String paramsKeyEngineName = 'engine_name';
const String paramsKeyDebugPath = 'debug_path';
const String paramsKeyLogLevel = 'log_level';

/// 鉴权配置
const String paramsKeyAppId = 'appid';
const String paramsKeyAppKey = 'appkey';
const String paramsKeyAppToken = 'token';
const String paramsKeyResourceId = 'resource_id';
const String paramsKeyUid = 'uid';
const String paramsKeyDialogAddress = 'dialog_address';
const String paramsKeyDialogUri = 'dialog_uri';

/// AEC 回声消除
const String paramsKeyEnableAec = 'enable_aec';
const String paramsKeyAecModelPath = 'aec_model_path';

/// 录音机 & 输入音频
const String paramsKeyRecorderType = 'recorder_data_source_type';
const String paramsKeyDialogRecorderPath = 'dialog_recorder_path';
const String paramsKeyEnableRecorderAudioCallback =
    'dialog_enable_recorder_audio_callback';

/// 播放器 & 输出音频
const String paramsKeyEnablePlayer = 'dialog_enable_player';
const String paramsKeyEnablePlayerAudioCallback =
    'dialog_enable_player_audio_callback';
const String paramsKeyEnableDecoderAudioCallback =
    'dialog_enable_decoder_audio_callback';
const String paramsKeyDialogPlayerPath = 'dialog_player_path';

/// 工作模式
const String paramsKeyDialogWorkMode = 'dialog_work_mode';

/// 自定义音频重采样
const String paramsKeyEnableResampler = 'enable_resampler';
const String paramsKeyCustomSampleRate = 'custom_sample_rate';
const String paramsKeyCustomChannel = 'custom_channel';

// ============================================================
// 枚举值（SDK 真实取值）
// ============================================================

/// 录音类型（SDK 真实值）
const String recorderTypeRecorder = 'Recorder';
const String recorderTypeStream = 'Stream';

/// 日志级别（SDK 真实值）
const String logLevelTrace = 'TRACE';
const String logLevelDebug = 'DEBUG';
const String logLevelInfo = 'INFO';
const String logLevelWarn = 'WARN';
const String logLevelError = 'ERROR';

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

/// Native 方法名常量（Pigeon 自动管理，此处保留仅向后兼容）
const String methodPrepareEnvironment = 'prepareEnvironment';
const String methodCreateEngine = 'createEngine';
const String methodSetOptionString = 'setOptionString';
const String methodSetOptionBool = 'setOptionBool';
const String methodSetOptionInt = 'setOptionInt';
const String methodInitEngine = 'initEngine';
const String methodSendDirective = 'sendDirective';
const String methodFeedAudio = 'feedAudio';
const String methodDestroyEngine = 'destroyEngine';
