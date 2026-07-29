import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

import 'models/voice_engine_config.dart';
import 'models/voice_engine_defines.dart';
import 'models/voice_engine_event.dart';

/// 豆包语音端到端实时语音大模型 Flutter 插件
///
/// 基于 MethodChannel/EventChannel 封装 Android/iOS 原生 SDK，
/// 提供低延迟、双向流式语音交互能力。
///
/// 使用示例：
/// ```dart
/// final engine = DoubaoVoiceEngine.instance;
///
/// // 1. 准备环境
/// await engine.prepareEnvironment();
///
/// // 2. 创建引擎
/// await engine.createEngine();
///
/// // 3. 配置参数
/// await engine.configure(VoiceEngineConfig(
///   appId: 'YOUR_APP_ID',
///   appKey: 'YOUR_APP_KEY',
///   appToken: 'YOUR_TOKEN',
///   uid: 'user_123',
/// ));
///
/// // 4. 初始化
/// await engine.initEngine();
///
/// // 5. 监听事件
/// engine.eventStream.listen((event) {
///   switch (event.type) {
///     case VoiceEngineEventType.asrResponse:
///       print('用户说: ${event.text}');
///       break;
///     case VoiceEngineEventType.chatResponse:
///       print('AI 回复: ${event.text}');
///       break;
///     case VoiceEngineEventType.decoderAudio:
///       // 处理 TTS 音频数据
///       break;
///   }
/// });
///
/// // 6. 启动引擎
/// await engine.startEngine(botName: '豆包');
///
/// // 7. 发送文本
/// await engine.sendTextQuery('今天天气怎么样？');
///
/// // 8. 停止 & 销毁
/// await engine.stopEngine();
/// await engine.destroyEngine();
/// ```
class DoubaoVoiceEngine {
  DoubaoVoiceEngine._();

  static final DoubaoVoiceEngine _instance = DoubaoVoiceEngine._();
  static DoubaoVoiceEngine get instance => _instance;

  static const String _methodChannelName = 'doubao_voice_engine/method';
  static const String _eventChannelName = 'doubao_voice_engine/event';

  // Method names
  static const String methodPrepareEnvironment = 'prepareEnvironment';
  static const String methodCreateEngine = 'createEngine';
  static const String methodSetOptionString = 'setOptionString';
  static const String methodSetOptionBool = 'setOptionBool';
  static const String methodSetOptionInt = 'setOptionInt';
  static const String methodInitEngine = 'initEngine';
  static const String methodSendDirective = 'sendDirective';
  static const String methodFeedAudio = 'feedAudio';
  static const String methodDestroyEngine = 'destroyEngine';

  MethodChannel? _methodChannel;
  EventChannel? _eventChannel;
  StreamSubscription? _eventSubscription;

  final _eventController = StreamController<VoiceEngineEvent>.broadcast();

  bool _isInitialized = false;

  // ============================================================
  // 公开属性
  // ============================================================

  /// 引擎事件流
  Stream<VoiceEngineEvent> get eventStream => _eventController.stream;

  /// 是否已初始化
  bool get isInitialized => _isInitialized;

  // ============================================================
  // 平台通道初始化
  // ============================================================

  MethodChannel get _channel {
    _methodChannel ??= const MethodChannel(_methodChannelName);
    return _methodChannel!;
  }

  void _initEventChannel() {
    _eventChannel ??= const EventChannel(_eventChannelName);
    _eventSubscription?.cancel();
    _eventSubscription = _eventChannel!
        .receiveBroadcastStream()
        .listen(_onEventData, onError: _onEventError);
  }

  void _onEventData(dynamic data) {
    try {
      if (data is Map) {
        final event = VoiceEngineEvent.fromMap(
          Map<String, dynamic>.from(data),
        );
        _eventController.add(event);
      }
    } catch (e) {
      debugPrint('DoubaoVoiceEngine: error parsing event data: $e');
    }
  }

  void _onEventError(dynamic error) {
    debugPrint('DoubaoVoiceEngine: event error: $error');
  }

  // ============================================================
  // 1. 准备环境（App 生命周期内仅一次）
  // ============================================================

  /// 初始化环境依赖，创建引擎实例前调用。
  /// 整个 App 生命周期内**仅需执行一次**。
  Future<void> prepareEnvironment() async {
    final ok = await _channel.invokeMethod<bool>(methodPrepareEnvironment);
    if (ok != true) {
      throw PlatformException(
        code: 'PREPARE_FAILED',
        message: '环境准备失败。请检查：\n'
            '1. App 是否已完成火山引擎鉴权配置\n'
            '2. 网络权限是否已开启\n'
            '3. iOS: pod install 是否使用了 --repo-update\n'
            '4. Android: AndroidManifest.xml 是否声明了 INTERNET 权限',
      );
    }
  }

