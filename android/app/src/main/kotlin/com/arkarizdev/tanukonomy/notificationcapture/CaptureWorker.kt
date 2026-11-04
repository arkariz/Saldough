package com.arkarizdev.tanukonomy.notificationcapture

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * SPIKE T-26.9 (ADR-044 §3.5): menyalakan mesin Dart tanpa layar dari layanan
 * pendengar saat mesin aplikasi tidak hidup, supaya penentu Dart yang sama
 * menyelesaikan tangkapan dan notifikasi bertombol bisa dipasang tanpa membuka
 * aplikasi. Mesin tanpa layar hanya membaca Hive; keputusan pengguna masuk ke
 * jurnal native ([CaptureJournal]).
 *
 * Bukan implementasi akhir. Hanya jalan di build debug yang berkas
 * `files/capture_worker_spike` ada, jadi tidak mengubah perilaku normal.
 */
object CaptureWorker {
    const val TAG = "CaptureSpike"
    private const val CHANNEL = "tanukonomy/capture_worker"
    private const val LIBRARY = "package:saldough/app/capture_worker/capture_worker_main.dart"
    private const val ENTRYPOINT = "captureWorkerMain"
    private const val WATCHDOG_MS = 30_000L

    private val main = Handler(Looper.getMainLooper())
    @Volatile private var running = false
    private var engine: FlutterEngine? = null
    private var startedAt = 0L
    private var watchdog: Runnable? = null

    fun enabled(context: Context): Boolean = File(context.filesDir, "capture_worker_spike").exists()

    /** `true` bila pekerjaan diterima (sudah berjalan atau baru dimulai). */
    fun run(context: Context, item: CapturedItem, appLabel: String): Boolean {
        if (running) {
            Log.i(TAG, "mesin tanpa layar sedang berjalan; ${item.id} menunggu di antrean")
            return true
        }
        running = true
        val app = context.applicationContext
        main.post { start(app, item, appLabel) }
        return true
    }

    private fun start(app: Context, item: CapturedItem, appLabel: String) {
        startedAt = SystemClock.elapsedRealtime()
        Log.i(TAG, "mulai mesin tanpa layar untuk ${item.id}")
        try {
            val engine = FlutterEngine(app)
            this.engine = engine
            Log.i(TAG, "FlutterEngine dibuat +${elapsed()}ms")
            MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
                when (call.method) {
                    "job" -> result.success(
                        mapOf(
                            "captureId" to item.id,
                            "packageName" to item.packageName,
                            "appLabel" to appLabel,
                            "title" to item.title,
                            "body" to item.body,
                            "postedAt" to item.postedAt,
                            // Uji tumpang tindih: tahan Hive terbuka sekian ms (berkas `capture_worker_hold`).
                            "holdMs" to (File(app.filesDir, "capture_worker_hold").takeIf { it.exists() }
                                ?.readText()?.trim()?.toIntOrNull() ?: 0),
                        ),
                    )
                    "log" -> {
                        Log.i(TAG, "dart: ${call.arguments} (total +${elapsed()}ms)")
                        result.success(null)
                    }
                    "postActionable" -> {
                        val args = call.arguments as Map<*, *>
                        CaptureActionable.post(
                            app,
                            args["captureId"] as String,
                            args["title"] as String,
                            args["body"] as String,
                        )
                        Log.i(TAG, "notifikasi bertombol dipasang +${elapsed()}ms")
                        result.success(null)
                    }
                    "done" -> {
                        result.success(null)
                        shutdown("selesai")
                    }
                    else -> result.notImplemented()
                }
            }
            val bundle = FlutterInjector.instance().flutterLoader().findAppBundlePath()
            engine.dartExecutor.executeDartEntrypoint(DartExecutor.DartEntrypoint(bundle, LIBRARY, ENTRYPOINT))
            // Satu watchdog per jalan; dibatalkan di shutdown supaya tidak mematikan mesin berikutnya.
            val guard = Runnable { if (running) shutdown("watchdog ${WATCHDOG_MS}ms") }
            watchdog = guard
            main.postDelayed(guard, WATCHDOG_MS)
        } catch (e: Throwable) {
            Log.e(TAG, "mesin tanpa layar gagal dinyalakan", e)
            shutdown("galat")
        }
    }

    private fun shutdown(reason: String) {
        main.post {
            watchdog?.let { main.removeCallbacks(it) }
            watchdog = null
            engine?.destroy()
            engine = null
            running = false
            Log.i(TAG, "mesin tanpa layar dimatikan ($reason) +${elapsed()}ms")
        }
    }

    private fun elapsed() = SystemClock.elapsedRealtime() - startedAt
}
