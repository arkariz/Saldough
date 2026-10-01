package com.arkarizdev.tanukonomy.notificationcapture

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/** Satu notifikasi yang ditampung, belum ditafsirkan. */
data class CapturedItem(
    val id: String,
    val packageName: String,
    val title: String,
    val body: String,
    val postedAt: Long,
    /** Ikon tangkapan, Base64 PNG ([NotificationIcons]). */
    val icon: String? = null,
) {
    fun toJson(): JSONObject = JSONObject()
        .put("id", id)
        .put("packageName", packageName)
        .put("title", title)
        .put("body", body)
        .put("postedAt", postedAt)
        .apply { if (icon != null) put("icon", icon) }

    fun toMap(): Map<String, Any?> = mapOf(
        "id" to id,
        "packageName" to packageName,
        "title" to title,
        "body" to body,
        "postedAt" to postedAt,
        "icon" to icon,
    )

    companion object {
        fun fromJson(json: JSONObject) = CapturedItem(
            id = json.getString("id"),
            packageName = json.getString("packageName"),
            title = json.optString("title"),
            body = json.optString("body"),
            postedAt = json.getLong("postedAt"),
            icon = json.optString("icon").takeIf { it.isNotEmpty() },
        )
    }
}

/**
 * Antrean serah-terima native → Dart (ADR-032 §3.1), di SharedPreferences
 * milik aplikasi. Dart membaca, memproses, lalu meng-ack. Maks. [MAX_ITEMS];
 * isi yang sama (paket + teks) dalam [DEDUP_WINDOW_MS] diabaikan, termasuk
 * yang sudah di-ack (notifikasi yang diperbarui sering diposting ulang).
 *
 * [debugSamples] hanya terisi di build debug: teks mentah dari paket terdaftar
 * sebelum saringan kata kunci, untuk menyusun pola dari sampel asli.
 */
object CaptureQueue {
    private const val PREFS = "notification_capture_queue"
    private const val KEY_ITEMS = "items"
    private const val KEY_SEEN = "seen"
    private const val KEY_DEBUG = "debug"
    private const val MAX_ITEMS = 50
    private const val MAX_DEBUG = 20
    private const val DEDUP_WINDOW_MS = 2L * 24 * 60 * 60 * 1000

    private fun prefs(context: Context) = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private fun read(context: Context, key: String): JSONArray =
        try { JSONArray(prefs(context).getString(key, "[]")) } catch (e: Exception) { JSONArray() }

    /** Menambah [item]; `false` bila isinya sudah pernah ditampung. */
    @Synchronized
    fun add(context: Context, item: CapturedItem): Boolean {
        val now = System.currentTimeMillis()
        val fingerprint = "${item.packageName}|${item.title}|${item.body}".hashCode().toString()
        val seen = read(context, KEY_SEEN)
        val keptSeen = JSONArray()
        var duplicate = false
        for (i in 0 until seen.length()) {
            val entry = seen.getJSONObject(i)
            if (now - entry.getLong("at") > DEDUP_WINDOW_MS) continue
            if (entry.getString("fp") == fingerprint) duplicate = true
            keptSeen.put(entry)
        }
        if (duplicate) return false
        keptSeen.put(JSONObject().put("fp", fingerprint).put("at", now))

        val items = read(context, KEY_ITEMS)
        val kept = JSONArray()
        val start = maxOf(0, items.length() - (MAX_ITEMS - 1))
        for (i in start until items.length()) kept.put(items.getJSONObject(i))
        kept.put(item.toJson())
        prefs(context).edit()
            .putString(KEY_ITEMS, kept.toString())
            .putString(KEY_SEEN, trimTail(keptSeen, 200).toString())
            .apply()
        return true
    }

    @Synchronized
    fun pending(context: Context): List<CapturedItem> {
        val items = read(context, KEY_ITEMS)
        return (0 until items.length()).mapNotNull {
            try { CapturedItem.fromJson(items.getJSONObject(it)) } catch (e: Exception) { null }
        }
    }

    @Synchronized
    fun acknowledge(context: Context, ids: Collection<String>) {
        val items = read(context, KEY_ITEMS)
        val kept = JSONArray()
        for (i in 0 until items.length()) {
            val item = items.getJSONObject(i)
            if (item.optString("id") !in ids) kept.put(item)
        }
        prefs(context).edit().putString(KEY_ITEMS, kept.toString()).apply()
    }

    @Synchronized
    fun addDebugSample(context: Context, item: CapturedItem) {
        val samples = read(context, KEY_DEBUG)
        // Sampel hanya untuk menyusun pola: tanpa ikon.
        samples.put(item.copy(icon = null).toJson())
        prefs(context).edit().putString(KEY_DEBUG, trimTail(samples, MAX_DEBUG).toString()).apply()
    }

    @Synchronized
    fun debugSamples(context: Context): List<CapturedItem> {
        val samples = read(context, KEY_DEBUG)
        return (0 until samples.length()).map { CapturedItem.fromJson(samples.getJSONObject(it)) }.reversed()
    }

    private fun trimTail(array: JSONArray, max: Int): JSONArray {
        val out = JSONArray()
        for (i in maxOf(0, array.length() - max) until array.length()) out.put(array.get(i))
        return out
    }
}
