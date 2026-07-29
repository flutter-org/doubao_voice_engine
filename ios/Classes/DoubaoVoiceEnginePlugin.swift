import Flutter
import UIKit
import SpeechEngineToB

public class DoubaoVoiceEnginePlugin: NSObject, FlutterPlugin {

    private var methodChannel: FlutterMethodChannel?
    private var eventChannel: FlutterEventChannel?
    private var eventSink: FlutterEventSink?
    private var speechEngine: SpeechEngine?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = DoubaoVoiceEnginePlugin()

        let methodChannel = FlutterMethodChannel(
            name: "doubao_voice_engine/method",
            binaryMessenger: registrar.messenger()
        )
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        instance.methodChannel = methodChannel

        let eventChannel = FlutterEventChannel(
            name: "doubao_voice_engine/event",
            binaryMessenger: registrar.messenger()
        )
        eventChannel.setStreamHandler(instance)
        instance.eventChannel = eventChannel
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        do {
            switch call.method {
            case "prepareEnvironment":
                handlePrepareEnvironment(result: result)
            case "createEngine":
                handleCreateEngine(result: result)
            case "configure":
                handleConfigure(call: call, result: result)
            case "setOptionString":
                handleSetOptionString(call: call, result: result)
            case "setOptionBool":
                handleSetOptionBool(call: call, result: result)
            case "setOptionInt":
                handleSetOptionInt(call: call, result: result)
            case "initEngine":
                handleInitEngine(result: result)
            case "sendDirective":
                handleSendDirective(call: call, result: result)
            case "feedAudio":
                handleFeedAudio(call: call, result: result)
            case "stopEngine":
                handleStopEngine(result: result)
            case "destroyEngine":
                handleDestroyEngine(result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        } catch let error {
            result(FlutterError(code: "ENGINE_ERROR", message: error.localizedDescription, details: nil))
        }
    }

    // ============================================================
    // 1. prepareEnvironment
    // ============================================================
    private func handlePrepareEnvironment(result: @escaping FlutterResult) {
        let ok = SpeechEngine.prepareEnvironment()
        result(ok)
    }

    // ============================================================
    // 2. createEngine
    // ============================================================
    private func handleCreateEngine(result: @escaping FlutterResult) {
        let engine = SpeechEngine()
        engine.createEngine(with: self)
        speechEngine = engine
        result(nil)
    }

    // ============================================================
    // 3. configure — 批量配置
    // ============================================================
    private func handleConfigure(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let engine = requireEngine(result: result) else { return }
        guard let params = call.arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Expected Map", details: nil))
            return
        }

        for (key, value) in params {
            if let stringValue = value as? String {
                engine.setStringParam(stringValue, forKey: key)
            } else if let boolValue = value as? Bool {
                engine.setBoolParam(boolValue, forKey: key)
            } else if let intValue = value as? Int {
                engine.setIntParam(intValue, forKey: key)
            }
        }
        result(nil)
    }

    // ============================================================
    // setOptionString / setOptionBool / setOptionInt
    // ============================================================
    private func handleSetOptionString(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let engine = requireEngine(result: result) else { return }
        guard let args = call.arguments as? [String: Any],
              let key = args["key"] as? String,
              let value = args["value"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
            return
        }
        engine.setStringParam(value, forKey: key)
        result(nil)
    }

    private func handleSetOptionBool(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let engine = requireEngine(result: result) else { return }
        guard let args = call.arguments as? [String: Any],
              let key = args["key"] as? String,
              let value = args["value"] as? Bool else {
            result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
            return
        }
        engine.setBoolParam(value, forKey: key)
        result(nil)
    }

    private func handleSetOptionInt(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let engine = requireEngine(result: result) else { return }
        guard let args = call.arguments as? [String: Any],
              let key = args["key"] as? String,
              let value = args["value"] as? Int else {
            result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
            return
        }
        engine.setIntParam(value, forKey: key)
        result(nil)
    }

