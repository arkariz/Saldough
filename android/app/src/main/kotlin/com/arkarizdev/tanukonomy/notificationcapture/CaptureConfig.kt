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

data class CaptureConfig(
    val enabled: Boolean,
    val sources: List<CaptureSource>,
    val remindWhenClosed: Boolean,
    val channelName: String,
    val capturedTitle: String,
    val capturedBody: String,
) {
    fun source(packageName: String): CaptureSource? = sources.firstOrNull { it.packageName == packageName }

    fun save(context: Context) {
        val json = JSONObject()
            .put("enabled", enabled)
            .put("remindWhenClosed", remindWhenClosed)
            .put("channelName", channelName)
            .put("capturedTitle", capturedTitle)
            .put("capturedBody", capturedBody)
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
