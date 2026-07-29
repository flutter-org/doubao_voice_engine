# 豆包语音端到端实时语音大模型 Flutter 插件

基于[豆包端到端实时语音大模型](https://www.volcengine.com/docs/6561)，封装 Android / iOS 原生 SDK，
提供低延迟、双向流式语音交互能力。可用于构建语音助手、智能客服、语音对话等场景。

## 支持的平台

| 平台 | 最低版本 | SDK 版本 |
|------|----------|----------|
| Android | API 19 (Android 4.4) | speechengine_tob 0.0.14.7 |
| iOS | iOS 12.0 | SpeechEngineToB 0.0.14.7 |

## 安装

```yaml
# pubspec.yaml
dependencies:
  doubao_voice_engine:
    path: ../doubao_voice_engine  # 本地路径
```

### iOS 额外配置

#### 1. 配置 Podfile

`ios/Podfile` **必须**在顶部声明两个 CocoaPods 源，**火山引擎源必须在 CocoaPods 官方源之后**：

```ruby
# 取消这两行顶部的注释，并确保都存在
source 'https://github.com/CocoaPods/Specs.git'
source 'https://github.com/volcengine/volcengine-specs.git'

platform :ios, '12.0'

target 'Runner' do
  use_frameworks!
  use_modular_headers!

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
  end
end
```

> **重要**：Podfile 中 **必须同时包含两个 source**，且 volcengine-specs 源不可或缺。
> `SocketRocket`、`SpeechEngineToB` 等依赖均由火山引擎源提供。

#### 2. 执行 pod install

首次安装或依赖版本更新时，**务必带 `--repo-update`** 参数以刷新本地 CocoaPods 索引：

```bash
cd ios && pod install --repo-update
```

如果 `--repo-update` 执行失败，先手动更新 repo 再重试：

```bash
pod repo update
pod install
```

#### 3. 配置 Info.plist

在 `ios/Runner/Info.plist` 中添加麦克风权限说明：

```xml
<key>NSMicrophoneUsageDescription</key>
<string>需要麦克风权限以进行语音对话</string>
```

### Android 额外配置

SDK 已通过 `AndroidManifest.xml` 声明所需���限，无需额外配置。

## 快速开始

```dart
import 'package:doubao_voice_engine/doubao_voice_engine.dart';

final engine = DoubaoVoiceEngine.instance;

// 1. 准备环境（App 启动时调用一次）
await engine.prepareEnvironment();

// 2. 创建引擎
await engine.createEngine();

// 3. 配置参数
await engine.configure(VoiceEngineConfig(
  appId: 'YOUR_APP_ID',
  appKey: 'YOUR_APP_KEY',
  appToken: 'YOUR_ACCESS_TOKEN',
  uid: 'user_123456',
));

// 4. 初始化引擎
await engine.initEngine();

// 5. 监听事件流
engine.eventStream.listen((event) {
  switch (event.type) {
    case VoiceEngineEventType.engineStart:
      print('引擎已启动');
      break;
    case VoiceEngineEventType.asrInfo:
      print('用户开始说话...');
      break;
    case VoiceEngineEventType.asrResponse:
      print('识别结果: ${event.text}');
      break;
    case VoiceEngineEventType.asrEnded:
      print('用户说话结束');
      break;
    case VoiceEngineEventType.chatResponse:
      print('AI 回复: ${event.text}');
      break;
    case VoiceEngineEventType.chatEnded:
      print('AI 回复结束');
      break;
    case VoiceEngineEventType.decoderAudio:
      // 处理 TTS 音频数据 (PCM 16bit 16kHz mono)
      final audioBytes = event.audio;
      break;
    case VoiceEngineEventType.engineError:
      print('错误: ${event.text}');
      break;
  }
});

// 6. 启动引擎
await engine.startEngine(botName: '豆包');

// 7. 发送文本对话
await engine.sendTextQuery('今天天气怎么样？');

// —— 语音对话是自动的，SDK 会通过麦克风拾音并通过事件流返回结果 ——

// 8. 停止和清理
await engine.stopEngine();
await engine.destroyEngine();
```

## API 参考

### DoubaoVoiceEngine

| 方法 | 说明 |
|------|------|
| `prepareEnvironment()` | 初始化环境依赖（App 生命周期内仅需一次） |
| `createEngine()` | 创建引擎实例 |
| `configure(config)` | 批量配置所有参数 |
| `initEngine()` | 初始化引擎，成功后开始接收事件 |
| `startEngine({botName, config})` | 启动语音对话引擎 |
| `stopEngine()` | 同步停止引擎 |
| `destroyEngine()` | 销毁引擎并释放资源 |
| `dispose()` | 释放所有资源（含 Channel） |

### 对话操作

| 方法 | 说明 |
|------|------|
| `sayHello(content)` | 播报开场白 |
| `sendTextQuery(content)` | 发送文本 Query |
| `sendChatTtsText(content, {isFirst, isLast})` | 自定义 TTS 回复（流式） |
| `sendRagText(documents)` | 发送 RAG 文档查询 |
| `useClientTriggerTts()` | 本轮使用客户端指定 TTS |
| `useServerTriggerTts()` | 本轮使用服务自动生成 TTS |

### 控制操作

| 方法 | 说明 |
|------|------|
| `clientInterrupt()` | 客户端打断当前播放 |
| `updateConfig(spConfig)` | 更新通话中配置 |
| `pausePlayer()` / `resumePlayer()` | 暂停/恢复播放 |
| `pauseRecorder()` / `resumeRecorder()` | 暂停/恢复录音 |
| `feedAudio(buffer)` | 输入自定义 PCM 音频 |

### 高级指令（VoiceDirective）

| 方法 | 说明 |
|------|------|
| `sendDirective(directive, {data})` | 发送任意 VoiceDirective 指令，用于扩展或未封装的场景 |

`VoiceDirective` 枚举值：

| 枚举 | 对应 Native 指令 |
|------|-----------------|
| `syncStopEngine` | DIRECTIVE_SYNC_STOP_ENGINE |
| `startEngine` | DIRECTIVE_START_ENGINE |
| `sayHello` | DIRECTIVE_EVENT_SAY_HELLO |
| `chatTtsText` | DIRECTIVE_DIALOG_CHAT_TTS_TEXT |
| `useClientTriggerTts` | DIRECTIVE_DIALOG_USE_CLIENT_TRIGGER_TTS |
| `useServerTriggerTts` | DIRECTIVE_DIALOG_USE_SERVER_TRIGGER_TTS |
| `chatTextQuery` | DIRECTIVE_EVENT_CHAT_TEXT_QUERY |
| `chatRagText` | DIRECTIVE_EVENT_CHAT_RAG_TEXT |
| `clientInterrupt` | DIRECTIVE_EVENT_CLIENT_INTERRUPT |
| `updateConfig` | DIRECTIVE_EVENT_UPDATE_CONFIG |
| `pausePlayer` / `resumePlayer` | DIRECTIVE_PAUSE_PLAYER / DIRECTIVE_RESUME_PLAYER |
| `pauseRecorder` / `resumeRecorder` | DIRECTIVE_PAUSE_RECORDER / DIRECTIVE_RESUME_RECORDER |

### 参数配置

| 方法 | 说明 |
|------|------|
| `setOptionString(key, value)` | 设置字符串参数 |
| `setOptionBool(key, value)` | 设置布尔参数 |
| `setOptionInt(key, value)` | 设置整数参数 |

### 事件类型（VoiceEngineEventType）

| 事件 | 说明 | 数据类型 |
|------|------|----------|
| `engineStart` | 引擎启动成功 | text (JSON) |
| `engineStop` | 引擎关闭 | text (JSON) |
| `engineError` | 错误信息 | text |
| `asrInfo` | 用户开始说话 | text |
| `asrResponse` | ASR 识别结果 | text (JSON) |
| `asrEnded` | 用户说话结束 | text |
| `chatResponse` | Chat 对话回复 | text (JSON) |
| `chatEnded` | Chat 回复结束 | text |
| `playerAudio` | 播放器音频数据 | audio (PCM) |
| `decoderAudio` | 解码器音频数据 | audio (PCM) |
| `recorderAudio` | 录音机音频数据 | audio (PCM) |

## 高级用法

### 自定义 TTS 工作模式

```dart
// 配置为 delegate 模式
await engine.configure(VoiceEngineConfig(
  appId: '...',
  // ...
  dialogWorkMode: dialogWorkModeDelegateChatTtsText,
));

// 每轮对话中二选一：
// 方式1：使用客户端指定文本
await engine.useClientTriggerTts();
// 或发送自定义 TTS 文本
await engine.sendChatTtsText('这是自定义回复', isFirst: true);
await engine.sendChatTtsText('', isLast: true);

// 方式2：使用服务自动生成
await engine.useServerTriggerTts();
```

### 自定义音频输入（STREAM 模式）

```dart
await engine.configure(VoiceEngineConfig(
  appId: '...',
  recorderType: recorderTypeStream, // 使用自定义音频输入
  enablePlayer: false,              // 关闭内置播放器
  enableDecoderAudioCallback: true, // 通过回调获取 TTS 音频
));

// 输入 PCM 16bit 16kHz 单声道音频
final audioBuffer = Uint8List.fromList(pcmData);
await engine.feedAudio(audioBuffer);
```

### 开启 AEC 回声消除

```dart
await engine.configure(VoiceEngineConfig(
  appId: '...',
  enableAec: true,
  aecModelPath: '/path/to/aec.model', // AEC 模型文件路径
));
```

## 音频格式说明

| 参数 | 值 |
|------|-----|
| 编码 | PCM |
| 位深 | 16 bit |
| 采样率 | 16 kHz |
| 通道 | 1（单声道） |

如输入音频格式不同，可开启 SDK 内部重采��：

```dart
await engine.setOptionBool(paramsKeyEnableResampler, true);
await engine.setOptionInt(paramsKeyCustomSampleRate, 44100);
await engine.setOptionInt(paramsKeyCustomChannel, 2);
```

## 注意事项

1. `stopEngine()` 和 `destroyEngine()` **不可在事件回调线程中调用**，否则会导致死锁。
2. `prepareEnvironment()` 在整个 App 生命周期内仅需调用一次。
3. Android 录音权限需要在运行时申请；插件仅声明权限，应用层需自行处理权限请求。
4. iOS 需在 `Info.plist` 中配置 `NSMicrophoneUsageDescription`。

## 常见问题

### pod install 报错：Unable to find a specification for SocketRocket / SpeechEngineToB

```
[!] Unable to find a specification for `SocketRocket (= 0.6.1)` depended upon by `doubao_voice_engine`
```

这个错误意味着 CocoaPods 找不到火山引擎源中的依赖。按以下步骤逐一排查：

**1. 检查 Podfile 是否包含 volcengine-specs 源**

确保 `ios/Podfile` **顶部**有以下两行（缺一不可）：

```ruby
source 'https://github.com/CocoaPods/Specs.git'
source 'https://github.com/volcengine/volcengine-specs.git'
```

**2. 使用 `--repo-update` 重新安装**

```bash
cd ios && pod install --repo-update
```

**3. 如果仍然失败，手动添加 volcengine 源并更新**

```bash
pod repo add volcengine-specs https://github.com/volcengine/volcengine-specs.git
pod repo update
pod install
```

**4. 确认网络可达**

火山引擎 CocoaPods 源托管在 GitHub，确保网络可以访问 `github.com/volcengine`。如在内网环境，可能需要配置代理：

```bash
git config --global http.proxy http://your-proxy:port
```

### Android 编译报错：找不到 speechengine_tob

需要在 `android/build.gradle`（项目级）中添加火山引擎 Maven 仓库：

```groovy
allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url "https://artifact.bytedance.com/repository/Volcengine/" }
    }
}
```

### iOS 编译警告："does not support Swift Package Manager"

```
The following plugins do not support Swift Package Manager for ios:
  - doubao_voice_engine
This will become an error in a future version of Flutter.
```

这是因本插件使用 CocoaPods 集成原生 SDK，尚未适配 Swift Package Manager。目前仅是一个警告，不影响编译和运行。未来版本的 Flutter 可能将其升级为错误，届时需要更新插件以支持 SPM。

### `initEngine()` 返回错误码 -202

```
PlatformException (INIT_FAILED, 引擎初始化失败，错误码: -202, ...)
```

错误码 -202 未在官方公开文档中列出，通常表示**引擎名称不匹配**或**必需参数缺失/类型错误**。

**排查步骤：**

**1. 确认 Engine Name 为大写 `DIALOG_ENGINE`**

> ⚠️ 这是最常见的 -202 原因。SDK 常量 `DIALOG_ENGINE` 的字符串值为 `"DIALOG_ENGINE"`（大写），
> 而非 `"dialog_engine"`（小写）。本插件 v0.0.1 曾误用小写，已修复。

插件内部已修复此问题（`voice_engine_defines.dart` 中 `dialogEngine = 'DIALOG_ENGINE'`）。
如果你 fork 了旧代码，请确认此常量值为大写。

**2. 启用 SDK TRACE 日志**

SDK 会在本地生成 `speech_sdk.log`，其中的错误信息比返回码更具体。
默认日志级别已设为 `LOG_LEVEL_TRACE`，如需设置 `debugPath`：

```dart
final engine = DoubaoVoiceEngine.instance;
await engine.prepareEnvironment();
await engine.createEngine();
await engine.configure(VoiceEngineConfig(
  appId: 'YOUR_APP_ID',
  appKey: 'YOUR_APP_KEY',
  appToken: 'YOUR_ACCESS_TOKEN',
  uid: 'test_user_001',
  debugPath: '/path/to/writable/dir',  // SDK 会在该目录下生成 speech_sdk.log
  // logLevel 默认已为 LOG_LEVEL_TRACE
));
await engine.initEngine();
```

运行后检查 `speech_sdk.log`，搜索 `error` 或 `fail` 关键字获取更详细的错误信息。

**3. 检查必需参数完整性**

下列参数在 `initEngine()` 之前**必须全部正确设置**：

| 参数 Key | 说明 | 示例值 |
|---------|------|--------|
| `PARAMS_KEY_ENGINE_NAME_STRING` | 引擎类型 | `DIALOG_ENGINE`（大写） |
| `PARAMS_KEY_APP_ID_STRING` | 火山引擎 AppID | 从控制台获取 |
| `PARAMS_KEY_APP_KEY_STRING` | 火山引擎 AppKey | 从控制台获取 |
| `PARAMS_KEY_APP_TOKEN_STRING` | Access Token | 从控制台获取 |
| `PARAMS_KEY_RESOURCE_ID_STRING` | 对话服务资源 ID | `volc.speech.dialog` |
| `PARAMS_KEY_UID_STRING` | 用户标识 | 任意非空字符串 |
| `PARAMS_KEY_DIALOG_ADDRESS_STRING` | 服务地址 | `wss://openspeech.bytedance.com` |
| `PARAMS_KEY_DIALOG_URI_STRING` | 服务 URI | `/api/v3/realtime/dialogue` |

**3. 确认 Token 格式**

**4. 确认 Token 格式**

不同服务的 Token 格式要求不同。确认你的 Token 是否需要 `Bearer;` 前缀：

- 端到端对话 SDK：**不需要** `Bearer;` 前缀，直接传入原始 Token
- 在线 TTS/ASR SDK：需要 `Bearer;{TOKEN}` 格式

**5. 确认调用顺序**

```dart
// ✅ 正确顺序
await engine.prepareEnvironment();  // 必须最先调用
await engine.createEngine();         // 第二步
await engine.configure(config);      // 第三步：设置所有必需参数
await engine.initEngine();           // 第四步：初始化

// ❌ 错误：未调用 configure
await engine.prepareEnvironment();
await engine.createEngine();
await engine.initEngine();  // 报错！没有任何参数被设置
```

**6. 验证参数值来源**

确保 `appId`、`appKey`、`appToken` 是从火山引擎控制台复制的**有效凭证**，不是示例占位符。已过期或被禁用的 Token 也会导致初始化失败。

**7. 查看调试日志**

运行时控制台会输出 `[DoubaoVoice]` 标签的日志（iOS）或 `DoubaoVoice` 标签的日志（Android），展示每个参数的实际类型和值。检查这些日志确认参数是否正确传入。

### iOS SDK API 兼容性

本插件内部已适配豆包语音 iOS SDK 最新 API 命名（`send`、`destroy`、`onMessage(with:andData:)` 等），你只需使用 Flutter 层的 `DoubaoVoiceEngine` 公开 API，无需关心 Native SDK 版本差异。

如需查看或修改 Native 层实现，参见 `ios/Classes/DoubaoVoiceEnginePlugin.swift`。

## License

MIT
