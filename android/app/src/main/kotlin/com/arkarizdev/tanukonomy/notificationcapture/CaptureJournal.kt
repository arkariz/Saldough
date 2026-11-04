package com.arkarizdev.tanukonomy.notificationcapture

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/**
 * Jurnal keputusan notifikasi bertindak (ADR-044 §3.5, T-26.10).
 *
 * Mesin Dart tanpa layar hanya membaca Hive, jadi apa yang dilihat pengguna
 * ("Rp25.000 · Kopi · BCA") dan keputusannya (Catat, Abaikan) ditampung di
 * sini, di native. Aplikasi menerapkannya ke Hive saat dibuka lewat
 * `ApplyCaptureJournal`; sesudah itu entrinya dibuang ([ack]).
 *
 * Satu entri per id tangkapan: `id`, `resolvedAt`, `decision` (`null` bila
 * belum ada keputusan, `record`, atau `dismiss`), `decidedAt`, dan `payload`
 * (JSON draf yang sudah diselesaikan, dibuat Dart). Native tidak menafsirkan
 * isinya. Entri lebih dari 7 hari dibuang, selaras retensi tangkapan.
 */
object CaptureJournal {
    private const val PREFS = "capture_journal"
    private const val KEY = "entries"
    private const val RETENTION_MS = 7L * 24 * 60 * 60 * 1000

    private fun prefs(context: Context) = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private fun read(context: Context): JSONArray {
        val raw = prefs(context).getString(KEY, null) ?: return JSONArray()
        return try {
            JSONArray(raw)
        } catch (e: Exception) {
            JSONArray()
        }
    }

    private fun write(context: Context, array: JSONArray) {
        // commit(), bukan apply(): keputusan tidak boleh hilang bila proses dimatikan sesudahnya.
        prefs(context).edit().putString(KEY, array.toString()).commit()
    }

    private fun fresh(array: JSONArray, now: Long): JSONArray {
        val kept = JSONArray()
        for (i in 0 until array.length()) {
            val item = array.getJSONObject(i)
            if (now - item.optLong("resolvedAt") <= RETENTION_MS) kept.put(item)
        }
        return kept
    }

    /** Menambah entri yang menunggu keputusan; id yang sudah ada diganti (tetap sekali per tangkapan). */
    @Synchronized
    fun put(context: Context, id: String, payload: String, now: Long = System.currentTimeMillis()) {
        val kept = JSONArray()
        val current = fresh(read(context), now)
        for (i in 0 until current.length()) {
            val item = current.getJSONObject(i)
            if (item.optString("id") != id) kept.put(item)
        }
        kept.put(JSONObject().put("id", id).put("resolvedAt", now).put("payload", payload))
        write(context, kept)
    }

    /**
     * Mencatat keputusan [decision] (`record`, `dismiss`, atau `null` untuk
     * membatalkannya). `false` bila entrinya tidak ada (sudah diterapkan aplikasi).
     */
    @Synchronized
    fun decide(context: Context, id: String, decision: String?, now: Long = System.currentTimeMillis()): Boolean {
        val array = read(context)
        var found = false
        for (i in 0 until array.length()) {
            val item = array.getJSONObject(i)
            if (item.optString("id") != id) continue
            found = true
            if (decision == null) {
                item.remove("decision")
                item.remove("decidedAt")
            } else {
                item.put("decision", decision)
                item.put("decidedAt", now)
            }
        }
        if (found) write(context, array)
        return found
    }

    /** Memutuskan [decision] untuk semua entri yang belum diputuskan; mengembalikan id-nya. */
    @Synchronized
    fun decideAll(context: Context, decision: String, now: Long = System.currentTimeMillis()): List<String> {
        val array = read(context)
        val decided = mutableListOf<String>()
        for (i in 0 until array.length()) {
            val item = array.getJSONObject(i)
            if (item.has("decision")) continue
            item.put("decision", decision)
            item.put("decidedAt", now)
            decided.add(item.getString("id"))
        }
        if (decided.isNotEmpty()) write(context, array)
        return decided
    }

    /** Membatalkan keputusan semua [ids] (Batalkan semua). */
    @Synchronized
    fun undecideAll(context: Context, ids: Collection<String>) {
        val array = read(context)
        for (i in 0 until array.length()) {
            val item = array.getJSONObject(i)
            if (item.optString("id") in ids) {
                item.remove("decision")
                item.remove("decidedAt")
            }
        }
        write(context, array)
    }

    /** Entri untuk Dart. */
    @Synchronized
    fun entries(context: Context, now: Long = System.currentTimeMillis()): List<Map<String, Any?>> {
        val array = fresh(read(context), now)
        return (0 until array.length()).map { i ->
            val item = array.getJSONObject(i)
            mapOf(
                "id" to item.getString("id"),
                "resolvedAt" to item.optLong("resolvedAt"),
                "decision" to item.optString("decision").ifEmpty { null },
                "decidedAt" to if (item.has("decidedAt")) item.optLong("decidedAt") else null,
                "payload" to item.optString("payload"),
            )
        }
    }

    /**
     * `true` bila salah satu entri [ids] cocok dengan kemunculan rutin (muatan
     * memuat `match`): keputusannya mengubah pengingat rutin (T-26.12).
     */
    @Synchronized
    fun touchesPlan(context: Context, ids: Collection<String>): Boolean {
        val array = read(context)
        for (i in 0 until array.length()) {
            val item = array.getJSONObject(i)
            if (item.optString("id") in ids && item.optString("payload").contains("\"match\"")) return true
        }
        return false
    }

    /** Membuang entri yang sudah diterapkan. */
    @Synchronized
    fun ack(context: Context, ids: Collection<String>) {
        val array = read(context)
        val kept = JSONArray()
        for (i in 0 until array.length()) {
            val item = array.getJSONObject(i)
            if (item.optString("id") !in ids) kept.put(item)
        }
        write(context, kept)
    }

    @Synchronized
    fun size(context: Context): Int = read(context).length()
}

/**
 * Status Plus untuk mesin tanpa layar (T-26.10): Dart menulisnya tiap hak
 * berubah; mesin tanpa layar tidak punya `ActivePlan`, jadi membaca salinan
 * ini. Tanpa batas akhir, salinan dianggap basi setelah 14 hari (tidak
 * diketahui = Gratis, jadi tombol Catat tidak muncul).
 */
object CapturePlan {
    private const val PREFS = "capture_plan"
    private const val STALE_MS = 14L * 24 * 60 * 60 * 1000

    private fun prefs(context: Context) = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun set(context: Context, isPlus: Boolean, untilMs: Long?, now: Long = System.currentTimeMillis()) {
        prefs(context).edit()
            .putBoolean("isPlus", isPlus)
            .putLong("until", untilMs ?: 0L)
            .putLong("setAt", now)
            .commit()
    }

    fun isPlus(context: Context, now: Long = System.currentTimeMillis()): Boolean {
        val p = prefs(context)
        if (!p.getBoolean("isPlus", false)) return false
        val until = p.getLong("until", 0L)
        return if (until > 0L) now <= until else now - p.getLong("setAt", 0L) <= STALE_MS
    }
}
