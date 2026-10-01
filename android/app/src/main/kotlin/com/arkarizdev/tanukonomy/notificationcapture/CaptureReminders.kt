package com.arkarizdev.tanukonomy.notificationcapture

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.os.Build
import android.util.Base64
import com.arkarizdev.tanukonomy.MainActivity
import com.arkarizdev.tanukonomy.R

/** Notifikasi Tanukonomy sendiri untuk tangkapan (ADR-032 §3.7). */
object CaptureReminders {
    const val EXTRA_CAPTURE_ID = "notification_capture_id"
    private const val CHANNEL_ID = "notification_capture"

    fun ensureChannel(context: Context, name: String) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        val channel = NotificationChannel(
            CHANNEL_ID,
            name.ifBlank { "Catat dari notifikasi" },
            NotificationManager.IMPORTANCE_DEFAULT,
        )
        manager.createNotificationChannel(channel)
    }

    fun canPost(context: Context): Boolean {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) manager.areNotificationsEnabled() else true
    }

    /** Pengingat generik saat Dart tidak hidup; teksnya dari [CaptureConfig]. */
    fun showGeneric(context: Context, config: CaptureConfig, item: CapturedItem, appLabel: String) {
        val title = config.capturedTitle.replace("{app}", appLabel).ifBlank { appLabel }
        val icon = item.icon?.let { Base64.decode(it, Base64.NO_WRAP) }
        show(context, item.id, title, config.capturedBody, config.channelName, icon)
    }

    /** [icon]: PNG ikon tangkapan (logo bank/merchant), jadi ikon besar. */
    fun show(
        context: Context,
        captureId: String,
        title: String,
        body: String,
        channelName: String = "",
        icon: ByteArray? = null,
    ) {
        if (!canPost(context)) return
        ensureChannel(context, channelName)
        val intent = Intent(context, MainActivity::class.java)
            .putExtra(EXTRA_CAPTURE_ID, captureId)
            .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        val pending = PendingIntent.getActivity(
            context,
            captureId.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        @Suppress("DEPRECATION")
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, CHANNEL_ID)
        } else {
            Notification.Builder(context)
        }
        val notification = builder
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(Notification.BigTextStyle().bigText(body))
            .setContentIntent(pending)
            .setAutoCancel(true)
            .apply {
                val bitmap = icon?.let { BitmapFactory.decodeByteArray(it, 0, it.size) }
                if (bitmap != null) setLargeIcon(bitmap)
            }
            .build()
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(CHANNEL_ID, captureId.hashCode(), notification)
    }
}
