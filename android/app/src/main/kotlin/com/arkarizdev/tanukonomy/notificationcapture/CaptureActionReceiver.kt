package com.arkarizdev.tanukonomy.notificationcapture

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject

/**
 * SPIKE T-26.9: tombol notifikasi bertindak. Menulis keputusan ke
 * [CaptureJournal] (satu-satunya yang ditulis native; aplikasi menerapkannya
 * ke Hive saat dibuka) dan mengganti notifikasinya dengan hasilnya.
 */
class CaptureActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getStringExtra(CaptureActionable.EXTRA_ID) ?: return
        val decision = when (intent.action) {
            CaptureActionable.ACTION_RECORD -> "record"
            CaptureActionable.ACTION_DISMISS -> "dismiss"
            else -> return
        }
        CaptureJournal.append(context, id, decision)
        Log.i(CaptureWorker.TAG, "tombol $decision untuk $id ditulis ke jurnal; entri sekarang ${CaptureJournal.size(context)}")
        CaptureActionable.result(
            context,
            id,
            if (decision == "record") "Tercatat (menunggu diterapkan saat aplikasi dibuka)" else "Diabaikan",
        )
    }
}

/** SPIKE T-26.9: jurnal keputusan tombol, di SharedPreferences native. */
object CaptureJournal {
    private const val PREFS = "capture_journal"
    private const val KEY = "entries"

    private fun prefs(context: Context) = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    @Synchronized
    fun append(context: Context, captureId: String, decision: String) {
        val array = JSONArray(prefs(context).getString(KEY, "[]"))
        array.put(JSONObject().put("captureId", captureId).put("decision", decision).put("at", System.currentTimeMillis()))
        prefs(context).edit().putString(KEY, array.toString()).apply()
    }

    fun size(context: Context): Int = JSONArray(prefs(context).getString(KEY, "[]")).length()
}
