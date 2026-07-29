# 豆包语音端到端 Flutter 插件 — 开发完成

## 做了什么

参考豆包语音端到端实时语音大模型 Android/iOS SDK 接口文档，封装了一个完整的 Flutter 插件 `doubao_voice_engine`。

## 关键设计决策

1. **通信架构**：MethodChannel（Dart→Native 指令��+ EventChannel（Native→Dart 事件流），符合 Flutter 插件最佳实践
2. **单例模式**：`DoubaoVoiceEngine.instance` 管理全生命周期，与原生 SDK 的全局引擎实例一致
3. **事件模型**：11 种事件类型（Engine 状态、ASR 识别、Chat 回复、Audio 数据），按类型区分 text/audio 数据
4. **指令映射**：Dart 层用 enum `VoiceDirective`，Native 层分别映射到 Android 的 `SpeechEngineDefines.DIRECTIVE_*` 和 iOS 的 `SEDirective*`
5. **线程安全**：`stopEngine()` 和 `destroyEngine()` 在 Native 层使用独立线程执行，避免回调线程死锁

## 文件清单

| 文件 | 说明 |
|------|------|
| `lib/doubao_voice_engine.dart` | 插件入口，导出所有公开 API |
| `lib/src/doubao_voice_engine_impl.dart` | 核心引擎类，MethodChannel 封装 |
| `lib/src/models/voice_engine_config.dart` | 配置模型，含完整参数列表 |
| `lib/src/models/voice_engine_defines.dart` | 参数 key、Directive/Event 类型定义 |
| `lib/src/models/voice_engine_event.dart` | 事件数据模型 |
| `android/.../DoubaoVoiceEnginePlugin.kt` | Android 平台实现（Kotlin） |
| `ios/.../DoubaoVoiceEnginePlugin.swift` | iOS 平台实现（Swift） |
| `pubspec.yaml` | 插件元数据 & 依赖声明 |
| `README.md` | 完整使用文档 |

## 后续事项

- 如需运行示例 App，需在 `example/` 目录下创建 Flutter 项目并引入此插件
- AEC 模型文件 (`aec.model`) 如需使用，需从火山引擎获取并放入 assets
- Android 录音权限需在应用层调用 `permission_handler` 等库进行运行时申请
