package com.mustafapolat.zeka_parkuru

import android.media.AudioAttributes
import android.os.Build
import android.os.Bundle
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import android.speech.tts.Voice
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

class MainActivity : FlutterActivity() {
    private data class PendingSpeech(
        val text: String,
        val languageTag: String,
        val result: MethodChannel.Result,
    )

    private var narrator: TextToSpeech? = null
    private var narratorReady = false
    private var speechChannel: MethodChannel? = null
    private var pendingSpeech: PendingSpeech? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setHighRefreshRate()
    }

    override fun onResume() {
        super.onResume()
        setHighRefreshRate()
    }

    override fun onAttachedToWindow() {
        super.onAttachedToWindow()
        setHighRefreshRate()
    }

    private fun setHighRefreshRate() {
        try {
            window.addFlags(WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                display?.let { d ->
                    val modes = d.supportedModes
                    val maxMode = modes.maxByOrNull { it.refreshRate }
                    if (maxMode != null && maxMode.refreshRate >= 60.0f) {
                        val params = window.attributes
                        params.preferredDisplayModeId = maxMode.modeId
                        params.preferredRefreshRate = maxMode.refreshRate
                        window.attributes = params
                    }
                }
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                @Suppress("DEPRECATION")
                val display = windowManager.defaultDisplay
                display?.let { d ->
                    val modes = d.supportedModes
                    val maxMode = modes.maxByOrNull { it.refreshRate }
                    if (maxMode != null && maxMode.refreshRate >= 60.0f) {
                        val params = window.attributes
                        params.preferredDisplayModeId = maxMode.modeId
                        window.attributes = params
                    }
                }
            }
        } catch (_: Exception) {
            // Cihaz kısıtlaması durumunda sessizce devam et
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "zeka_parkuru/reader_speech",
        )
        speechChannel = channel
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "speak" -> speak(call.argument<String>("text"), call.argument<String>("languageTag"), result)
                "stop" -> {
                    pendingSpeech?.result?.error("SPEECH_STOPPED", "Speech was stopped.", null)
                    pendingSpeech = null
                    narrator?.stop()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // Konuşma motoru ilk kareyi geciktirmesin; yalnızca sesli okuma istenince kurulur.
    }

    private fun speak(text: String?, languageTag: String?, result: MethodChannel.Result) {
        val cleanText = text?.trim().orEmpty()
        val cleanLanguage = languageTag?.trim().orEmpty()
        if (cleanText.isEmpty() || cleanLanguage.isEmpty()) {
            result.error("INVALID_SPEECH", "Text and language are required.", null)
            return
        }
        val engine = narrator
        if (!narratorReady || engine == null) {
            pendingSpeech?.result?.error("SPEECH_REPLACED", "A newer speech request replaced this one.", null)
            pendingSpeech = PendingSpeech(cleanText, cleanLanguage, result)
            initializeNarrator()
            return
        }
        speakReady(engine, cleanText, cleanLanguage, result)
    }

    private fun initializeNarrator() {
        if (narrator != null) return
        try {
            narrator = TextToSpeech(applicationContext) { status ->
                runOnUiThread {
                    narratorReady = status == TextToSpeech.SUCCESS
                    val engine = narrator
                    if (narratorReady && engine != null) {
                        engine.setAudioAttributes(
                            AudioAttributes.Builder()
                                .setUsage(AudioAttributes.USAGE_ASSISTANCE_ACCESSIBILITY)
                                .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                                .build(),
                        )
                        engine.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
                            override fun onStart(utteranceId: String?) = Unit

                            override fun onDone(utteranceId: String?) {
                                runOnUiThread { speechChannel?.invokeMethod("finished", utteranceId) }
                            }

                            @Deprecated("Deprecated in Java")
                            override fun onError(utteranceId: String?) {
                                runOnUiThread { speechChannel?.invokeMethod("stopped", utteranceId) }
                            }

                            override fun onError(utteranceId: String?, errorCode: Int) {
                                runOnUiThread { speechChannel?.invokeMethod("stopped", utteranceId) }
                            }

                            override fun onStop(utteranceId: String?, interrupted: Boolean) {
                                runOnUiThread { speechChannel?.invokeMethod("stopped", utteranceId) }
                            }
                        })
                    }
                    val request = pendingSpeech
                    pendingSpeech = null
                    if (request != null) {
                        if (narratorReady && engine != null) {
                            speakReady(engine, request.text, request.languageTag, request.result)
                        } else {
                            request.result.error("NARRATOR_NOT_READY", "Device speech is not available.", null)
                        }
                    }
                    if (!narratorReady) {
                        narrator?.shutdown()
                        narrator = null
                    }
                }
            }
        } catch (_: Exception) {
            pendingSpeech?.result?.error("NARRATOR_NOT_READY", "Device speech is not available.", null)
            pendingSpeech = null
            narrator = null
        }
    }

    private fun speakReady(engine: TextToSpeech, cleanText: String, cleanLanguage: String, result: MethodChannel.Result) {
        val locale = Locale.forLanguageTag(cleanLanguage)
        if (engine.isLanguageAvailable(locale) < TextToSpeech.LANG_AVAILABLE) {
            result.error("VOICE_UNAVAILABLE", "Install a voice for $cleanLanguage in Android settings.", null)
            return
        }
        engine.language = locale
        selectBestOfflineVoice(engine, locale)
        engine.setSpeechRate(0.94f)
        val status = engine.speak(
            cleanText,
            TextToSpeech.QUEUE_FLUSH,
            Bundle(),
            "zp_reader_${System.nanoTime()}",
        )
        if (status == TextToSpeech.ERROR) {
            result.error("SPEECH_FAILED", "The device could not start speech.", null)
        } else {
            result.success(true)
        }
    }

    private fun selectBestOfflineVoice(engine: TextToSpeech, locale: Locale) {
        val candidates = engine.voices.orEmpty().filter { voice ->
            voice.locale.language.equals(locale.language, ignoreCase = true) &&
                !voice.isNetworkConnectionRequired
        }
        if (candidates.isEmpty()) return

        val qualityOrder = compareByDescending<Voice> { it.quality }
            .thenBy { it.latency }
        val sameRegion = candidates.filter { voice ->
            locale.country.isNotEmpty() &&
                voice.locale.country.equals(locale.country, ignoreCase = true)
        }
        val preferred = sameRegion.minWithOrNull(qualityOrder)
            ?: candidates.minWithOrNull(qualityOrder)
        if (preferred != null) engine.voice = preferred
    }

    override fun onDestroy() {
        pendingSpeech?.result?.error("SPEECH_STOPPED", "Speech was stopped.", null)
        pendingSpeech = null
        narrator?.stop()
        narrator?.shutdown()
        narrator = null
        super.onDestroy()
    }
}
