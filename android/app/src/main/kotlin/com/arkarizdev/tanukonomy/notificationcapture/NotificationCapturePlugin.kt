package com.arkarizdev.tanukonomy.notificationcapture

import android.Manifest
import android.app.Activity
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

/**
 * Kanal Flutter Catat dari notifikasi (ADR-032): metode
 * `tanukonomy/notification_capture`, event `.../captured` (tangkapan baru
 * selagi mesin hidup) dan `.../taps` (ketukan pengingat).
 */
class NotificationCapturePlugin(private val activity: Activity) : MethodChannel.MethodCallHandler {
    private val context: Context = activity.applicationContext
    private val main = Handler(Looper.getMainLooper())
    private val io = Executors.newSingleThreadExecutor()
    private var methods: MethodChannel? = null
    private var capturedEvents: EventChannel? = null
    private var tapEvents: EventChannel? = null
    private var pendingPermission: MethodChannel.Result? = null
    private var launchTap: String? = null

    fun attach(messenger: BinaryMessenger) {
        methods = MethodChannel(messenger, CHANNEL).also { it.setMethodCallHandler(this) }
        capturedEvents = EventChannel(messenger, "$CHANNEL/captured").also {
            it.setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    capturedSink = events
                }

                override fun onCancel(arguments: Any?) {
                    capturedSink = null
                }
            })
        }
        tapEvents = EventChannel(messenger, "$CHANNEL/taps").also {
            it.setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    tapSink = events
                }

                override fun onCancel(arguments: Any?) {
                    tapSink = null
                }
            })
        }
    }

    fun detach() {
        methods?.setMethodCallHandler(null)
        capturedEvents?.setStreamHandler(null)
        tapEvents?.setStreamHandler(null)
        capturedSink = null
        tapSink = null
        io.shutdown()
    }

    /** Ketukan pengingat dari intent [MainActivity]. */
    fun handleIntent(intent: Intent?, launch: Boolean) {
        val id = intent?.getStringExtra(CaptureReminders.EXTRA_CAPTURE_ID) ?: return
        intent.removeExtra(CaptureReminders.EXTRA_CAPTURE_ID)
        val sink = tapSink
        if (launch || sink == null) launchTap = id else sink.success(id)
    }

    fun onPermissionResult(granted: Boolean) {
        pendingPermission?.success(granted)
        pendingPermission = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isAccessGranted" -> result.success(isAccessGranted())
            "openAccessSettings" -> {
                activity.startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
                result.success(null)
            }
            "canPostReminders" -> result.success(canPostReminders())
            "requestReminderPermission" -> requestReminderPermission(result)
            "configure" -> {
                configure(call)
                result.success(null)
            }
            "pending" -> io.execute {
                val items = try { CaptureQueue.pendingMaps(context) } catch (e: Exception) { null }
                main.post {
                    if (items == null) result.error("pending", "Gagal membaca antrean", null) else result.success(items)
                }
            }
            "acknowledge" -> {
                CaptureQueue.acknowledge(context, call.argument<List<String>>("ids").orEmpty())
                result.success(null)
            }
            "takeLaunchReminderTap" -> {
                result.success(launchTap)
                launchTap = null
            }
            "showReminder" -> {
                CaptureReminders.show(
                    context,
                    call.argument<String>("captureId").orEmpty(),
                    call.argument<String>("title").orEmpty(),
                    call.argument<String>("body").orEmpty(),
                    CaptureConfig.load(context).channelName,
                    call.argument<ByteArray>("icon"),
                )
                result.success(null)
            }
            "installedApps" -> io.execute {
                val apps = try { installedApps() } catch (e: Exception) { null }
                main.post {
                    if (apps == null) result.error("installed_apps", "Gagal membaca aplikasi", null) else result.success(apps)
                }
            }
            "debugSamples" -> result.success(CaptureQueue.debugSamples(context).map { it.toMap() })
            else -> result.notImplemented()
        }
    }

    private fun isAccessGranted(): Boolean {
        val flat = Settings.Secure.getString(context.contentResolver, "enabled_notification_listeners") ?: return false
        val component = ComponentName(context, TransactionNotificationListener::class.java)
        return flat.split(":").any { ComponentName.unflattenFromString(it) == component }
    }

    private fun canPostReminders(): Boolean {
        if (Build.VERSION.SDK_INT >= 33 &&
            context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) {
            return false
        }
        return CaptureReminders.canPost(context)
    }

    private fun requestReminderPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < 33 || canPostReminders()) {
            result.success(canPostReminders())
            return
        }
        pendingPermission?.success(false)
        pendingPermission = result
        activity.requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), PERMISSION_REQUEST)
    }

    private fun configure(call: MethodCall) {
        val sources = call.argument<List<Map<String, Any?>>>("sources").orEmpty().map {
            CaptureSource(
                packageName = it["packageName"] as String,
                label = it["label"] as? String ?: it["packageName"] as String,
                keywords = (it["keywords"] as? List<*>)?.filterIsInstance<String>().orEmpty(),
            )
        }
        val config = CaptureConfig(
            enabled = call.argument<Boolean>("enabled") ?: false,
            sources = sources,
            remindWhenClosed = call.argument<Boolean>("remindWhenClosed") ?: false,
            channelName = call.argument<String>("channelName").orEmpty(),
            capturedTitle = call.argument<String>("capturedTitle").orEmpty(),
            capturedBody = call.argument<String>("capturedBody").orEmpty(),
        )
        config.save(context)
        CaptureReminders.ensureChannel(context, config.channelName)
    }

    private fun installedApps(): List<Map<String, Any?>> {
        val pm = context.packageManager
        val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        @Suppress("DEPRECATION")
        val activities = pm.queryIntentActivities(intent, 0)
        return activities
            .filter { it.activityInfo.packageName != context.packageName }
            .distinctBy { it.activityInfo.packageName }
            .map {
                mapOf(
                    "packageName" to it.activityInfo.packageName,
                    "label" to it.loadLabel(pm).toString(),
                    "icon" to NotificationIcons.render(it.loadIcon(pm)),
                )
            }
            .sortedBy { (it["label"] as String).lowercase() }
    }

    companion object {
        const val CHANNEL = "tanukonomy/notification_capture"
        const val PERMISSION_REQUEST = 4721

        @Volatile private var capturedSink: EventChannel.EventSink? = null
        @Volatile private var tapSink: EventChannel.EventSink? = null

        /**
         * Memberi tahu Dart ada tangkapan baru. `false` bila tidak ada mesin
         * Flutter yang mendengarkan (layanan lalu memunculkan pengingat generik).
         */
        fun notifyCaptured(): Boolean {
            val sink = capturedSink ?: return false
            Handler(Looper.getMainLooper()).post { capturedSink?.success(null) }
            return sink === capturedSink
        }
    }
}
