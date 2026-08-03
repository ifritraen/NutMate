package com.raen.nutmate

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    companion object {
        private const val CHANNEL = "com.raen.nutmate/widget_update"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {

        super.configureFlutterEngine(flutterEngine)

        // Schedule default 5-min widget updates on startup
        WidgetScheduler.scheduleUpdates(this, 5)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "setUpdateInterval") {
                val interval = call.argument<Int>("intervalMinutes") ?: 5
                WidgetScheduler.scheduleUpdates(this, interval)
                WidgetHelper.updateAllWidgets(this)
                result.success(true)
            } else if (call.method == "refreshWidgets") {
                WidgetHelper.updateAllWidgets(this)
                result.success(true)
            } else {
                result.notImplemented()
            }
        }
    }
}
