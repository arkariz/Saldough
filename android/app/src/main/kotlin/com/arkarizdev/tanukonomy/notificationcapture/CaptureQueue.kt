package com.arkarizdev.tanukonomy.notificationcapture

import android.content.Context
import java.io.File
import org.json.JSONArray
import org.json.JSONObject

/** Satu notifikasi yang ditampung, belum ditafsirkan. Ikonnya berkas terpisah ([CaptureQueue]). */
data class CapturedItem(
    val id: String,
    val packageName: String,
    val title: String,
    val body: String,
    val postedAt: Long,
) {
    fun toJson(): JSONObject = JSONObject()
        .put("id", id)
        .put("packageName", packageName)
        .put("title", title)
        .put("body", body)
        .put("postedAt", postedAt)

    /** Untuk kanal Flutter; [icon] PNG dikirim sebagai bytes. */
    fun toMap(icon: ByteArray? = null): Map<String, Any?> = mapOf(
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
        )
    }
}

/**
 * Antrean serah-terima native → Dart (ADR-032 §3.1, §10), di SharedPreferences
 * milik aplikasi. Dart membaca, memproses, lalu meng-ack. Maks. [MAX_ITEMS].
 *
 * Dedup hanya untuk notifikasi yang diposting ulang (ADR-032 §10): kunci +
 * waktu notifikasi + isi yang sama dalam [DEDUP_WINDOW_MS], atau kunci + isi
 * yang sama dalam [REPOST_WINDOW_MS] (notifikasi yang dibangun ulang mendapat
 * waktu baru). Kemiripan lain diputuskan Dart, yang tidak pernah membuang.
 *
 * Ikon disimpan sebagai berkas PNG per tangkapan di [ICON_DIR] supaya antrean
 * JSON tetap kecil; berkasnya dihapus saat tangkapannya di-ack atau tergusur.
 *
 * [debugSamples] hanya terisi di build debug: teks mentah dari paket terdaftar
 * sebelum saringan kata kunci, untuk menyusun pola dari sampel asli.
 */
object CaptureQueue {
    private const val PREFS = "notification_capture_queue"
    private const val KEY_ITEMS = "items"
    private const val KEY_SEEN = "seen"
    private const val KEY_DEBUG = "debug"
    private const val ICON_DIR = "notification_capture_icons"
    private const val MAX_ITEMS = 50
    private const val MAX_DEBUG = 20
    private const val DEDUP_WINDOW_MS = 60L * 60 * 1000
    private const val REPOST_WINDOW_MS = 2L * 60 * 1000

    private fun prefs(context: Context) = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private fun read(context: Context, key: String): JSONArray =
        try { JSONArray(prefs(context).getString(key, "[]")) } catch (e: Exception) { JSONArray() }

    private fun iconFile(context: Context, id: String) = File(File(context.filesDir, ICON_DIR), "$id.png")

    /**
     * Menambah [item] (notifikasi [key] bertanggal [postedWhen]) beserta
     * [icon]; `false` bila ia posting ulang notifikasi yang sudah ditampung.
     */
    @Synchronized
    fun add(context: Context, item: CapturedItem, key: String, postedWhen: Long, icon: ByteArray?): Boolean {
        val now = System.currentTimeMillis()
        val content = "$key|${item.title}|${item.body}".hashCode().toString()
        val exact = "$key|$postedWhen|${item.title}|${item.body}".hashCode().toString()
        val seen = read(context, KEY_SEEN)
        val keptSeen = JSONArray()
        var duplicate = false
        for (i in 0 until seen.length()) {
            val entry = seen.getJSONObject(i)
            val age = now - entry.getLong("at")
            if (age > DEDUP_WINDOW_MS) continue
            if (entry.optString("fp") == exact) duplicate = true
            if (entry.optString("content") == content && age <= REPOST_WINDOW_MS) duplicate = true
            keptSeen.put(entry)
        }
        if (duplicate) return false
        keptSeen.put(JSONObject().put("fp", exact).put("content", content).put("at", now))

        if (icon != null) {
            try {
                iconFile(context, item.id).apply { parentFile?.mkdirs() }.writeBytes(icon)
            } catch (e: Exception) {
                // Tanpa ikon tetap ditampung.
            }
        }
        val items = read(context, KEY_ITEMS)
        val kept = JSONArray()
        val start = maxOf(0, items.length() - (MAX_ITEMS - 1))
        for (i in 0 until items.length()) {
            val existing = items.getJSONObject(i)
            if (i >= start) kept.put(existing) else iconFile(context, existing.optString("id")).delete()
        }
        kept.put(item.toJson())
        prefs(context).edit()
            .putString(KEY_ITEMS, kept.toString())
            .putString(KEY_SEEN, trimTail(keptSeen, 200).toString())
            .apply()
        return true
    }

    /** Antrean untuk kanal Flutter, dengan ikon tiap tangkapan (bila ada). */
    @Synchronized
    fun pendingMaps(context: Context): List<Map<String, Any?>> = pending(context).map { item ->
        val file = iconFile(context, item.id)
        val icon = try { if (file.exists()) file.readBytes() else null } catch (e: Exception) { null }
        item.toMap(icon)
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
        for (id in ids) iconFile(context, id).delete()
        prefs(context).edit().putString(KEY_ITEMS, kept.toString()).apply()
    }

    @Synchronized
    fun addDebugSample(context: Context, item: CapturedItem) {
        val samples = read(context, KEY_DEBUG)
        samples.put(item.toJson())
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
