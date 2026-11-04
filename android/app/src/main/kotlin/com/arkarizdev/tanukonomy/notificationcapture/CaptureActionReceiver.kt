package com.arkarizdev.tanukonomy.notificationcapture

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Tombol notifikasi bertindak (ADR-044 §3.5): Catat, Abaikan, dan Batalkan.
 * Menulis keputusan ke [CaptureJournal] (aplikasi menerapkannya ke Hive saat
 * dibuka) dan mengganti notifikasinya dengan hasilnya.
 */
class CaptureActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getStringExtra(CaptureActionable.EXTRA_ID) ?: return
        val decision = when (intent.action) {
            CaptureActionable.ACTION_RECORD -> "record"
            CaptureActionable.ACTION_DISMISS -> "dismiss"
            CaptureActionable.ACTION_UNDO -> null
            else -> return
        }
        // Entri sudah diterapkan aplikasi: tombol basi, tidak melakukan apa pun.
        if (!CaptureJournal.decide(context, id, decision)) {
            Log.i(CaptureWorker.TAG, "tombol ${intent.action} untuk $id diabaikan: entri sudah diterapkan")
            CaptureActionable.cancel(context, id)
            return
        }
        Log.i(CaptureWorker.TAG, "keputusan ${decision ?: "batal"} untuk $id ditulis ke jurnal")
        when (decision) {
            "record" -> CaptureActionable.recorded(context, id)
            "dismiss" -> CaptureActionable.cancel(context, id)
            else -> CaptureActionable.undone(context, id)
        }
    }
}