  // ============================================================
  // 2. 创建引擎实例
  // ============================================================

  /// 创建引擎实例。
  /// 调用前需先执行 [prepareEnvironment]。
  Future<void> createEngine() async {
    await _channel.invokeMethod(methodCreateEngine);
    _initEventChannel();
  }

  // ============================================================
  // 3. 参数配置
  // ============================================================

  /// 批量配置引擎参数。
  /// 与 [setOptionString]/[setOptionInt]/[setOptionBool] 二选一使用。
  Future<void> configure(VoiceEngineConfig config) async {
    final paramMap = config.toParamMap();
    debugPrint('DoubaoVoiceEngine: configure() — ${paramMap.length} params');
    // 脱敏打印关键鉴权参数
    final safeMap = Map<String, dynamic>.from(paramMap);
    safeMap['PARAMS_KEY_APP_KEY_STRING'] = '***';
    safeMap['PARAMS_KEY_APP_TOKEN_STRING'] = '***';
    debugPrint('DoubaoVoiceEngine: params = $safeMap');
    await _channel.invokeMethod('configure', paramMap);
  }

  /// 设置字符串参数
  Future<void> setOptionString(String key, String value) async {
    await _channel.invokeMethod(methodSetOptionString, {
      'key': key,
      'value': value,
    });
  }

  /// 设置布尔参数
  Future<void> setOptionBool(String key, bool value) async {
    await _channel.invokeMethod(methodSetOptionBool, {
      'key': key,
      'value': value,
    });
  }

  /// 设置整数参数
  Future<void> setOptionInt(String key, int value) async {
    await _channel.invokeMethod(methodSetOptionInt, {
      'key': key,
      'value': value,
    });
  }

  // ============================================================
  // 4. 初始化引擎
  // ============================================================

  /// 初始化引擎实例。
  /// 调用前需完成参数配置。
  Future<void> initEngine() async {
    debugPrint('DoubaoVoiceEngine: calling initEngine...');
    final result = await _channel.invokeMethod<int>(methodInitEngine);
    debugPrint('DoubaoVoiceEngine: initEngine returned $result');
    if (result != null && result != 0) {
      debugPrint('DoubaoVoiceEngine: INIT FAILED with code $result');
      final tips = _buildInitErrorTips(result);
      throw PlatformException(
        code: 'INIT_FAILED',
        message: '引擎初始化失败，错误码: $result\n$tips',
      );
    }
    _isInitialized = true;
  }

  /// 根据错误码生成排查建议
  String _buildInitErrorTips(int errorCode) {
    final tips = StringBuffer();
    tips.writeln('排查建议：');
    tips.writeln('1. 检查 configure() 是否正确传入了 appId / appKey / appToken');
    tips.writeln('2. 确认 resourceId 应为 "volc.speech.dialog"');
    tips.writeln('3. 确认 uid 不为空字符串');
    tips.writeln('4. 设置 logLevel 为 "LOG_LEVEL_TRACE" 以获取 SDK 详细日志');
    tips.writeln('5. 查看设备上的 speech_sdk.log 文件获取原始错误信息');
    tips.writeln('6. 参考 README 常见问题 → "initEngine 返回 -202 错误"');
    return tips.toString();
  }

  // ============================================================
  // 5. 指令操作
  // ============================================================

  /// 启动引擎，开始语音对话。
  ///
  /// [botName] 机器人名称，如 "豆包"。
  /// [config] 额外的 SP 配置项。
  Future<void> startEngine({
    String botName = '豆包',
    Map<String, dynamic>? config,
  }) async {
    final dialogConfig = <String, dynamic>{'bot_name': botName};
    if (config != null) dialogConfig.addAll(config);
    final data = '{"dialog":${_toJson(dialogConfig)}}';
    await _sendDirective(VoiceDirective.startEngine, data: data);
  }

  /// 播报开场白。
  /// 调用时机：引擎启动成功后。
  Future<void> sayHello(String content) async {
    final data = '{"content":${_escapeJson(content)}}';
    await _sendDirective(VoiceDirective.sayHello, data: data);
  }

  /// 发送文本 Query（对话文字输入）。
  Future<void> sendTextQuery(String content) async {
    final data = '{"content":${_escapeJson(content)}}';
    await _sendDirective(VoiceDirective.chatTextQuery, data: data);
  }

  /// 发送自定义 TTS 回复文本（流式）。
  ///
  /// [content] TTS 文本内容。
  /// [isFirst] 是否首包。
  /// [isLast] 是否尾包（结束）。设为 true 时 content 可为空。
  Future<void> sendChatTtsText(
    String content, {
    bool isFirst = false,
    bool isLast = false,
  }) async {
    final data =
        '{"start":$isFirst,"end":$isLast,"content":${_escapeJson(content)}}';
    await _sendDirective(VoiceDirective.chatTtsText, data: data);
  }

