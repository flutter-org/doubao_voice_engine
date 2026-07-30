package com.volcengine.doubao_voice_engine

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.annotation.NonNull
import com.bytedance.speech.speechengine.SpeechEngine
import com.bytedance.speech.speechengine.SpeechEngineDefines
import com.bytedance.speech.speechengine.SpeechEngineGenerator
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import java.nio.ByteBuffer

/**
 * DoubaoVoiceEnginePlugin — Pigeon 架构
 *
 * 实现 DoubaoVoiceHostApi 接口处理 Dart 调用，
 * 使用 DoubaoVoiceFlutterApi 发送事件回调到 Dart 侧。
 */
class DoubaoVoiceEnginePlugin : FlutterPlugin, DoubaoVoiceHostApi {

    private var speechEngine: SpeechEngine? = null
    private var applicationContext: Context? = null
    private var binaryMessenger: BinaryMessenger? = null
    private var flutterApi: DoubaoVoiceFlutterApi? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    companion object {
        private const val TAG = "DoubaoVoice"
    }

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = flutterPluginBinding.applicationContext
        binaryMessenger = flutterPluginBinding.binaryMessenger

        // 注册 Pigeon HostApi
        DoubaoVoiceHostApi.setUp(
            flutterPluginBinding.binaryMessenger,
            this
        )

