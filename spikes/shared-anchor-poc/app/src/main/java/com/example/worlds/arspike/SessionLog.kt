package com.example.worlds.arspike

import android.content.Context
import android.os.BatteryManager
import android.os.Build
import android.os.Debug
import android.os.PowerManager
import android.os.SystemClock
import org.json.JSONObject
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * One JSON object per line, written to the app's own external files folder
 * (`Android/data/<package>/files/logs`, readable with `adb pull`) and
 * exportable through the share sheet.
 *
 * Privacy (docs/SECURITY_AND_PRIVACY.md): accuracies, states and timings only.
 * The phone's own position is never logged; the only coordinates written are
 * an anchor pose that someone captured or typed, and sites checked for VPS.
 */
class SessionLog(context: Context) {
    private val startElapsedMs = SystemClock.elapsedRealtime()
    val file: File

    init {
        val dir = File(context.getExternalFilesDir(null) ?: context.filesDir, "logs").apply { mkdirs() }
        val stamp = SimpleDateFormat("yyyyMMdd-HHmmss", Locale.US).format(Date())
        file = File(dir, "session-$stamp.jsonl")
    }

    val elapsedMs: Long get() = SystemClock.elapsedRealtime() - startElapsedMs

    @Synchronized
    fun event(name: String, fields: Map<String, Any?> = emptyMap()) {
        val o = JSONObject()
            .put("t_ms", elapsedMs)
            .put("wall", System.currentTimeMillis())
            .put("event", name)
        fields.forEach { (k, v) -> o.put(k, v ?: JSONObject.NULL) }
        file.appendText(o.toString() + "\n")
    }

    fun text(): String = if (file.exists()) file.readText() else ""
}

/** Frame time, memory, battery and thermal samples for the PoC's performance columns. */
class Metrics(private val context: Context, private val log: SessionLog) {
    private var windowStartNs = 0L
    private var lastFrameNs = 0L
    private var frames = 0
    private var worstFrameNs = 0L

    var fps: Double = 0.0
        private set

    /** Call once per AR frame with the frame's camera timestamp. */
    fun onFrame(timestampNs: Long) {
        if (timestampNs <= 0 || timestampNs == lastFrameNs) return
        if (lastFrameNs != 0L) worstFrameNs = maxOf(worstFrameNs, timestampNs - lastFrameNs)
        lastFrameNs = timestampNs
        if (windowStartNs == 0L) windowStartNs = timestampNs
        frames++
        val windowNs = timestampNs - windowStartNs
        if (windowNs >= WINDOW_NS) {
            fps = frames * 1e9 / windowNs
            sample(windowNs)
            windowStartNs = timestampNs
            frames = 0
            worstFrameNs = 0
        }
    }

    private fun sample(windowNs: Long) {
        val runtime = Runtime.getRuntime()
        val battery = context.getSystemService(BatteryManager::class.java)
        val thermal = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            context.getSystemService(PowerManager::class.java)?.currentThermalStatus
        } else {
            null
        }
        log.event(
            "metrics",
            mapOf(
                "window_s" to windowNs / 1e9,
                "camera_fps" to "%.1f".format(Locale.US, fps).toDouble(),
                "worst_frame_ms" to worstFrameNs / 1e6,
                "java_heap_mb" to (runtime.totalMemory() - runtime.freeMemory()) / 1_048_576.0,
                "native_heap_mb" to Debug.getNativeHeapAllocatedSize() / 1_048_576.0,
                "battery_pct" to battery?.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY),
                "thermal_status" to thermal,
            ),
        )
    }

    private companion object {
        const val WINDOW_NS = 5_000_000_000L
    }
}
