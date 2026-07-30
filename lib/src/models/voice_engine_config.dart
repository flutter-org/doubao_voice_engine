import 'voice_engine_defines.dart';

/// 引擎配置数据模型
class VoiceEngineConfig {
  // ---- 必需配置 ----
  final String appId;
  final String appKey;
  final String appToken;
  final String resourceId;
  final String uid;
  final String dialogAddress;
  final String dialogUri;

  // ---- 可选配置 ----
  final String? debugPath;
  final String logLevel;

  // AEC
  final bool enableAec;
  final String? aecModelPath;

  // 录音机
  final String recorderType;
  final String? recorderPath;
  final bool enableRecorderAudioCallback;

  // 播放器
  final bool enablePlayer;
  final bool enablePlayerAudioCallback;
  final bool enableDecoderAudioCallback;
  final String? playerPath;

  // 工作模式
  final int dialogWorkMode;

  // 自定义重采样
  final bool enableResampler;
  final int customSampleRate;
  final int customChannel;

  const VoiceEngineConfig({
    required this.appId,
    required this.appKey,
    required this.appToken,
    this.resourceId = 'volc.speech.dialog',
    required this.uid,
    this.dialogAddress = 'wss://openspeech.bytedance.com',
    this.dialogUri = '/api/v3/realtime/dialogue',
    this.debugPath,
    this.logLevel = logLevelTrace,
    this.enableAec = false,
    this.aecModelPath,
    this.recorderType = recorderTypeRecorder,
    this.recorderPath,
    this.enableRecorderAudioCallback = false,
    this.enablePlayer = true,
    this.enablePlayerAudioCallback = false,
    this.enableDecoderAudioCallback = false,
    this.playerPath,
    this.dialogWorkMode = dialogWorkModeDefault,
    this.enableResampler = false,
    this.customSampleRate = 16000,
    this.customChannel = 1,
  });

}