        // 创建 FlutterApi 用于发送事件到 Dart
        flutterApi = DoubaoVoiceFlutterApi(flutterPluginBinding.binaryMessenger)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        DoubaoVoiceHostApi.setUp(binding.binaryMessenger, null)
        flutterApi = null
        binaryMessenger = null
        destroyEngineInternal()
    }

    // ============================================================
    // DoubaoVoiceHostApi 实现
    // ============================================================

    override fun prepareEnvironment(): Boolean {
        return try {
            SpeechEngineGenerator.PrepareEnvironment(
                applicationContext,
                applicationContext
            )
            Log.d(TAG, "prepareEnvironment -> OK")
            true
        } catch (e: Exception) {
            Log.e(TAG, "prepareEnvironment FAILED", e)
            false
        }
    }

    override fun createEngine() {
        val engine = SpeechEngineGenerator.getInstance()
        engine.createEngine()
        speechEngine = engine
        Log.d(TAG, "createEngine -> OK")
    }

    // ============================================================
    // SDK 参数 key → 真实值映射
    // 取值自 SDK 二进制，常量的「值」而非「标识符名」。
    // 之前误将 "PARAMS_KEY_APP_ID_STRING"（标识符名）当作 key 传给 SDK，
    // SDK 不认识这些 key，所有参数被静默丢弃，导致 initEngine() 返回 -202。
    // ============================================================
    private object SDKKey {
        const val ENGINE_NAME                  = "engine_name"
        const val LOG_LEVEL                    = "log_level"
        const val DEBUG_PATH                   = "debug_path"
        const val APP_ID                       = "appid"
        const val APP_KEY                      = "appkey"
        const val APP_TOKEN                    = "token"
        const val RESOURCE_ID                  = "resource_id"
        const val UID                          = "uid"
        const val DIALOG_ADDRESS               = "dialog_address"
        const val DIALOG_URI                   = "dialog_uri"
        const val ENABLE_AEC                   = "enable_aec"
        const val AEC_MODEL_PATH               = "aec_model_path"
        const val RECORDER_DATA_SOURCE_TYPE    = "recorder_data_source_type"
        const val DIALOG_RECORDER_PATH         = "dialog_recorder_path"
        const val DIALOG_ENABLE_RECORDER_AUDIO_CB = "dialog_enable_recorder_audio_callback"
        const val DIALOG_ENABLE_PLAYER         = "dialog_enable_player"
        const val DIALOG_ENABLE_PLAYER_AUDIO_CB   = "dialog_enable_player_audio_callback"
        const val DIALOG_ENABLE_DECODER_AUDIO_CB  = "dialog_enable_decoder_audio_callback"
        const val DIALOG_PLAYER_PATH           = "dialog_player_path"
        const val DIALOG_WORK_MODE             = "dialog_work_mode"
        const val ENABLE_RESAMPLER             = "enable_resampler"
        const val CUSTOM_SAMPLE_RATE           = "custom_sample_rate"
        const val CUSTOM_CHANNEL               = "custom_channel"
    }

    private object SDKValue {
        const val ENGINE_DIALOG        = "dialog"
        const val RECORDER_TYPE_RECORDER = "Recorder"
        const val RECORDER_TYPE_STREAM   = "Stream"
        const val LOG_LEVEL_TRACE       = "TRACE"
    }

    override fun configure(config: EngineConfigMessage) {
        val engine = speechEngine ?: throw IllegalStateException("请先调用 createEngine()")

        // 引擎基础
        engine.setOptionString(SDKKey.ENGINE_NAME, SDKValue.ENGINE_DIALOG)
        Log.d(TAG, "configure STRING  engine_name        = dialog")
        engine.setOptionString(SDKKey.LOG_LEVEL, config.logLevel)
        config.debugPath?.let { engine.setOptionString(SDKKey.DEBUG_PATH, it) }

        // 鉴权
        Log.d(TAG, "configure STRING  appid              = ${config.appId}")
        engine.setOptionString(SDKKey.APP_ID, config.appId)
        engine.setOptionString(SDKKey.APP_KEY, config.appKey)
        engine.setOptionString(SDKKey.APP_TOKEN, config.appToken)
        engine.setOptionString(SDKKey.RESOURCE_ID, config.resourceId)
        Log.d(TAG, "configure STRING  resource_id        = ${config.resourceId}")
        engine.setOptionString(SDKKey.UID, config.uid)
        engine.setOptionString(SDKKey.DIALOG_ADDRESS, config.dialogAddress)
        engine.setOptionString(SDKKey.DIALOG_URI, config.dialogUri)

        // AEC
        Log.d(TAG, "configure BOOL    enable_aec         = ${config.enableAec}")
        engine.setOptionBoolean(SDKKey.ENABLE_AEC, config.enableAec)
        if (config.enableAec && config.aecModelPath != null) {
            engine.setOptionString(SDKKey.AEC_MODEL_PATH, config.aecModelPath)
        }

        // 录音机
        engine.setOptionString(SDKKey.RECORDER_DATA_SOURCE_TYPE, config.recorderType)
        config.recorderPath?.let {
            engine.setOptionString(SDKKey.DIALOG_RECORDER_PATH, it)
        }
        engine.setOptionBoolean(
            SDKKey.DIALOG_ENABLE_RECORDER_AUDIO_CB,
            config.enableRecorderAudioCallback
        )

        // 播放器
        Log.d(TAG, "configure BOOL    dialog_enable_player = ${config.enablePlayer}")
        engine.setOptionBoolean(SDKKey.DIALOG_ENABLE_PLAYER, config.enablePlayer)
        engine.setOptionBoolean(
            SDKKey.DIALOG_ENABLE_PLAYER_AUDIO_CB,
            config.enablePlayerAudioCallback
        )
        engine.setOptionBoolean(
            SDKKey.DIALOG_ENABLE_DECODER_AUDIO_CB,
            config.enableDecoderAudioCallback
        )
        config.playerPath?.let {
            engine.setOptionString(SDKKey.DIALOG_PLAYER_PATH, it)
        }

        // 工作模式（仅在非默认模式时设置）
        config.dialogWorkMode?.let {
            Log.d(TAG, "configure INT     dialog_work_mode   = $it")
            engine.setOptionInt(SDKKey.DIALOG_WORK_MODE, it)
        }

        // 重采样
        engine.setOptionBoolean(SDKKey.ENABLE_RESAMPLER, config.enableResampler)
        if (config.enableResampler) {
            config.customSampleRate?.let {
                engine.setOptionInt(SDKKey.CUSTOM_SAMPLE_RATE, it)
            }
            config.customChannel?.let {
                engine.setOptionInt(SDKKey.CUSTOM_CHANNEL, it)
            }
        }

        Log.d(TAG, "configure done")
    }

    override fun setOptionString(key: String, value: String) {
        val engine = speechEngine ?: throw IllegalStateException("请先调用 createEngine()")
        engine.setOptionString(key, value)
    }

    override fun setOptionBool(key: String, value: Boolean) {
        val engine = speechEngine ?: throw IllegalStateException("请先调用 createEngine()")
        engine.setOptionBoolean(key, value)
    }

    override fun setOptionInt(key: String, value: Long) {
        val engine = speechEngine ?: throw IllegalStateException("请先调用 createEngine()")
        engine.setOptionInt(key, value.toInt())
    }

    override fun initEngine(): Long {
        val engine = speechEngine ?: throw IllegalStateException("请先调用 createEngine()")
        val ret = engine.initEngine()
        if (ret != SpeechEngineDefines.ERR_NO_ERROR) {
            Log.e(TAG, "initEngine FAILED — error code: $ret")
            return ret.toLong()
        }
        Log.d(TAG, "initEngine SUCCESS")
        engine.setContext(applicationContext)
        engine.setListener(speechListener)
        return 0L
    }

    override fun sendDirective(request: DirectiveRequest) {
        val engine = speechEngine ?: throw IllegalStateException("请先调用 createEngine()")

        val directiveInt = resolveDirective(request.directive)
        if (directiveInt == -1) {
            throw IllegalArgumentException("Unknown directive: ${request.directive}")
        }

        val data = request.data ?: ""
        val ret = engine.sendDirective(directiveInt, data)
        if (ret != SpeechEngineDefines.ERR_NO_ERROR) {
            throw RuntimeException("sendDirective returned $ret")
        }
    }

    override fun feedAudio(buffer: ByteArray): Long {
        val engine = speechEngine ?: throw IllegalStateException("请先调用 createEngine()")

        val shortBuffer = ByteBuffer.wrap(buffer).asShortBuffer()
        val shortArray = ShortArray(shortBuffer.remaining())
        shortBuffer.get(shortArray)

        val ret = engine.feedAudio(shortArray, shortArray.size)
        return ret.toLong()
    }

    override fun stopEngine(callback: (Result<Unit>) -> Unit) {
        val engine = speechEngine ?: run {
            callback(Result.success(Unit))
            return
        }
        // 异步停止，避免回调线程死锁
        Thread {
            try {
                engine.sendDirective(resolveDirective("DIRECTIVE_SYNC_STOP_ENGINE"), "")
                mainHandler.post { callback(Result.success(Unit)) }
            } catch (e: Exception) {
                mainHandler.post { callback(Result.failure(e)) }
            }
        }.start()
    }

    override fun destroyEngine(callback: (Result<Unit>) -> Unit) {
        val engine = speechEngine ?: run {
            callback(Result.success(Unit))
            return
        }
        Thread {
            try {
                engine.sendDirective(resolveDirective("DIRECTIVE_SYNC_STOP_ENGINE"), "")
                engine.destroyEngine()
            } catch (_: Exception) {}
            mainHandler.post { callback(Result.success(Unit)) }
        }.start()
        speechEngine = null
    }

    private fun destroyEngineInternal() {
        speechEngine?.let { engine ->
            Thread {
                try {
                    engine.sendDirective(resolveDirective("DIRECTIVE_SYNC_STOP_ENGINE"), "")
                } catch (_: Exception) {}
                engine.destroyEngine()
            }.start()
        }
        speechEngine = null
    }

    // ============================================================
    // SpeechEngine 回调监听器 — 通过 Pigeon FlutterApi 发送事件
    // ============================================================
    private val speechListener = object : SpeechEngine.SpeechListener {
        override fun onSpeechMessage(type: Int, data: ByteArray, len: Int) {
            val event = when (type) {
                SpeechEngineDefines.MESSAGE_TYPE_ENGINE_START ->
                    EngineEventMessage(
                        type = "MESSAGE_TYPE_ENGINE_START",
                        text = String(data, 0, len)
                    )
                SpeechEngineDefines.MESSAGE_TYPE_ENGINE_STOP ->
                    EngineEventMessage(
                        type = "MESSAGE_TYPE_ENGINE_STOP",
                        text = String(data, 0, len)
                    )
                SpeechEngineDefines.MESSAGE_TYPE_ENGINE_ERROR ->
                    EngineEventMessage(
                        type = "MESSAGE_TYPE_ENGINE_ERROR",
                        text = String(data, 0, len)
                    )
                SpeechEngineDefines.MESSAGE_TYPE_DIALOG_ASR_INFO ->
                    EngineEventMessage(
                        type = "MESSAGE_TYPE_DIALOG_ASR_INFO",
                        text = String(data, 0, len)
                    )
                SpeechEngineDefines.MESSAGE_TYPE_DIALOG_ASR_RESPONSE ->
                    EngineEventMessage(
                        type = "MESSAGE_TYPE_DIALOG_ASR_RESPONSE",
                        text = String(data, 0, len)
                    )
                SpeechEngineDefines.MESSAGE_TYPE_DIALOG_ASR_ENDED ->
                    EngineEventMessage(
                        type = "MESSAGE_TYPE_DIALOG_ASR_ENDED",
                        text = String(data, 0, len)
                    )
                SpeechEngineDefines.MESSAGE_TYPE_DIALOG_CHAT_RESPONSE ->
                    EngineEventMessage(
                        type = "MESSAGE_TYPE_DIALOG_CHAT_RESPONSE",
                        text = String(data, 0, len)
                    )
                SpeechEngineDefines.MESSAGE_TYPE_DIALOG_CHAT_ENDED ->
                    EngineEventMessage(
                        type = "MESSAGE_TYPE_DIALOG_CHAT_ENDED",
                        text = String(data, 0, len)
                    )
                SpeechEngineDefines.MESSAGE_TYPE_PLAYER_AUDIO_DATA ->
                    EngineEventMessage(
                        type = "MESSAGE_TYPE_PLAYER_AUDIO_DATA",
                        audio = data.copyOf(len)
                    )
                SpeechEngineDefines.MESSAGE_TYPE_DECODER_AUDIO_DATA ->
                    EngineEventMessage(
                        type = "MESSAGE_TYPE_DECODER_AUDIO_DATA",
                        audio = data.copyOf(len)
                    )
                SpeechEngineDefines.MESSAGE_TYPE_DIALOG_RECORDER_AUDIO ->
                    EngineEventMessage(
                        type = "MESSAGE_TYPE_DIALOG_RECORDER_AUDIO",
                        audio = data.copyOf(len)
                    )
                else -> return
            }

            // 通过 Pigeon FlutterApi 发送事件到 Dart
            mainHandler.post {
                flutterApi?.onEngineEvent(event) { result ->
                    result.onFailure { Log.e(TAG, "FlutterApi onEngineEvent failed", it) }
                }
            }
        }
    }

    // ============================================================
    // Directive 字符串 → Int 映射
    // ============================================================
    private fun resolveDirective(name: String): Int {
        return when (name) {
            "DIRECTIVE_SYNC_STOP_ENGINE" -> SpeechEngineDefines.DIRECTIVE_SYNC_STOP_ENGINE
            "DIRECTIVE_START_ENGINE" -> SpeechEngineDefines.DIRECTIVE_START_ENGINE
            "DIRECTIVE_EVENT_SAY_HELLO" -> SpeechEngineDefines.DIRECTIVE_EVENT_SAY_HELLO
            "DIRECTIVE_DIALOG_CHAT_TTS_TEXT" -> SpeechEngineDefines.DIRECTIVE_DIALOG_CHAT_TTS_TEXT
            "DIRECTIVE_DIALOG_USE_CLIENT_TRIGGER_TTS" -> SpeechEngineDefines.DIRECTIVE_DIALOG_USE_CLIENT_TRIGGER_TTS
            "DIRECTIVE_DIALOG_USE_SERVER_TRIGGER_TTS" -> SpeechEngineDefines.DIRECTIVE_DIALOG_USE_SERVER_TRIGGER_TTS
            "DIRECTIVE_EVENT_CHAT_TEXT_QUERY" -> SpeechEngineDefines.DIRECTIVE_EVENT_CHAT_TEXT_QUERY
            "DIRECTIVE_EVENT_CHAT_RAG_TEXT" -> SpeechEngineDefines.DIRECTIVE_EVENT_CHAT_RAG_TEXT
            "DIRECTIVE_EVENT_CLIENT_INTERRUPT" -> SpeechEngineDefines.DIRECTIVE_EVENT_CLIENT_INTERRUPT
            "DIRECTIVE_EVENT_UPDATE_CONFIG" -> SpeechEngineDefines.DIRECTIVE_EVENT_UPDATE_CONFIG
            "DIRECTIVE_PAUSE_PLAYER" -> SpeechEngineDefines.DIRECTIVE_PAUSE_PLAYER
            "DIRECTIVE_RESUME_PLAYER" -> SpeechEngineDefines.DIRECTIVE_RESUME_PLAYER
            "DIRECTIVE_PAUSE_RECORDER" -> SpeechEngineDefines.DIRECTIVE_PAUSE_RECORDER
            "DIRECTIVE_RESUME_RECORDER" -> SpeechEngineDefines.DIRECTIVE_RESUME_RECORDER
            else -> -1
        }
    }
}
