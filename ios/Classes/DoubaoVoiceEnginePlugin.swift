import Flutter
import UIKit
import SpeechEngineToB

/// DoubaoVoiceEnginePlugin — Pigeon 架构
///
/// 实现 DoubaoVoiceHostApi 协议处理 Dart 调用，
/// 使用 DoubaoVoiceFlutterApi 发送事件回调到 Dart 侧。
public class DoubaoVoiceEnginePlugin: NSObject, FlutterPlugin, DoubaoVoiceHostApi, SpeechEngineDelegate {

    private var speechEngine: SpeechEngine?
    private var flutterApi: DoubaoVoiceFlutterApi?

    // ============================================================
    // FlutterPlugin 注册
    // ============================================================
    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = DoubaoVoiceEnginePlugin()

        // Pigeon HostApi 注册
        DoubaoVoiceHostApiSetup.setUp(
            binaryMessenger: registrar.messenger(),
            api: instance
        )

        // FlutterApi 用于发送事件到 Dart
        instance.flutterApi = DoubaoVoiceFlutterApi(binaryMessenger: registrar.messenger())
    }

    // FlutterPlugin 协议要求实现，但 Pigeon 架构下不再使用 MethodChannel
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        result(FlutterMethodNotImplemented)
    }

    // ============================================================
    // DoubaoVoiceHostApi 实现
    // ============================================================

    func prepareEnvironment() throws -> Bool {
        let ok = SpeechEngine.prepareEnvironment()
        NSLog("[DoubaoVoice] prepareEnvironment -> %@", ok ? "OK" : "FAILED")
        return ok
    }

    func createEngine() throws {
        let engine = SpeechEngine()
        engine.createEngine(with: self)
        speechEngine = engine
        NSLog("[DoubaoVoice] createEngine -> OK")
    }

    func configure(config: EngineConfigMessage) throws {
        guard let engine = speechEngine else {
            throw PigeonError(code: "ENGINE_NOT_CREATED", message: "请先调用 createEngine()", details: nil)
        }

        // 引擎基础
        engine.setStringParam("DIALOG_ENGINE", forKey: "PARAMS_KEY_ENGINE_NAME_STRING")
        NSLog("[DoubaoVoice] configure STRING  PARAMS_KEY_ENGINE_NAME_STRING = DIALOG_ENGINE")
        engine.setStringParam(config.logLevel, forKey: "PARAMS_KEY_LOG_LEVEL_STRING")
        if let debugPath = config.debugPath {
            engine.setStringParam(debugPath, forKey: "PARAMS_KEY_DEBUG_PATH_STRING")
        }

        // 鉴权
        NSLog("[DoubaoVoice] configure STRING  PARAMS_KEY_APP_ID_STRING = %@", config.appId)
        engine.setStringParam(config.appId, forKey: "PARAMS_KEY_APP_ID_STRING")
        engine.setStringParam(config.appKey, forKey: "PARAMS_KEY_APP_KEY_STRING")
        engine.setStringParam(config.appToken, forKey: "PARAMS_KEY_APP_TOKEN_STRING")
        NSLog("[DoubaoVoice] configure STRING  PARAMS_KEY_RESOURCE_ID_STRING = %@", config.resourceId)
        engine.setStringParam(config.resourceId, forKey: "PARAMS_KEY_RESOURCE_ID_STRING")
        engine.setStringParam(config.uid, forKey: "PARAMS_KEY_UID_STRING")
        engine.setStringParam(config.dialogAddress, forKey: "PARAMS_KEY_DIALOG_ADDRESS_STRING")
        engine.setStringParam(config.dialogUri, forKey: "PARAMS_KEY_DIALOG_URI_STRING")

        // AEC
        NSLog("[DoubaoVoice] configure BOOL    PARAMS_KEY_ENABLE_AEC_BOOL = %@", config.enableAec ? "true" : "false")
        engine.setBoolParam(config.enableAec, forKey: "PARAMS_KEY_ENABLE_AEC_BOOL")
        if config.enableAec, let aecModelPath = config.aecModelPath {
            engine.setStringParam(aecModelPath, forKey: "PARAMS_KEY_AEC_MODEL_PATH_STRING")
        }

        // 录音机
        engine.setStringParam(config.recorderType, forKey: "PARAMS_KEY_RECORDER_TYPE_STRING")
        if let recorderPath = config.recorderPath {
            engine.setStringParam(recorderPath, forKey: "PARAMS_KEY_DIALOG_RECORDER_PATH_STRING")
        }
        engine.setBoolParam(config.enableRecorderAudioCallback, forKey: "PARAMS_KEY_DIALOG_ENABLE_RECORDER_AUDIO_CALLBACK_BOOL")

        // 播放器
        NSLog("[DoubaoVoice] configure BOOL    PARAMS_KEY_DIALOG_ENABLE_PLAYER_BOOL = %@", config.enablePlayer ? "true" : "false")
        engine.setBoolParam(config.enablePlayer, forKey: "PARAMS_KEY_DIALOG_ENABLE_PLAYER_BOOL")
        engine.setBoolParam(config.enablePlayerAudioCallback, forKey: "PARAMS_KEY_DIALOG_ENABLE_PLAYER_AUDIO_CALLBACK_BOOL")
        engine.setBoolParam(config.enableDecoderAudioCallback, forKey: "PARAMS_KEY_DIALOG_ENABLE_DECODER_AUDIO_CALLBACK_BOOL")
        if let playerPath = config.playerPath {
            engine.setStringParam(playerPath, forKey: "PARAMS_KEY_DIALOG_PLAYER_PATH_STRING")
        }

        // 工作模式（仅在非默认模式时设置）
        if let workMode = config.dialogWorkMode {
            NSLog("[DoubaoVoice] configure INT     PARAMS_KEY_DIALOG_WORK_MODE_INT = %d", workMode)
            engine.setIntParam(Int32(workMode), forKey: "PARAMS_KEY_DIALOG_WORK_MODE_INT")
        }

        // 重采样
        engine.setBoolParam(config.enableResampler, forKey: "PARAMS_KEY_ENABLE_RESAMPLER_BOOL")
        if config.enableResampler {
            if let sampleRate = config.customSampleRate {
                engine.setIntParam(Int32(sampleRate), forKey: "PARAMS_KEY_CUSTOM_SAMPLE_RATE_INT")
            }
            if let channel = config.customChannel {
                engine.setIntParam(Int32(channel), forKey: "PARAMS_KEY_CUSTOM_CHANNEL_INT")
            }
        }

        NSLog("[DoubaoVoice] configure done")
    }

    func setOptionString(key: String, value: String) throws {
        guard let engine = speechEngine else {
            throw PigeonError(code: "ENGINE_NOT_CREATED", message: "请先调用 createEngine()", details: nil)
        }
        engine.setStringParam(value, forKey: key)
    }

    func setOptionBool(key: String, value: Bool) throws {
        guard let engine = speechEngine else {
            throw PigeonError(code: "ENGINE_NOT_CREATED", message: "请先调用 createEngine()", details: nil)
        }
        engine.setBoolParam(value, forKey: key)
    }

    func setOptionInt(key: String, value: Int64) throws {
        guard let engine = speechEngine else {
            throw PigeonError(code: "ENGINE_NOT_CREATED", message: "请先调用 createEngine()", details: nil)
        }
        engine.setIntParam(Int32(value), forKey: key)
    }

    func initEngine() throws -> Int64 {
        guard let engine = speechEngine else {
            throw PigeonError(code: "ENGINE_NOT_CREATED", message: "请先调用 createEngine()", details: nil)
        }
        let ret = engine.initEngine()
        if ret.rawValue != SENoError.rawValue {
            NSLog("[DoubaoVoice] initEngine FAILED — error code: %d (0x%X)", ret.rawValue, ret.rawValue)
            return Int64(ret.rawValue)
        }
        NSLog("[DoubaoVoice] initEngine SUCCESS")
        return 0
    }

    func sendDirective(request: DirectiveRequest) throws {
        guard let engine = speechEngine else {
            throw PigeonError(code: "ENGINE_NOT_CREATED", message: "请先调用 createEngine()", details: nil)
        }

        let directive = resolveDirective(request.directive)
        let dataStr = request.data ?? ""

        let ret: SEEngineErrorCode
        if dataStr.isEmpty {
            ret = engine.send(directive)
        } else {
            ret = engine.send(directive, data: dataStr)
        }

        if ret != SENoError {
            throw PigeonError(code: "DIRECTIVE_FAILED", message: "send returned \(ret.rawValue)", details: nil)
        }
    }

    func feedAudio(buffer: FlutterStandardTypedData) throws -> Int64 {
        guard let engine = speechEngine else {
            throw PigeonError(code: "ENGINE_NOT_CREATED", message: "请先调用 createEngine()", details: nil)
        }

        let bytes = buffer.data
        let int16Count = bytes.count / 2
        var int16Array = [Int16](repeating: 0, count: int16Count)
        int16Array.withUnsafeMutableBufferPointer { ptr in
            bytes.copyBytes(to: ptr)
        }

        let ret = int16Array.withUnsafeMutableBufferPointer { ptr in
            engine.feedAudio(ptr.baseAddress!, length: Int32(int16Count))
        }
        return Int64(ret.rawValue)
    }

    func stopEngine(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let engine = speechEngine else {
            completion(.success(()))
            return
        }
        // 异步执行以避免回调线程死锁
        DispatchQueue.global().async {
            _ = engine.send(SEDirectiveSyncStopEngine)
            DispatchQueue.main.async {
                completion(.success(()))
            }
        }
    }

    func destroyEngine(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let engine = speechEngine else {
            completion(.success(()))
            return
        }
        DispatchQueue.global().async {
            _ = engine.send(SEDirectiveSyncStopEngine)
            engine.destroy()
            DispatchQueue.main.async {
                completion(.success(()))
            }
        }
        speechEngine = nil
    }

    // ============================================================
    // SpeechEngineDelegate — SDK 回调，通过 Pigeon FlutterApi 发送到 Dart
    // ============================================================
    public func onMessage(with type: SEMessageType, andData data: Data) {
        let event: EngineEventMessage?

        switch type {
        case SEEngineStart:
            let text = String(data: data, encoding: .utf8)
            event = EngineEventMessage(type: "MESSAGE_TYPE_ENGINE_START", text: text)

        case SEEngineStop:
            let text = String(data: data, encoding: .utf8)
            event = EngineEventMessage(type: "MESSAGE_TYPE_ENGINE_STOP", text: text)

        case SEEngineError:
            let text = String(data: data, encoding: .utf8)
            event = EngineEventMessage(type: "MESSAGE_TYPE_ENGINE_ERROR", text: text)

        case SEDialogASRInfo:
            let text = String(data: data, encoding: .utf8)
            event = EngineEventMessage(type: "MESSAGE_TYPE_DIALOG_ASR_INFO", text: text)

        case SEDialogASRResponse:
            let text = String(data: data, encoding: .utf8)
            event = EngineEventMessage(type: "MESSAGE_TYPE_DIALOG_ASR_RESPONSE", text: text)

        case SEDialogASREnded:
            let text = String(data: data, encoding: .utf8)
            event = EngineEventMessage(type: "MESSAGE_TYPE_DIALOG_ASR_ENDED", text: text)

        case SEDialogChatResponse:
            let text = String(data: data, encoding: .utf8)
            event = EngineEventMessage(type: "MESSAGE_TYPE_DIALOG_CHAT_RESPONSE", text: text)

        case SEDialogChatEnded:
            let text = String(data: data, encoding: .utf8)
            event = EngineEventMessage(type: "MESSAGE_TYPE_DIALOG_CHAT_ENDED", text: text)

        case SEDialogPlayerAudio:
            event = EngineEventMessage(type: "MESSAGE_TYPE_PLAYER_AUDIO_DATA", audio: FlutterStandardTypedData(bytes: data))

        case SEDecoderAudioData:
            event = EngineEventMessage(type: "MESSAGE_TYPE_DECODER_AUDIO_DATA", audio: FlutterStandardTypedData(bytes: data))

        case SEDialogRecorderAudio:
            event = EngineEventMessage(type: "MESSAGE_TYPE_DIALOG_RECORDER_AUDIO", audio: FlutterStandardTypedData(bytes: data))

        default:
            event = nil
        }

        guard let event = event else { return }

        // 通过 Pigeon FlutterApi 发送事件到 Dart
        DispatchQueue.main.async { [weak self] in
            self?.flutterApi?.onEngineEvent(event: event) { result in
                switch result {
                case .failure(let error):
                    NSLog("[DoubaoVoice] FlutterApi onEngineEvent failed: %@", error.localizedDescription)
                case .success:
                    break
                }
            }
        }
    }

    // ============================================================
    // Directive 字符串 → 枚举 映射
    // ============================================================
    private func resolveDirective(_ name: String) -> SEDirective {
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
        default: return SEDirectiveSyncStopEngine
        }
    }
}
