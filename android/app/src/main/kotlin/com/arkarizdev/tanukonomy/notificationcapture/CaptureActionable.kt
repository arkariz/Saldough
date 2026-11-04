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
 * SPIKE T-26.9: notifikasi Tanukonomy dengan tombol Catat dan Abaikan yang
 * ditangani [CaptureActionReceiver] tanpa membuka aplikasi.
 */
object CaptureActionable {
    private const val CHANNEL_ID = "notification_capture"
    const val ACTION_RECORD = "com.arkarizdev.tanukonomy.capture.RECORD"
    const val ACTION_DISMISS = "com.arkarizdev.tanukonomy.capture.DISMISS"
    const val EXTRA_ID = "capture_id"

    fun post(context: Context, captureId: String, title: String, body: String) {
        if (!CaptureReminders.canPost(context)) return
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
        context.getSystemService(NotificationManager::class.java).notify(CHANNEL_ID, captureId.hashCode(), notification)
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

    /** Ganti notifikasi dengan hasil keputusan (tanpa tombol). */
    fun result(context: Context, captureId: String, text: String) {
        val notification = Notification.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(text)
            .setAutoCancel(true)
            .setTimeoutAfter(15_000)
            .build()
        context.getSystemService(NotificationManager::class.java).notify(CHANNEL_ID, captureId.hashCode(), notification)
    }
}
