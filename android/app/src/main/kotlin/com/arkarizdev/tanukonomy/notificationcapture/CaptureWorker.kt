package com.arkarizdev.tanukonomy.notificationcapture

import android.content.Context
import android.content.pm.ApplicationInfo
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
 * Mesin Dart tanpa layar untuk Catat dari notifikasi (ADR-044 §3.5, spike
 * T-26.9, T-26.10). Dinyalakan layanan pendengar saat mesin aplikasi tidak
 * hidup: Dart membaca antrean ([pending]), membaca Hive (hanya baca), memakai
 * penentu yang sama dengan aplikasi, lalu memasang notifikasi dengan tombol
 * Catat/Abaikan. Keputusan ditulis ke [CaptureJournal]; aplikasi yang
 * menerapkannya ke Hive saat dibuka.
 *
 * Satu mesin menguras seluruh antrean: Dart melaporkan id yang sudah
 * ditangani lewat `done`; bila ada tangkapan baru yang belum ditangani
 * (datang saat mesin berjalan), mesin dinyalakan lagi.
 *
 * Hanya jalan di build yang bisa di-debug dan berkas `files/capture_worker_spike`
 * ada, sampai pengujian perangkat nyata selesai (ADR-044 revisi 2).
 */
object CaptureWorker {
    const val TAG = "CaptureSpike"
    private const val CHANNEL = "tanukonomy/capture_worker"
    private const val LIBRARY = "package:saldough/app/capture_worker/capture_worker_main.dart"
    private const val ENTRYPOINT = "captureWorkerMain"
    private const val WATCHDOG_MS = 30_000L
    private const val MAX_ROUNDS = 5

    private val main = Handler(Looper.getMainLooper())
    @Volatile private var running = false
    private var engine: FlutterEngine? = null
    private var startedAt = 0L
    private var watchdog: Runnable? = null
    private var rounds = 0

    /** Id yang sudah ditangani mesin di proses ini (diposting, dilewati, atau tak terbaca). */
    private val handled = mutableSetOf<String>()

    /** `true` bila pekerjaan diterima (sudah berjalan atau baru dimulai). */
    fun run(context: Context): Boolean {
        if (running) {
            Log.i(TAG, "mesin tanpa layar sedang berjalan; tangkapan baru ikut dikuras")
            return true
        }
        running = true
        rounds = 0
        val app = context.applicationContext
        pendingContext = app
        // Id yang sudah tidak ada di antrean (di-ack aplikasi) tidak perlu diingat lagi.
        val queued = CaptureQueue.pending(app).map { it.id }.toSet()
        handled.retainAll(queued)
        main.post { start(app) }
        return true
    }

    private fun start(app: Context) {
        startedAt = SystemClock.elapsedRealtime()
        rounds++
        Log.i(TAG, "mulai mesin tanpa layar (putaran $rounds)")
        try {
            val engine = FlutterEngine(app)
            this.engine = engine
            Log.i(TAG, "FlutterEngine dibuat +${elapsed()}ms")
            MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
                when (call.method) {
                    // Antrean yang belum ditangani; tangkapan sudah disaring layanan pendengar.
                    "pending" -> result.success(
                        CaptureQueue.pendingMaps(app).filter { it["id"] !in handled },
                    )
                    // Id yang sudah punya entri jurnal (diposting mesin sebelumnya).
                    "journalIds" -> result.success(CaptureJournal.entries(app).map { it["id"] })
                    "plan" -> result.success(mapOf("isPlus" to CapturePlan.isPlus(app)))
                    // Uji tumpang tindih (hanya build debug): tahan Hive terbuka sekian ms (berkas `capture_worker_hold`).
                    "hold" -> result.success(
                        if (app.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE == 0) {
                            0
                        } else {
                            File(app.filesDir, "capture_worker_hold").takeIf { it.exists() }
                                ?.readText()?.trim()?.toIntOrNull() ?: 0
                        },
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
                            args["payload"] as String?,
                            args["icon"] as ByteArray?,
                        )
                        Log.i(TAG, "notifikasi dipasang +${elapsed()}ms")
                        result.success(null)
                    }
                    "done" -> {
                        @Suppress("UNCHECKED_CAST")
                        handled.addAll((call.arguments as? List<String>).orEmpty())
                        result.success(null)
                        shutdown("selesai", restartIfPending = true)
                    }
                    else -> result.notImplemented()
                }
            }
            val bundle = FlutterInjector.instance().flutterLoader().findAppBundlePath()
            engine.dartExecutor.executeDartEntrypoint(DartExecutor.DartEntrypoint(bundle, LIBRARY, ENTRYPOINT))
            // Satu watchdog per jalan; dibatalkan di shutdown supaya tidak mematikan mesin berikutnya.
            val guard = Runnable { if (running) shutdown("watchdog ${WATCHDOG_MS}ms", restartIfPending = false) }
            watchdog = guard
            main.postDelayed(guard, WATCHDOG_MS)
        } catch (e: Throwable) {
            Log.e(TAG, "mesin tanpa layar gagal dinyalakan", e)
            shutdown("galat", restartIfPending = false)
        }
    }

    private fun shutdown(reason: String, restartIfPending: Boolean) {
        main.post {
            watchdog?.let { main.removeCallbacks(it) }
            watchdog = null
            engine?.destroy()
            engine = null
            Log.i(TAG, "mesin tanpa layar dimatikan ($reason) +${elapsed()}ms")
            val app = pendingContext
            val more = restartIfPending && rounds < MAX_ROUNDS && app != null &&
                CaptureQueue.pending(app).any { it.id !in handled }
            if (more && app != null) {
                Log.i(TAG, "ada tangkapan baru yang belum ditangani; menyalakan lagi")
                start(app)
            } else {
                running = false
                if (app != null) fallbackForUnhandled(app)
            }
        }
    }

    @Volatile private var pendingContext: Context? = null

    /**
     * Mesin gagal menyala atau berhenti sebelum menangani semuanya: tangkapan
     * yang tersisa mendapat pengingat generik seperti sebelum mesin tanpa layar,
     * supaya tidak ada yang diam (ADR-044 §3.5).
     */
    private fun fallbackForUnhandled(app: Context) {
        val config = CaptureConfig.load(app)
        if (!config.notifies(app)) return
        val leftover = CaptureQueue.pending(app).filter { it.id !in handled }
        if (leftover.isEmpty()) return
        Log.w(TAG, "${leftover.size} tangkapan belum ditangani mesin; pengingat generik")
        leftover.forEach {
            CaptureReminders.showGeneric(app, config, it, config.source(it.packageName)?.label ?: it.packageName, null)
            handled.add(it.id)
        }
    }

    private fun elapsed() = SystemClock.elapsedRealtime() - startedAt
}
