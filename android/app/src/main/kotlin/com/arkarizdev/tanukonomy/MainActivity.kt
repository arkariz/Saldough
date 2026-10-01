package com.arkarizdev.tanukonomy

import android.content.Intent
import android.content.pm.PackageManager
import com.arkarizdev.tanukonomy.notificationcapture.NotificationCapturePlugin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var notificationCapture: NotificationCapturePlugin? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Catat dari notifikasi (ADR-032).
        notificationCapture = NotificationCapturePlugin(this).also {
            it.attach(flutterEngine.dartExecutor.binaryMessenger)
            it.handleIntent(intent, launch = true)
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        notificationCapture?.detach()
        notificationCapture = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        notificationCapture?.handleIntent(intent, launch = false)
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == NotificationCapturePlugin.PERMISSION_REQUEST) {
            notificationCapture?.onPermissionResult(
                grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED,
            )
        }
    }
}
