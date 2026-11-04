package com.arkarizdev.tanukonomy.notificationcapture

import android.app.Notification
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.graphics.drawable.Icon
import android.os.Build
import com.arkarizdev.tanukonomy.R

/**
 * Notifikasi Tanukonomy untuk tangkapan yang diselesaikan mesin tanpa layar
 * (ADR-044 §3.5). Bagi pengguna Plus dengan draf lengkap ada tombol Catat dan
 * Abaikan yang ditangani [CaptureActionReceiver] tanpa membuka aplikasi; yang
 * lain membuka CATAT terisi seperti pengingat biasa ([CaptureReminders]).
 * Dua notifikasi bertombol atau lebih dikelompokkan dengan ringkasan yang
 * punya tombol Catat semua. Semua teks dari [ActionTexts] (bahasa aplikasi).
 */
object CaptureActionable {
    private const val CHANNEL_ID = "notification_capture"
    /** Tag khusus supaya notifikasi bertindak bisa dibersihkan tanpa menyentuh pengingat. */
    const val TAG = "capture_action"
    private const val SUMMARY_TAG = "capture_action_summary"
    private const val SUMMARY_ID = 1
    const val ACTION_RECORD = "com.arkarizdev.tanukonomy.capture.RECORD"
    const val ACTION_DISMISS = "com.arkarizdev.tanukonomy.capture.DISMISS"
    const val ACTION_UNDO = "com.arkarizdev.tanukonomy.capture.UNDO"
    const val ACTION_RECORD_ALL = "com.arkarizdev.tanukonomy.capture.RECORD_ALL"
    const val ACTION_UNDO_ALL = "com.arkarizdev.tanukonomy.capture.UNDO_ALL"
    const val EXTRA_ID = "capture_id"
    const val EXTRA_IDS = "capture_ids"
    private const val RESULT_TIMEOUT_MS = 30_000L

    private fun manager(context: Context) = context.getSystemService(NotificationManager::class.java)

    fun post(context: Context, captureId: String, title: String, body: String, payload: String?, icon: ByteArray?) {
        if (!CaptureReminders.canPost(context)) return
        val config = CaptureConfig.load(context)
        if (payload == null) {
            // Tanpa tombol: ketukan membuka CATAT terisi lewat jalur yang sudah ada.
            CaptureReminders.show(context, captureId, title, body, config.channelName, icon)
            return
        }
        CaptureJournal.put(context, captureId, payload)
        CaptureReminders.ensureChannel(context, config.channelName)
        val texts = config.texts
        val notification = Notification.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(Notification.BigTextStyle().bigText(body))
            .setAutoCancel(false)
            .addAction(action(context, captureId, ACTION_RECORD, texts.record))
            .addAction(action(context, captureId, ACTION_DISMISS, texts.dismiss))
            .apply {
                val bitmap = icon?.let { BitmapFactory.decodeByteArray(it, 0, it.size) }
                if (bitmap != null) setLargeIcon(bitmap)
            }
            .build()
        manager(context).notify(TAG, captureId.hashCode(), notification)
        updateSummary(context)
    }

    private fun action(context: Context, captureId: String, name: String, label: String, ids: List<String>? = null): Notification.Action {
        val intent = Intent(context, CaptureActionReceiver::class.java)
            .setAction(name)
            .putExtra(EXTRA_ID, captureId)
            .apply { if (ids != null) putStringArrayListExtra(EXTRA_IDS, ArrayList(ids)) }
        val pending = PendingIntent.getBroadcast(
            context,
            (name + captureId).hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        return Notification.Action.Builder(Icon.createWithResource(context, R.mipmap.ic_launcher), label, pending)
            .apply {
                // Di layar kunci, Catat meminta perangkat dibuka dulu (API 31+).
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && (name == ACTION_RECORD || name == ACTION_RECORD_ALL)) {
                    setAuthenticationRequired(true)
                }
            }
            .build()
    }

    /** Notifikasi bertombol yang sedang tampil (tanpa ringkasan). */
    private fun active(context: Context) = manager(context).activeNotifications.filter { it.tag == TAG }

    /**
     * Dua notifikasi bertombol atau lebih: satu notifikasi mandiri dengan Catat semua; kurang dari itu, tanpa itu.
     * Sengaja bukan ringkasan grup: Android 7+ tidak menampilkan tombol ringkasan grup.
     */
    private fun updateSummary(context: Context) {
        val count = active(context).size
        if (count < 2) {
            manager(context).cancel(SUMMARY_TAG, SUMMARY_ID)
            return
        }
        val texts = CaptureConfig.load(context).texts
        val notification = Notification.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(texts.groupSummary.replace("{count}", count.toString()))
            .setAutoCancel(false)
            .addAction(action(context, SUMMARY_TAG, ACTION_RECORD_ALL, texts.recordAll))
            .build()
        manager(context).notify(SUMMARY_TAG, SUMMARY_ID, notification)
    }

    /** Hasil Catat: sudah masuk jurnal; Batalkan masih bisa sebelum aplikasi menerapkannya. */
    fun recorded(context: Context, captureId: String) {
        val texts = CaptureConfig.load(context).texts
        val notification = Notification.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(texts.recordedTitle)
            .setContentText(texts.recordedBody)
            .setAutoCancel(true)
            .setTimeoutAfter(RESULT_TIMEOUT_MS)
            .addAction(action(context, captureId, ACTION_UNDO, texts.undo))
            .build()
        manager(context).notify(TAG, captureId.hashCode(), notification)
        updateSummary(context)
    }

    /** Hasil Catat semua: satu notifikasi, Batalkan membatalkan semuanya. */
    fun recordedMany(context: Context, ids: List<String>) {
        val texts = CaptureConfig.load(context).texts
        val notification = Notification.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(texts.recordedMany.replace("{count}", ids.size.toString()))
            .setContentText(texts.recordedBody)
            .setAutoCancel(true)
            .setTimeoutAfter(RESULT_TIMEOUT_MS)
            .addAction(action(context, SUMMARY_TAG, ACTION_UNDO_ALL, texts.undo, ids))
            .build()
        manager(context).notify(SUMMARY_TAG, SUMMARY_ID, notification)
    }

    /** Hasil Batalkan: tangkapannya tetap menunggu di kotak masuk. */
    fun undone(context: Context, captureId: String) {
        val texts = CaptureConfig.load(context).texts
        val notification = Notification.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(texts.undoneTitle)
            .setContentText(texts.undoneBody)
            .setAutoCancel(true)
            .setTimeoutAfter(RESULT_TIMEOUT_MS / 3)
            .build()
        manager(context).notify(TAG, captureId.hashCode(), notification)
        updateSummary(context)
    }

    /** Hasil Batalkan semua. */
    fun undoneMany(context: Context) {
        val texts = CaptureConfig.load(context).texts
        val notification = Notification.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(texts.undoneTitle)
            .setContentText(texts.undoneBody)
            .setAutoCancel(true)
            .setTimeoutAfter(RESULT_TIMEOUT_MS / 3)
            .build()
        manager(context).notify(SUMMARY_TAG, SUMMARY_ID, notification)
    }

    fun cancel(context: Context, captureId: String) {
        manager(context).cancel(TAG, captureId.hashCode())
        updateSummary(context)
    }

    /** Membersihkan semua notifikasi bertindak (aplikasi dibuka: tangkapan kini kartu di kotak masuk). */
    fun cancelAll(context: Context) {
        val manager = manager(context)
        manager.activeNotifications.filter { it.tag == TAG || it.tag == SUMMARY_TAG }.forEach { manager.cancel(it.tag, it.id) }
    }
}
