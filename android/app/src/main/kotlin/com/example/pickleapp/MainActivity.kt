package com.example.pickleapp

import android.app.Activity
import android.app.ActivityManager
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.annotation.NonNull
import androidx.annotation.RequiresApi
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.flutter_app/foreground"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)

        // Register method channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "keepAppInForeground") {
                keepAppInForeground()
                result.success(null)
            } else if (call.method == "releaseForegroundLock") {
                releaseForegroundLock()
                result.success(null)
            } else{
                result.notImplemented()
            }
        }
    }

    // Method to keep the app in foreground
    private fun keepAppInForeground() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            val packageName = packageName

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val recentTasks = activityManager.appTasks
                for (task in recentTasks) {
                    if (task.taskInfo.baseIntent.component?.packageName == packageName) {
                        task.moveToFront()
                        break
                    }
                }
            } else {
                val intent = packageManager.getLaunchIntentForPackage(packageName)
                startActivity(intent)
            }
        }
    }

    private fun releaseForegroundLock() {
        stopLockTask()
    }
}