  /// 发送 RAG 查询。
  ///
  /// [documents] RAG 文档列表，每项包含 title 和 content。
  Future<void> sendRagText(List<Map<String, String>> documents) async {
    final ragList = documents.map((doc) {
      return '{\\"title\\":\\${doc['title']!}\\",\\"content\\":\\${doc['content']!}\\"}';
    }).join(',');
    final data = '{"external_rag":"[$ragList]"}';
    await _sendDirective(VoiceDirective.chatRagText, data: data);
  }

  /// 使用客户端指定的 TTS 回复。
  /// 仅在 delegate 工作模式下有效，每轮对话需二选一调用。
  Future<void> useClientTriggerTts() async {
    await _sendDirective(VoiceDirective.useClientTriggerTts);
  }

  /// 使用服务自动生成的 TTS 回复。
  /// 仅在 delegate 工作模式下有效，每轮对话需二选一调用。
  Future<void> useServerTriggerTts() async {
    await _sendDirective(VoiceDirective.useServerTriggerTts);
  }

  /// 客户端打断（中断当前播放）。
  Future<void> clientInterrupt() async {
    await _sendDirective(VoiceDirective.clientInterrupt, data: '{}');
  }

  /// 更新通话中 SP 配置。
  Future<void> updateConfig(Map<String, dynamic> spConfig) async {
    final data = '{"dialog":${_toJson(spConfig)}}';
    await _sendDirective(VoiceDirective.updateConfig, data: data);
  }

  /// 暂停播放
  Future<void> pausePlayer() async {
    await _sendDirective(VoiceDirective.pausePlayer);
  }

  /// 恢复播放
  Future<void> resumePlayer() async {
    await _sendDirective(VoiceDirective.resumePlayer);
  }

  /// 暂停录音（需在 startEngine 时设置 dialog.exra.input_mode = "keep_alive"）
  Future<void> pauseRecorder() async {
    await _sendDirective(VoiceDirective.pauseRecorder);
  }

  /// 恢复录音
  Future<void> resumeRecorder() async {
    await _sendDirective(VoiceDirective.resumeRecorder);
  }

  /// 停止引擎（同步等待）。
  ///
  /// ⚠️ 不可在事件回调线程中调用！
  Future<void> stopEngine() async {
    await _channel.invokeMethod('stopEngine');
  }

  /// 发送自定义指令（高级用法）。
  ///
  /// [directive] 指令类型。
  /// [data] 可选 JSON 参数。
  Future<void> sendDirective(VoiceDirective directive, {String? data}) async {
    await _sendDirective(directive, data: data);
  }

  Future<void> _sendDirective(VoiceDirective directive, {String? data}) async {
    final directiveStr = directiveStrings[directive]!;
    await _channel.invokeMethod(methodSendDirective, {
      'directive': directiveStr,
      'data': data ?? '',
    });
  }

  // ============================================================
  // 6. 自定义音频输入
  // ============================================================

  /// 传入原始 PCM 音频数据（STREAM 模式下使用）。
  ///
  /// 音频格式要求：
  /// - 位深：PCM 16bit
  /// - 采样率：16kHz（如不是可开启内部重采样）
  /// - 通道数：1（单声道）
  Future<void> feedAudio(Uint8List buffer) async {
    await _channel.invokeMethod(methodFeedAudio, buffer);
  }

  // ============================================================
  // 7. 销毁引擎
  // ============================================================

  /// 销毁引擎实例，释放资源。
  ///
  /// ⚠️ 不可在事件回调线程中调用！
  Future<void> destroyEngine() async {
    await _channel.invokeMethod(methodDestroyEngine);
    _isInitialized = false;
  }

  /// 释放所有资源。
  Future<void> dispose() async {
    await _eventSubscription?.cancel();
    _eventSubscription = null;
    await _eventController.close();
    _methodChannel = null;
    _eventChannel = null;
    _isInitialized = false;
  }

  // ============================================================
  // 辅助
  // ============================================================

  static String _escapeJson(String s) {
    return '"${s.replaceAll('\\', '\\\\').replaceAll('"', '\\"').replaceAll('\n', '\\n')}"';
  }

  static String _toJson(Map<String, dynamic> map) {
    final buffer = StringBuffer('{');
    bool first = true;
    for (final entry in map.entries) {
      if (!first) buffer.write(',');
      first = false;
      buffer.write('"${entry.key}":${_valueToJson(entry.value)}');
    }
    buffer.write('}');
    return buffer.toString();
  }

  static String _valueToJson(dynamic value) {
    if (value is String) return _escapeJson(value);
    if (value is bool) return value.toString();
    if (value is num) return value.toString();
    if (value is Map) return _toJson(value.cast<String, dynamic>());
    return 'null';
  }
}