    // ============================================================
    // 4. initEngine
    // ============================================================
    private func handleInitEngine(result: @escaping FlutterResult) {
        guard let engine = requireEngine(result: result) else { return }
        let ret = engine.initEngine()
        if ret.rawValue != SENoError.rawValue {
            result(Int(ret.rawValue))
        } else {
            result(0)
        }
    }

    // ============================================================
    // 5. sendDirective
    // ============================================================
    private func handleSendDirective(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let engine = requireEngine(result: result) else { return }
        guard let args = call.arguments as? [String: Any],
              let directiveStr = args["directive"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
            return
        }

        let dataStr = args["data"] as? String ?? ""
        let directive = resolveDirective(directiveStr)
        let data = dataStr.data(using: .utf8) ?? Data()

        let ret: SEEngineErrorCode
        if dataStr.isEmpty {
            ret = engine.sendDirective(directive)
        } else {
            ret = engine.sendDirective(directive, data: dataStr)
        }

        if ret != SENoError {
            result(FlutterError(code: "DIRECTIVE_FAILED",
                                message: "sendDirective returned \(ret.rawValue)",
                                details: nil))
        } else {
            result(nil)
        }
    }

    // ============================================================
    // 6. feedAudio
    // ============================================================
    private func handleFeedAudio(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let engine = requireEngine(result: result) else { return }

        guard let audioData = call.arguments as? FlutterStandardTypedData else {
            result(FlutterError(code: "INVALID_AUDIO", message: "Expected Uint8List", details: nil))
            return
        }

        let bytes = audioData.data
        let int16Count = bytes.count / 2
        var int16Array = [Int16](repeating: 0, count: int16Count)
        _ = int16Array.withUnsafeMutableBufferPointer { buffer in
            bytes.copyBytes(to: buffer)
        }

        let ret = engine.feedAudio(int16Array, length: Int32(int16Count))
        result(Int(ret.rawValue))
    }

    // ============================================================
    // stopEngine
    // ============================================================
    private func handleStopEngine(result: @escaping FlutterResult) {
        guard let engine = speechEngine else {
            result(nil)
            return
        }
        // 异步执行以避免回调线程死锁
        DispatchQueue.global().async {
            _ = engine.sendDirective(SEDirectiveSyncStopEngine)
            DispatchQueue.main.async {
                result(nil)
            }
        }
    }

    // ============================================================
    // destroyEngine
    // ============================================================
    private func handleDestroyEngine(result: @escaping FlutterResult) {
        destroyEngineInternal()
        result(nil)
    }

    private func destroyEngineInternal() {
        guard let engine = speechEngine else { return }
        DispatchQueue.global().async {
            _ = engine.sendDirective(SEDirectiveSyncStopEngine)
            engine.destroyEngine()
        }
        speechEngine = nil
    }

    // ============================================================
    // SpeechEngine 回调 — 将所有事件桥接到 EventChannel
    // ============================================================
    private func sendEvent(type: String, text: String? = nil, audio: Data? = nil) {
        var eventMap: [String: Any] = ["type": type]
        if let text = text {
            eventMap["text"] = text
        }
        if let audio = audio {
            eventMap["audio"] = FlutterStandardTypedData(bytes: audio)
        }
        DispatchQueue.main.async { [weak self] in
            self?.eventSink?(eventMap)
        }
    }

