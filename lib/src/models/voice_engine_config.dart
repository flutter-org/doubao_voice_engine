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
    this.logLevel = logLevelWarn,
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

  /// 生成所有配置参数的 Map
  Map<String, dynamic> toParamMap() {
    final params = <String, dynamic>{};

    void setString(String key, String value) => params[key] = value;
    void setBool(String key, bool value) => params[key] = value;
    void setInt(String key, int value) => params[key] = value;

    // 引擎基础
    setString(paramsKeyEngineName, dialogEngine);
    setString(paramsKeyLogLevel, logLevel);
    if (debugPath != null) setString(paramsKeyDebugPath, debugPath!);

    // 鉴权
    setString(paramsKeyAppId, appId);
    setString(paramsKeyAppKey, appKey);
    setString(paramsKeyAppToken, appToken);
    setString(paramsKeyResourceId, resourceId);
    setString(paramsKeyUid, uid);
    setString(paramsKeyDialogAddress, dialogAddress);
    setString(paramsKeyDialogUri, dialogUri);

    // AEC
    setBool(paramsKeyEnableAec, enableAec);
    if (enableAec && aecModelPath != null) {
      setString(paramsKeyAecModelPath, aecModelPath!);
    }

    // 录音机
    setString(paramsKeyRecorderType, recorderType);
    if (recorderPath != null) {
      setString(paramsKeyDialogRecorderPath, recorderPath!);
    }
    setBool(paramsKeyEnableRecorderAudioCallback, enableRecorderAudioCallback);

    // 播放器
    setBool(paramsKeyEnablePlayer, enablePlayer);
    setBool(paramsKeyEnablePlayerAudioCallback, enablePlayerAudioCallback);
    setBool(paramsKeyEnableDecoderAudioCallback, enableDecoderAudioCallback);
    if (playerPath != null) {
      setString(paramsKeyDialogPlayerPath, playerPath!);
    }

    // 工作模式
    setInt(paramsKeyDialogWorkMode, dialogWorkMode);

    // 重采样
    setBool(paramsKeyEnableResampler, enableResampler);
    setInt(paramsKeyCustomSampleRate, customSampleRate);
    setInt(paramsKeyCustomChannel, customChannel);

    return params;
  }
}
