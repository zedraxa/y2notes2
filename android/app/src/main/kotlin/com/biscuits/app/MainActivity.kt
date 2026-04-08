package com.biscuits.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val PEN_METHOD_CHANNEL = "com.biscuits/android_pen"
        private const val PEN_EVENT_CHANNEL = "com.biscuits/android_pen/buttons"
        private const val PENCIL_METHOD_CHANNEL = "com.biscuits/pencil"
        private const val PENCIL_EVENT_CHANNEL = "com.biscuits/pencil/gestures"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Android stylus / M-Pencil method channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PEN_METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getPenInfo" -> {
                        // Detect stylus capabilities via InputDevice API
                        val penInfo = detectStylusInfo()
                        result.success(penInfo)
                    }
                    else -> result.notImplemented()
                }
            }

        // Pen button events stream
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, PEN_EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    // Register MotionEvent listener for stylus button events
                }

                override fun onCancel(arguments: Any?) {
                    // Unregister listener
                }
            })

        // Apple Pencil stub — no-op on Android
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PENCIL_METHOD_CHANNEL)
            .setMethodCallHandler { _, result -> result.success(null) }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, PENCIL_EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {}
                override fun onCancel(arguments: Any?) {}
            })
    }

    /**
     * Detect connected stylus capabilities using Android InputDevice API.
     * Returns a Map with stylus type, connection status, and capabilities.
     */
    private fun detectStylusInfo(): Map<String, Any?>? {
        val inputDevices = android.view.InputDevice.getDeviceIds()
        for (id in inputDevices) {
            val device = android.view.InputDevice.getDevice(id) ?: continue
            val sources = device.sources

            // Check for stylus source
            if (sources and android.view.InputDevice.SOURCE_STYLUS != 0) {
                val type = when {
                    device.name.contains("S Pen", ignoreCase = true) -> "samsungSPen"
                    device.name.contains("Wacom", ignoreCase = true) -> "wacomEmr"
                    device.name.contains("USI", ignoreCase = true) -> "usiPen"
                    else -> "generic"
                }

                // Check for pressure support
                val motionRanges = device.motionRanges
                var pressureLevels: Int? = null
                for (range in motionRanges) {
                    if (range.axis == android.view.MotionEvent.AXIS_PRESSURE) {
                        // Estimate discrete levels from range
                        pressureLevels = ((range.max - range.min) / range.resolution).toInt()
                            .coerceAtLeast(256)
                    }
                }

                return mapOf(
                    "type" to type,
                    "connected" to true,
                    "battery" to null, // Battery info requires vendor-specific APIs
                    "pressureLevels" to pressureLevels
                )
            }
        }
        return null
    }
}
