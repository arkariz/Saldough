package com.arkarizdev.tanukonomy.notificationcapture

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/**
 * Setelan yang dikirim Dart (ADR-032 §3.1): sumber aktif + kata kunci,
 * mode pengingat, dan teks pengingat dalam bahasa aplikasi (ADR-028).
 * Native tidak menafsirkan apa pun dan tidak menyentuh Hive.
 */
data class CaptureSource(val packageName: String, val label: String, val keywords: List<String>) {
    fun matchesKeywords(text: String): Boolean {
        // Whitelist (ADR-032 §3.1): tanpa filter, tidak ada yang ditangkap.
        val usable = keywords.map { it.trim() }.filter { it.isNotEmpty() }
        val lower = text.lowercase()
        return usable.any { lower.contains(it.lowercase()) }
    }
}

/** Teks notifikasi bertindak; `{count}` diganti jumlah. Kosong = bawaan Kotlin tidak ada, jadi Dart wajib mengisi. */
data class ActionTexts(
    val record: String = "",
    val dismiss: String = "",
    val undo: String = "",
    val recordedTitle: String = "",
    val recordedBody: String = "",
    val undoneTitle: String = "",
    val undoneBody: String = "",
    val groupSummary: String = "",
    val recordAll: String = "",
    val recordedMany: String = "",
)

data class CaptureConfig(
    val enabled: Boolean,
    val sources: List<CaptureSource>,
    val remindWhenClosed: Boolean,
    val channelName: String,
    val capturedTitle: String,
    val capturedBody: String,
    /** ADR-042 §3.2: simpan contoh notifikasi sumber terdaftar (bawaan mati). */
    val saveSamples: Boolean = false,
    /** ADR-044 §3.5: bawaan; notifikasi menyala hanya bila paket Plus ([CapturePlan]). */
    val autoNotify: Boolean = false,
    /** Teks notifikasi bertindak dalam bahasa aplikasi (dari Dart; native tidak tahu bahasanya). */
    val texts: ActionTexts = ActionTexts(),
) {
    /** Notifikasi saat aplikasi tertutup: dipilih pengguna, atau bawaan untuk Plus. */
    fun notifies(context: Context): Boolean = remindWhenClosed || (autoNotify && CapturePlan.isPlus(context))

    fun source(packageName: String): CaptureSource? = sources.firstOrNull { it.packageName == packageName }

    fun save(context: Context) {
        val json = JSONObject()
            .put("enabled", enabled)
            .put("remindWhenClosed", remindWhenClosed)
            .put("channelName", channelName)
            .put("capturedTitle", capturedTitle)
            .put("capturedBody", capturedBody)
            .put("saveSamples", saveSamples)
            .put("autoNotify", autoNotify)
            .put(
                "texts",
                JSONObject()
                    .put("record", texts.record).put("dismiss", texts.dismiss).put("undo", texts.undo)
                    .put("recordedTitle", texts.recordedTitle).put("recordedBody", texts.recordedBody)
                    .put("undoneTitle", texts.undoneTitle).put("undoneBody", texts.undoneBody)
                    .put("groupSummary", texts.groupSummary).put("recordAll", texts.recordAll)
                    .put("recordedMany", texts.recordedMany),
            )
            .put(
                "sources",
                JSONArray(sources.map {
                    JSONObject()
                        .put("packageName", it.packageName)
                        .put("label", it.label)
                        .put("keywords", JSONArray(it.keywords))
                }),
            )
        prefs(context).edit().putString(KEY, json.toString()).apply()
    }

    companion object {
        private const val PREFS = "notification_capture_config"
        private const val KEY = "config"

        private fun prefs(context: Context) = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

        val disabled = CaptureConfig(false, emptyList(), false, "", "", "")

        fun load(context: Context): CaptureConfig {
            val raw = prefs(context).getString(KEY, null) ?: return disabled
            return try {
                val json = JSONObject(raw)
                val sources = json.optJSONArray("sources") ?: JSONArray()
                CaptureConfig(
                    enabled = json.optBoolean("enabled"),
                    remindWhenClosed = json.optBoolean("remindWhenClosed"),
                    channelName = json.optString("channelName"),
                    capturedTitle = json.optString("capturedTitle"),
                    capturedBody = json.optString("capturedBody"),
                    saveSamples = json.optBoolean("saveSamples"),
                    autoNotify = json.optBoolean("autoNotify"),
                    texts = json.optJSONObject("texts")?.let {
                        ActionTexts(
                            record = it.optString("record"), dismiss = it.optString("dismiss"), undo = it.optString("undo"),
                            recordedTitle = it.optString("recordedTitle"), recordedBody = it.optString("recordedBody"),
                            undoneTitle = it.optString("undoneTitle"), undoneBody = it.optString("undoneBody"),
                            groupSummary = it.optString("groupSummary"), recordAll = it.optString("recordAll"),
                            recordedMany = it.optString("recordedMany"),
                        )
                    } ?: ActionTexts(),
                    sources = (0 until sources.length()).map { i ->
                        val s = sources.getJSONObject(i)
                        val keywords = s.optJSONArray("keywords") ?: JSONArray()
                        CaptureSource(
                            packageName = s.getString("packageName"),
                            label = s.optString("label", s.getString("packageName")),
                            keywords = (0 until keywords.length()).map { keywords.getString(it) },
                        )
                    },
                )
            } catch (e: Exception) {
                disabled
            }
        }
    }
}
