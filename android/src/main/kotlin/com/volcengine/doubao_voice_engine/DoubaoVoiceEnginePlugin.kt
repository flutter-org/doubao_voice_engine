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
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.nio.ByteBuffer

/** DoubaoVoiceEnginePlugin */
class DoubaoVoiceEnginePlugin : FlutterPlugin, MethodCallHandler {

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null
    private var speechEngine: SpeechEngine? = null
    private var applicationContext: Context? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    companion object {
        private const val TAG = "DoubaoVoice"
    }

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = flutterPluginBinding.applicationContext

        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "doubao_voice_engine/method")
        methodChannel.setMethodCallHandler(this)

        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "doubao_voice_engine/event")
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        eventSink = null
        destroyEngineInternal()
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        try {
            when (call.method) {
                "prepareEnvironment" -> handlePrepareEnvironment(result)
                "createEngine" -> handleCreateEngine(result)
                "configure" -> handleConfigure(call, result)
                "setOptionString" -> handleSetOptionString(call, result)
                "setOptionBool" -> handleSetOptionBool(call, result)
                "setOptionInt" -> handleSetOptionInt(call, result)
                "initEngine" -> handleInitEngine(result)
                "sendDirective" -> handleSendDirective(call, result)
                "feedAudio" -> handleFeedAudio(call, result)
                "stopEngine" -> handleStopEngine(result)
                "destroyEngine" -> handleDestroyEngine(result)
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("ENGINE_ERROR", e.message, null)
        }
    }

    // ============================================================
    // 1. prepareEnvironment
    // ============================================================
    private fun handlePrepareEnvironment(result: Result) {
        try {
            SpeechEngineGenerator.PrepareEnvironment(
                applicationContext,
                applicationContext
            )
            result.success(true) // 必须返回 true，Dart 层用 invokeMethod<bool> 判断
        } catch (e: Exception) {
            result.error("PREPARE_FAILED", e.message, null)
        }
    }

    // ============================================================
    // 2. createEngine
    // ============================================================
    private fun handleCreateEngine(result: Result) {
        try {
            val engine = SpeechEngineGenerator.getInstance()
            engine.createEngine()
            speechEngine = engine
            result.success(null)
        } catch (e: Exception) {
            result.error("CREATE_FAILED", e.message, null)
        }
    }

    // ============================================================
    // 3. configure — 批量配置
    // ============================================================
    private fun handleConfigure(call: MethodCall, result: Result) {
        val engine = requireEngine(result) ?: return
        val params = call.arguments as? Map<*, *> ?: run {
            result.error("INVALID_ARGS", "Expected Map", null)
            return
        }

        params.forEach { (key, value) ->
            val keyStr = key.toString()
            when (value) {
                is String -> {
                    Log.d(TAG, "configure STRING  $keyStr = $value")
                    engine.setOptionString(keyStr, value)
                }
                is Boolean -> {
                    Log.d(TAG, "configure BOOL    $keyStr = $value")
                    engine.setOptionBoolean(keyStr, value)
                }
                is Int -> {
                    Log.d(TAG, "configure INT     $keyStr = $value")
                    engine.setOptionInt(keyStr, value)
                }
            }
        }
        Log.d(TAG, "configure done — ${params.size} params set")
        result.success(null)
    }

    // ============================================================
    // setOptionString / setOptionBool / setOptionInt
    // ============================================================
    private fun handleSetOptionString(call: MethodCall, result: Result) {
        val engine = requireEngine(result) ?: return
        val args = call.arguments as? Map<*, *> ?: return
        engine.setOptionString(args["key"].toString(), args["value"].toString())
        result.success(null)
    }

    private fun handleSetOptionBool(call: MethodCall, result: Result) {
        val engine = requireEngine(result) ?: return
        val args = call.arguments as? Map<*, *> ?: return
        engine.setOptionBoolean(args["key"].toString(), args["value"] as Boolean)
        result.success(null)
    }

    private fun handleSetOptionInt(call: MethodCall, result: Result) {
        val engine = requireEngine(result) ?: return
        val args = call.arguments as? Map<*, *> ?: return
        engine.setOptionInt(args["key"].toString(), args["value"] as Int)
        result.success(null)
    }

    // ============================================================
    // 4. initEngine
    // ============================================================
    private fun handleInitEngine(result: Result) {
        val engine = requireEngine(result) ?: return
        val ret = engine.initEngine()
        if (ret != SpeechEngineDefines.ERR_NO_ERROR) {
            Log.e(TAG, "initEngine FAILED — error code: $ret")
            result.success(ret) // 返回错误码给 Dart 层处理
        } else {
            Log.d(TAG, "initEngine SUCCESS")
            engine.setContext(applicationContext)
            engine.setListener(speechListener)
            result.success(0)
        }
    }

    // ============================================================
    // 5. sendDirective
    // ============================================================
    private fun handleSendDirective(call: MethodCall, result: Result) {
        val engine = requireEngine(result) ?: return
        val args = call.arguments as? Map<*, *> ?: return

        val directive = args["directive"].toString()
        val data = args["data"]?.toString() ?: ""

        val directiveInt = resolveDirective(directive)
        if (directiveInt == -1) {
            result.error("UNKNOWN_DIRECTIVE", "Unknown directive: $directive", null)
            return
        }

        val ret = engine.sendDirective(directiveInt, data)
        if (ret != SpeechEngineDefines.ERR_NO_ERROR) {
            result.error("DIRECTIVE_FAILED", "sendDirective returned $ret", ret.toString())
        } else {
            result.success(null)
        }
    }

    // ============================================================
    // 6. feedAudio
    // ============================================================
    private fun handleFeedAudio(call: MethodCall, result: Result) {
        val engine = requireEngine(result) ?: return

        val audioData = call.arguments as? ByteArray ?: run {
            result.error("INVALID_AUDIO", "Expected byte array", null)
            return
        }

        val shortBuffer = ByteBuffer.wrap(audioData).asShortBuffer()
        val shortArray = ShortArray(shortBuffer.remaining())
        shortBuffer.get(shortArray)

        val ret = engine.feedAudio(shortArray, shortArray.size)
        result.success(ret)
    }

    // ============================================================
    // stopEngine
    // ============================================================
    private fun handleStopEngine(result: Result) {
        val engine = speechEngine ?: run {
            result.success(null)
            return
        }
        // 异步停止，避免回调线程死锁
        Thread {
            engine.sendDirective(resolveDirective("DIRECTIVE_SYNC_STOP_ENGINE"), "")
            mainHandler.post { result.success(null) }
        }.start()
    }

    // ============================================================
    // destroyEngine
    // ============================================================
    private fun handleDestroyEngine(result: Result) {
        destroyEngineInternal()
        result.success(null)
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
    // SpeechEngine 回调监听器
    // ============================================================
    private val speechListener = object : SpeechEngine.SpeechListener {
        override fun onSpeechMessage(type: Int, data: ByteArray, len: Int) {
            val eventMap = mutableMapOf<String, Any?>()

            when (type) {
                SpeechEngineDefines.MESSAGE_TYPE_ENGINE_START -> {
                    eventMap["type"] = "MESSAGE_TYPE_ENGINE_START"
                    eventMap["text"] = String(data, 0, len)
                }
                SpeechEngineDefines.MESSAGE_TYPE_ENGINE_STOP -> {
                    eventMap["type"] = "MESSAGE_TYPE_ENGINE_STOP"
                    eventMap["text"] = String(data, 0, len)
                }
                SpeechEngineDefines.MESSAGE_TYPE_ENGINE_ERROR -> {
                    eventMap["type"] = "MESSAGE_TYPE_ENGINE_ERROR"
                    eventMap["text"] = String(data, 0, len)
                }
                SpeechEngineDefines.MESSAGE_TYPE_DIALOG_ASR_INFO -> {
                    eventMap["type"] = "MESSAGE_TYPE_DIALOG_ASR_INFO"
                    eventMap["text"] = String(data, 0, len)
                }
                SpeechEngineDefines.MESSAGE_TYPE_DIALOG_ASR_RESPONSE -> {
                    eventMap["type"] = "MESSAGE_TYPE_DIALOG_ASR_RESPONSE"
                    eventMap["text"] = String(data, 0, len)
                }
                SpeechEngineDefines.MESSAGE_TYPE_DIALOG_ASR_ENDED -> {
                    eventMap["type"] = "MESSAGE_TYPE_DIALOG_ASR_ENDED"
                    eventMap["text"] = String(data, 0, len)
                }
                SpeechEngineDefines.MESSAGE_TYPE_DIALOG_CHAT_RESPONSE -> {
                    eventMap["type"] = "MESSAGE_TYPE_DIALOG_CHAT_RESPONSE"
                    eventMap["text"] = String(data, 0, len)
                }
                SpeechEngineDefines.MESSAGE_TYPE_DIALOG_CHAT_ENDED -> {
                    eventMap["type"] = "MESSAGE_TYPE_DIALOG_CHAT_ENDED"
                    eventMap["text"] = String(data, 0, len)
                }
                SpeechEngineDefines.MESSAGE_TYPE_PLAYER_AUDIO_DATA -> {
                    eventMap["type"] = "MESSAGE_TYPE_PLAYER_AUDIO_DATA"
                    eventMap["audio"] = data.copyOf(len)
                }
                SpeechEngineDefines.MESSAGE_TYPE_DECODER_AUDIO_DATA -> {
                    eventMap["type"] = "MESSAGE_TYPE_DECODER_AUDIO_DATA"
                    eventMap["audio"] = data.copyOf(len)
                }
                SpeechEngineDefines.MESSAGE_TYPE_DIALOG_RECORDER_AUDIO -> {
                    eventMap["type"] = "MESSAGE_TYPE_DIALOG_RECORDER_AUDIO"
                    eventMap["audio"] = data.copyOf(len)
                }
                else -> return
            }

            mainHandler.post {
                eventSink?.success(eventMap)
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

    private fun requireEngine(result: Result): SpeechEngine? {
        val engine = speechEngine
        if (engine == null) {
            result.error("ENGINE_NOT_CREATED", "请先调用 createEngine()", null)
        }
        return engine
    }
}
