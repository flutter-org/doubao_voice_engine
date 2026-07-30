import 'package:pigeon/pigeon.dart';

// ============================================================
// Pigeon 配置 — 生成 Dart / Kotlin / Swift 三端类型安全代码
// ============================================================
@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/src/messages.g.dart',
  kotlinOut:
      'android/src/main/kotlin/com/volcengine/doubao_voice_engine/Messages.g.kt',
  kotlinOptions: KotlinOptions(package: 'com.volcengine.doubao_voice_engine'),
  swiftOut: 'ios/Classes/Messages.g.swift',
  dartPackageName: 'doubao_voice_engine',
))

// ============================================================
// 数据模型
// ============================================================

/// 引擎配置消息（替代之前的 Map<String, dynamic>）
class EngineConfigMessage {
  EngineConfigMessage({
    required this.appId,
    required this.appKey,
    required this.appToken,
    required this.resourceId,
    required this.uid,
    required this.dialogAddress,
    required this.dialogUri,
    this.debugPath,
    required this.logLevel,
    required this.enableAec,
    this.aecModelPath,
    required this.recorderType,
    this.recorderPath,
    required this.enableRecorderAudioCallback,
    required this.enablePlayer,
    required this.enablePlayerAudioCallback,
    required this.enableDecoderAudioCallback,
    this.playerPath,
    this.dialogWorkMode,
    required this.enableResampler,
    this.customSampleRate,
    this.customChannel,
  });

  /// 鉴权 — 必需
  final String appId;
  final String appKey;
  final String appToken;
  final String resourceId;
  final String uid;
  final String dialogAddress;
  final String dialogUri;

  /// 引擎基础
  final String? debugPath;
  final String logLevel;

  /// AEC 回声消除
  final bool enableAec;
  final String? aecModelPath;

  /// 录音机
  final String recorderType;
  final String? recorderPath;
  final bool enableRecorderAudioCallback;

  /// 播放器
  final bool enablePlayer;
  final bool enablePlayerAudioCallback;
  final bool enableDecoderAudioCallback;
  final String? playerPath;

  /// 工作模式（null = 不设置，使用 SDK 默认值）
  final int? dialogWorkMode;

  /// 重采样
  final bool enableResampler;
  final int? customSampleRate;
  final int? customChannel;
}

/// 指令请求
class DirectiveRequest {
  DirectiveRequest({
    required this.directive,
    this.data,
  });

  /// 指令名称，如 "DIRECTIVE_START_ENGINE"
  final String directive;

  /// 可选 JSON 参数
  final String? data;
}

/// 引擎事件消息（Native -> Dart）
class EngineEventMessage {
  EngineEventMessage({
    required this.type,
    this.text,
    this.audio,
  });

  /// 事件类型，如 "MESSAGE_TYPE_DIALOG_ASR_RESPONSE"
  final String type;

  /// 文本数据
  final String? text;

  /// 二进制音频数据
  final Uint8List? audio;
}

// ============================================================
// HostApi — Dart 调用 Native
// ============================================================
@HostApi()
abstract class DoubaoVoiceHostApi {
  /// 准备环境（App 生命周期内仅一次）
  bool prepareEnvironment();

  /// 创建引擎实例
  void createEngine();

  /// 批量配置引擎参数
  void configure(EngineConfigMessage config);

  /// 设置字符串参数
  void setOptionString(String key, String value);

  /// 设置布尔参数
  void setOptionBool(String key, bool value);

  /// 设置整数参数
  void setOptionInt(String key, int value);

  /// 初始化引擎，返回错误码（0 = 成功）
  int initEngine();

  /// 发送指令
  void sendDirective(DirectiveRequest request);

  /// 传入 PCM 音频数据，返回错误码
  int feedAudio(Uint8List buffer);

  /// 停止引擎（异步执行，避免回调线程死锁）
  @async
  void stopEngine();

  /// 销毁引擎（异步执行）
  @async
  void destroyEngine();
}

// ============================================================
// FlutterApi — Native 调用 Dart（替代 EventChannel）
// ============================================================
@FlutterApi()
abstract class DoubaoVoiceFlutterApi {
  /// 引擎事件回调
  void onEngineEvent(EngineEventMessage event);
}
