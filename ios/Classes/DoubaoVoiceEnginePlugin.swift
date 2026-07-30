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

    /// SDK 参数 key → 真实值映射表
    /// 取值自 SDK 二进制，常量的「值」而非「标识符名」。
    /// 之前误将 "PARAMS_KEY_APP_ID_STRING"（标识符名）当作 key 传给 SDK，
    /// SDK 不认识这些 key，所有参数被静默丢弃，导致 initEngine() 返回 -202。
    private enum SDKKey {
        static let engineName                  = "engine_name"
        static let logLevel                    = "log_level"
        static let debugPath                   = "debug_path"
        static let appId                       = "appid"
        static let appKey                      = "appkey"
        static let appToken                    = "token"
        static let resourceId                  = "resource_id"
        static let uid                         = "uid"
        static let dialogAddress               = "dialog_address"
        static let dialogUri                   = "dialog_uri"
        static let enableAec                   = "enable_aec"
        static let aecModelPath                = "aec_model_path"
        static let recorderDataSourceType      = "recorder_data_source_type"
        static let dialogRecorderPath          = "dialog_recorder_path"
        static let dialogEnableRecorderAudioCB = "dialog_enable_recorder_audio_callback"
        static let dialogEnablePlayer          = "dialog_enable_player"
        static let dialogEnablePlayerAudioCB   = "dialog_enable_player_audio_callback"
        static let dialogEnableDecoderAudioCB  = "dialog_enable_decoder_audio_callback"
        static let dialogPlayerPath            = "dialog_player_path"
        static let dialogWorkMode              = "dialog_work_mode"
        static let enableResampler             = "enable_resampler"
        static let customSampleRate            = "custom_sample_rate"
        static let customChannel               = "custom_channel"
    }

    /// SDK 枚举值映射
    /// 与参数 key 同理，传的是常量值而非标识符名
    private enum SDKValue {
        static let engineDialog   = "dialog"
        static let recorderTypeRecorder = "Recorder"
        static let recorderTypeStream   = "Stream"
        static let logLevelTrace  = "TRACE"
    }

    func configure(config: EngineConfigMessage) throws {
        guard let engine = speechEngine else {
            throw PigeonError(code: "ENGINE_NOT_CREATED", message: "请先调用 createEngine()", details: nil)
        }

        // 引擎基础
        engine.setStringParam(SDKValue.engineDialog, forKey: SDKKey.engineName)
        NSLog("[DoubaoVoice] configure STRING  engine_name        = dialog")
        engine.setStringParam(config.logLevel, forKey: SDKKey.logLevel)
        if let debugPath = config.debugPath {
            engine.setStringParam(debugPath, forKey: SDKKey.debugPath)
        }

        // 鉴权
        NSLog("[DoubaoVoice] configure STRING  appid              = %@", config.appId)
        engine.setStringParam(config.appId, forKey: SDKKey.appId)
        engine.setStringParam(config.appKey, forKey: SDKKey.appKey)
        engine.setStringParam(config.appToken, forKey: SDKKey.appToken)
        NSLog("[DoubaoVoice] configure STRING  resource_id        = %@", config.resourceId)
        engine.setStringParam(config.resourceId, forKey: SDKKey.resourceId)
        engine.setStringParam(config.uid, forKey: SDKKey.uid)
        engine.setStringParam(config.dialogAddress, forKey: SDKKey.dialogAddress)
        engine.setStringParam(config.dialogUri, forKey: SDKKey.dialogUri)

        // AEC
        NSLog("[DoubaoVoice] configure BOOL    enable_aec         = %@", config.enableAec ? "true" : "false")
        engine.setBoolParam(config.enableAec, forKey: SDKKey.enableAec)
        if config.enableAec, let aecModelPath = config.aecModelPath {
            engine.setStringParam(aecModelPath, forKey: SDKKey.aecModelPath)
        }

        // 录音机
        engine.setStringParam(config.recorderType, forKey: SDKKey.recorderDataSourceType)
        if let recorderPath = config.recorderPath {
            engine.setStringParam(recorderPath, forKey: SDKKey.dialogRecorderPath)
        }
        engine.setBoolParam(config.enableRecorderAudioCallback, forKey: SDKKey.dialogEnableRecorderAudioCB)

        // 播放器
        NSLog("[DoubaoVoice] configure BOOL    dialog_enable_player = %@", config.enablePlayer ? "true" : "false")
        engine.setBoolParam(config.enablePlayer, forKey: SDKKey.dialogEnablePlayer)
        engine.setBoolParam(config.enablePlayerAudioCallback, forKey: SDKKey.dialogEnablePlayerAudioCB)
        engine.setBoolParam(config.enableDecoderAudioCallback, forKey: SDKKey.dialogEnableDecoderAudioCB)
        if let playerPath = config.playerPath {
            engine.setStringParam(playerPath, forKey: SDKKey.dialogPlayerPath)
        }

        // 工作模式（仅在非默认模式时设置）
        if let workMode = config.dialogWorkMode {
            NSLog("[DoubaoVoice] configure INT     dialog_work_mode   = %d", workMode)
            engine.setIntParam(Int(workMode), forKey: SDKKey.dialogWorkMode)
        }

        // 重采样
        engine.setBoolParam(config.enableResampler, forKey: SDKKey.enableResampler)
        if config.enableResampler {
            if let sampleRate = config.customSampleRate {
                engine.setIntParam(Int(sampleRate), forKey: SDKKey.customSampleRate)
            }
            if let channel = config.customChannel {
                engine.setIntParam(Int(channel), forKey: SDKKey.customChannel)
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
        engine.setIntParam(Int(value), forKey: key)
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
