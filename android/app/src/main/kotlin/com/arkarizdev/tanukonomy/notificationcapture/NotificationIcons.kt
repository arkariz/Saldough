package com.arkarizdev.tanukonomy.notificationcapture

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.Drawable
import android.service.notification.StatusBarNotification
import java.io.ByteArrayOutputStream

/** Ikon PNG kecil untuk daftar aplikasi dan tangkapan (ADR-032 §3.1). */
object NotificationIcons {
    private const val SIZE_PX = 96

    /**
     * Ikon tangkapan, PNG: ikon besar notifikasi (logo bank atau merchant),
     * atau ikon aplikasi pengirim bila tidak ada. `null` bila keduanya gagal
     * dibaca.
     */
    fun forNotification(context: Context, sbn: StatusBarNotification): ByteArray? {
        val drawable = try {
            sbn.notification?.getLargeIcon()?.loadDrawable(context)
        } catch (e: Exception) {
            null
        } ?: try {
            context.packageManager.getApplicationIcon(sbn.packageName)
        } catch (e: Exception) {
            null
        } ?: return null
        return render(drawable)
    }

    /** [drawable] dirender persegi [SIZE_PX], tetap proporsional dan di tengah. */
    fun render(drawable: Drawable): ByteArray? = try {
        val bitmap = Bitmap.createBitmap(SIZE_PX, SIZE_PX, Bitmap.Config.ARGB_8888)
        val width = drawable.intrinsicWidth
        val height = drawable.intrinsicHeight
        if (width > 0 && height > 0 && width != height) {
            val scale = SIZE_PX.toFloat() / maxOf(width, height)
            val w = (width * scale).toInt()
            val h = (height * scale).toInt()
            val left = (SIZE_PX - w) / 2
            val top = (SIZE_PX - h) / 2
            drawable.setBounds(left, top, left + w, top + h)
        } else {
            drawable.setBounds(0, 0, SIZE_PX, SIZE_PX)
        }
        drawable.draw(Canvas(bitmap))
        ByteArrayOutputStream().use { out ->
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
            out.toByteArray()
        }
    } catch (e: Exception) {
        null
    }
}
