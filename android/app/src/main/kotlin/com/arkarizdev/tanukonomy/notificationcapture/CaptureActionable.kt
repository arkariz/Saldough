package com.arkarizdev.tanukonomy.notificationcapture

import android.app.Notification
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.drawable.Icon
import android.os.Build
import com.arkarizdev.tanukonomy.R

/**
 * Notifikasi Tanukonomy untuk tangkapan yang diselesaikan mesin tanpa layar
 * (ADR-044 §3.5). Bagi pengguna Plus dengan draf lengkap ada tombol Catat dan
 * Abaikan yang ditangani [CaptureActionReceiver] tanpa membuka aplikasi; yang
 * lain membuka CATAT terisi seperti pengingat biasa ([CaptureReminders]).
 */
object CaptureActionable {
    private const val CHANNEL_ID = "notification_capture"
    /** Tag khusus supaya notifikasi bertindak bisa dibersihkan tanpa menyentuh pengingat. */
    const val TAG = "capture_action"
    const val ACTION_RECORD = "com.arkarizdev.tanukonomy.capture.RECORD"
    const val ACTION_DISMISS = "com.arkarizdev.tanukonomy.capture.DISMISS"
    const val ACTION_UNDO = "com.arkarizdev.tanukonomy.capture.UNDO"
    const val EXTRA_ID = "capture_id"
    private const val RESULT_TIMEOUT_MS = 30_000L

    private fun manager(context: Context) = context.getSystemService(NotificationManager::class.java)

    fun post(context: Context, captureId: String, title: String, body: String, payload: String?) {
        if (!CaptureReminders.canPost(context)) return
        if (payload == null) {
            // Tanpa tombol: ketukan membuka CATAT terisi lewat jalur yang sudah ada.
            CaptureReminders.show(context, captureId, title, body)
            return
        }
        CaptureJournal.put(context, captureId, payload)
        CaptureReminders.ensureChannel(context, "")
        val notification = Notification.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(Notification.BigTextStyle().bigText(body))
            .setAutoCancel(false)
            .addAction(action(context, captureId, ACTION_RECORD, "Catat"))
            .addAction(action(context, captureId, ACTION_DISMISS, "Abaikan"))
            .build()
        manager(context).notify(TAG, captureId.hashCode(), notification)
    }

    private fun action(context: Context, captureId: String, name: String, label: String): Notification.Action {
        val intent = Intent(context, CaptureActionReceiver::class.java)
            .setAction(name)
            .putExtra(EXTRA_ID, captureId)
        val pending = PendingIntent.getBroadcast(
            context,
            (name + captureId).hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        return Notification.Action.Builder(Icon.createWithResource(context, R.mipmap.ic_launcher), label, pending)
            .apply {
                // Di layar kunci, Catat meminta perangkat dibuka dulu (API 31+).
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && name == ACTION_RECORD) setAuthenticationRequired(true)
            }
            .build()
    }

    /** Hasil Catat: sudah masuk jurnal; Batalkan masih bisa sebelum aplikasi menerapkannya. */
    fun recorded(context: Context, captureId: String) {
        val notification = Notification.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("Tercatat")
            .setContentText("Masuk ke catatanmu saat aplikasi dibuka.")
            .setAutoCancel(true)
            .setTimeoutAfter(RESULT_TIMEOUT_MS)
            .addAction(action(context, captureId, ACTION_UNDO, "Batalkan"))
            .build()
        manager(context).notify(TAG, captureId.hashCode(), notification)
    }

    /** Hasil Batalkan: tangkapannya tetap menunggu di kotak masuk. */
    fun undone(context: Context, captureId: String) {
        val notification = Notification.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("Dibatalkan")
            .setContentText("Menunggu di kotak masuk.")
            .setAutoCancel(true)
            .setTimeoutAfter(RESULT_TIMEOUT_MS / 3)
            .build()
        manager(context).notify(TAG, captureId.hashCode(), notification)
    }

    fun cancel(context: Context, captureId: String) = manager(context).cancel(TAG, captureId.hashCode())

    /** Membersihkan semua notifikasi bertindak (aplikasi dibuka: tangkapan kini kartu di kotak masuk). */
    fun cancelAll(context: Context) {
        val manager = manager(context)
        manager.activeNotifications.filter { it.tag == TAG }.forEach { manager.cancel(it.tag, it.id) }
    }
}