    // ============================================================
    // Directive 字符串 → 枚举 映射
    // ============================================================
    private func resolveDirective(_ name: String) -> String {
        switch name {
        case "DIRECTIVE_SYNC_STOP_ENGINE":           return SEDirectiveSyncStopEngine
        case "DIRECTIVE_START_ENGINE":               return SEDirectiveStartEngine
        case "DIRECTIVE_EVENT_SAY_HELLO":            return SEDirectiveEventSayHello
        case "DIRECTIVE_DIALOG_CHAT_TTS_TEXT":       return SEDirectiveDialogChatTtsText
        case "DIRECTIVE_DIALOG_USE_CLIENT_TRIGGER_TTS": return SEDirectiveDialogUseClientTriggerTts
        case "DIRECTIVE_DIALOG_USE_SERVER_TRIGGER_TTS": return SEDirectiveDialogUseServerTriggerTts
        case "DIRECTIVE_EVENT_CHAT_TEXT_QUERY":      return SEDirectiveEventChatTextQuery
        case "DIRECTIVE_EVENT_CHAT_RAG_TEXT":        return SEDirectiveEventChatRagText
        case "DIRECTIVE_EVENT_CLIENT_INTERRUPT":     return SEDirectiveEventClientInterrupt
        case "DIRECTIVE_EVENT_UPDATE_CONFIG":        return SEDirectiveEventUpdateConfig
        case "DIRECTIVE_PAUSE_PLAYER":               return SEDirectivePausePlayer
        case "DIRECTIVE_RESUME_PLAYER":              return SEDirectiveResumePlayer
        case "DIRECTIVE_PAUSE_RECORDER":             return SEDirectivePauseRecorder
        case "DIRECTIVE_RESUME_RECORDER":            return SEDirectiveResumeRecorder
        default: return name
        }
    }

    private func requireEngine(result: @escaping FlutterResult) -> SpeechEngine? {
        guard let engine = speechEngine else {
            result(FlutterError(code: "ENGINE_NOT_CREATED", message: "请先调用 createEngine()", details: nil))
            return nil
        }
        return engine
    }
}

// ============================================================
// SpeechEngineDelegate — 回调实现
// ============================================================
extension DoubaoVoiceEnginePlugin: SpeechEngineDelegate {

    public func onMessage(withType type: SEMessageType, andData data: Data) {
        switch type {
        case SEEngineStart:
            let text = String(data: data, encoding: .utf8)
            sendEvent(type: "MESSAGE_TYPE_ENGINE_START", text: text)

        case SEEngineStop:
            let text = String(data: data, encoding: .utf8)
            sendEvent(type: "MESSAGE_TYPE_ENGINE_STOP", text: text)

        case SEEngineError:
            let text = String(data: data, encoding: .utf8)
            sendEvent(type: "MESSAGE_TYPE_ENGINE_ERROR", text: text)

        case SEDialogASRInfo:
            let text = String(data: data, encoding: .utf8)
            sendEvent(type: "MESSAGE_TYPE_DIALOG_ASR_INFO", text: text)

        case SEDialogASRResponse:
            let text = String(data: data, encoding: .utf8)
            sendEvent(type: "MESSAGE_TYPE_DIALOG_ASR_RESPONSE", text: text)

        case SEDialogASREnded:
            let text = String(data: data, encoding: .utf8)
            sendEvent(type: "MESSAGE_TYPE_DIALOG_ASR_ENDED", text: text)

        case SEDialogChatResponse:
            let text = String(data: data, encoding: .utf8)
            sendEvent(type: "MESSAGE_TYPE_DIALOG_CHAT_RESPONSE", text: text)

        case SEDialogChatEnded:
            let text = String(data: data, encoding: .utf8)
            sendEvent(type: "MESSAGE_TYPE_DIALOG_CHAT_ENDED", text: text)

        case SEDialogPlayerAudio:
            sendEvent(type: "MESSAGE_TYPE_PLAYER_AUDIO_DATA", audio: data)

        case SEDecoderAudioData:
            sendEvent(type: "MESSAGE_TYPE_DECODER_AUDIO_DATA", audio: data)

        case SEDialogRecorderAudio:
            sendEvent(type: "MESSAGE_TYPE_DIALOG_RECORDER_AUDIO", audio: data)

        default:
            break
        }
    }
}

// ============================================================
// FlutterStreamHandler — EventChannel 管理
// ============================================================
extension DoubaoVoiceEnginePlugin: FlutterStreamHandler {

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
}
