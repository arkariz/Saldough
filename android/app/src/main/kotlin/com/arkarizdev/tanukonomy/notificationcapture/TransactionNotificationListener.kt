package com.arkarizdev.tanukonomy.notificationcapture

import android.app.Notification
import android.content.ComponentName
import android.content.pm.ApplicationInfo
import android.os.Build
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

/**
 * Penangkap native Catat dari notifikasi (ADR-032 §3.1). Berjalan walau
 * aplikasi tertutup; hanya menampung notifikasi dari sumber yang dipilih
 * pengguna, tidak pernah OTP, lalu meneruskannya ke Dart bila hidup atau
 * memunculkan pengingat generik.
 */
class TransactionNotificationListener : NotificationListenerService() {

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        try {
            handle(sbn)
        } catch (e: Exception) {
            // Satu notifikasi rusak tidak boleh menghentikan layanan.
        }
    }

    private fun handle(sbn: StatusBarNotification) {
        if (sbn.packageName == packageName) return
        val config = CaptureConfig.load(this)
        if (!config.enabled) return
        val source = config.source(sbn.packageName) ?: return
        val notification = sbn.notification ?: return
        if (sbn.isOngoing || notification.flags and Notification.FLAG_GROUP_SUMMARY != 0) return

        val extras = notification.extras ?: return
        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString().orEmpty()
        val lines = extras.getCharSequenceArray(Notification.EXTRA_TEXT_LINES)?.joinToString("\n")
        val body = (extras.getCharSequence(Notification.EXTRA_BIG_TEXT)
            ?: extras.getCharSequence(Notification.EXTRA_TEXT))?.toString()
            ?: lines.orEmpty()
        val text = "$title\n$body"
        val item = CapturedItem(
            id = "${sbn.postTime}-${(sbn.key + body).hashCode()}",
            packageName = sbn.packageName,
            title = title,
            body = body,
            postedAt = sbn.postTime,
        )

        if (applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE != 0 && !looksLikeOtp(text)) {
            CaptureQueue.addDebugSample(this, item)
        }
        if (text.none { it.isDigit() } || looksLikeOtp(text) || !source.matchesKeywords(text)) return
        val captured = item.copy(icon = NotificationIcons.forNotification(this, sbn))
        if (!CaptureQueue.add(this, captured)) return

        if (!NotificationCapturePlugin.notifyCaptured() && config.remindWhenClosed) {
            CaptureReminders.showGeneric(this, config, captured, source.label)
        }
    }

    override fun onListenerDisconnected() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            requestRebind(ComponentName(this, TransactionNotificationListener::class.java))
        }
    }

    companion object {
        /** Sama dengan `NotificationText.otpWords` di Dart. */
        private val OTP_WORDS = listOf(
            "otp",
            "kode verifikasi",
            "kode rahasia",
            "kode aktivasi",
            "one time password",
            "one-time password",
            "verification code",
            "security code",
            "jangan berikan",
            "jangan bagikan",
            "do not share",
        )

        fun looksLikeOtp(text: String): Boolean {
            val lower = text.lowercase()
            return OTP_WORDS.any { lower.contains(it) }
        }
    }
}
