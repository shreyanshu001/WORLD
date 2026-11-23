package com.example.worlds.arspike

import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.google.android.filament.Engine
import com.google.ar.core.Anchor
import com.google.ar.core.Config
import com.google.ar.core.Earth
import com.google.ar.core.Frame
import com.google.ar.core.Plane
import com.google.ar.core.Session
import com.google.ar.core.TrackingFailureReason
import com.google.ar.core.TrackingState
import io.github.sceneview.ar.ARSceneView
import io.github.sceneview.ar.node.AnchorNode
import io.github.sceneview.loaders.MaterialLoader
import io.github.sceneview.loaders.ModelLoader
import io.github.sceneview.node.ModelNode
import io.github.sceneview.node.Node
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

enum class AnchorKind { TERRAIN, WGS84 }

/** What the overlay shows. Updated a few times a second, not every frame. */
data class Hud(
    val state: SpikeState = SpikeState.CHECKING,
    val earthState: String = "-",
    val horizontalM: Double? = null,
    val verticalM: Double? = null,
    val yawDeg: Double? = null,
    val headingDeg: Double? = null,
    val fps: Double = 0.0,
    val anchor: String = "none",
    val contentShown: Boolean = false,
)

/**
 * Owns the spike's AR logic: Earth state, the quality gate, capturing a pose,
 * rebuilding an anchor from a stored pose, and the measurement log.
 * It never sends anything to a backend; poses move between phones as files.
 */
class SpikeController(
    private val context: Context,
    val log: SessionLog,
    private val engine: Engine,
    private val materialLoader: MaterialLoader,
    private val modelLoader: ModelLoader,
    private val childNodes: MutableList<Node>,
) {
    private val main = Handler(Looper.getMainLooper())
    private val metrics = Metrics(context, log)
    val gate = QualityGate()

    var view: ARSceneView? = null
    private var session: Session? = null
    private var frame: Frame? = null
    private var geospatialSupported = true

    var hud by mutableStateOf(Hud())
        private set
    var message by mutableStateOf<String?>(null)
    var pose by mutableStateOf<AnchorPose?>(null)
    var thresholds by mutableStateOf(gate.thresholds)
        private set

    private var anchorNode: AnchorNode? = null
    private var anchorKind: AnchorKind? = null
    private var anchorStatus = AnchorStatus.NONE
    private var resolveStartMs = 0L
    private var lastEarthState: Earth.EarthState? = null
    private var lastState: SpikeState? = null
    private var lastContentShown = false
    private var firstLocalizedLogged = false
    private var lastHudMs = 0L

    val modelFile: File get() = File(context.filesDir, "models/scene.glb")
    val posesDir: File get() = File(context.getExternalFilesDir(null) ?: context.filesDir, "poses")

    fun configure(session: Session, config: Config) {
        geospatialSupported = session.isGeospatialModeSupported(Config.GeospatialMode.ENABLED)
        config.geospatialMode =
            if (geospatialSupported) Config.GeospatialMode.ENABLED else Config.GeospatialMode.DISABLED
        config.planeFindingMode = Config.PlaneFindingMode.HORIZONTAL
    }

    fun onSessionCreated(session: Session) {
        this.session = session
        log.event("session_created", mapOf("geospatial_supported" to geospatialSupported))
        if (!geospatialSupported) message = "This phone's ARCore does not support Geospatial."
    }

    fun onSessionResumed(session: Session) = log.event("session_resumed")
    fun onSessionPaused(session: Session) = log.event("session_paused")

    fun onSessionFailed(e: Exception) {
        log.event("session_failed", mapOf("error" to e.javaClass.simpleName, "detail" to e.message))
        message = "AR session failed: ${e.javaClass.simpleName}"
    }

    fun onTrackingFailure(reason: TrackingFailureReason?) {
        log.event("camera_tracking_failure", mapOf("reason" to reason?.name))
    }

    fun onFrame(session: Session, frame: Frame) {
        this.frame = frame
        metrics.onFrame(frame.timestamp)
        val earth = session.earth
        val earthState = earth?.earthState
        if (earthState != lastEarthState) {
            log.event("earth_state", mapOf("state" to earthState?.name))
            lastEarthState = earthState
        }
        val earthTracking = earth?.trackingState == TrackingState.TRACKING
        val cameraPose = if (earthTracking) earth?.cameraGeospatialPose else null
        val cameraEus = cameraPose?.eastUpSouthQuaternion?.let {
            Quat(it[0].toDouble(), it[1].toDouble(), it[2].toDouble(), it[3].toDouble())
        }
        val anchor = anchorNode?.anchor
        val out = gate.update(
            GateInput(
                earthError = !geospatialSupported ||
                    (earthState != null && earthState != Earth.EarthState.ENABLED),
                cameraTracking = frame.camera.trackingState == TrackingState.TRACKING,
                earthTracking = earthTracking,
                horizontalAccuracyM = cameraPose?.horizontalAccuracy,
                yawAccuracyDeg = cameraPose?.orientationYawAccuracy,
                anchor = anchorStatus,
                anchorTracking = anchor?.trackingState == TrackingState.TRACKING,
            ),
        )
        anchorNode?.isVisible = out.showContent

        if (out.localized && !firstLocalizedLogged && cameraPose != null) {
            firstLocalizedLogged = true
            log.event("first_localized", mapOf(
                "horizontal_m" to cameraPose.horizontalAccuracy,
                "vertical_m" to cameraPose.verticalAccuracy,
                "yaw_deg" to cameraPose.orientationYawAccuracy,
            ))
        }
        if (out.state != lastState) {
            log.event("state", mapOf(
                "state" to out.state.name,
                "horizontal_m" to cameraPose?.horizontalAccuracy,
                "yaw_deg" to cameraPose?.orientationYawAccuracy,
            ))
            lastState = out.state
        }
        if (out.showContent != lastContentShown) {
            log.event(if (out.showContent) "content_shown" else "content_hidden")
            lastContentShown = out.showContent
        }

        val now = log.elapsedMs
        if (now - lastHudMs >= 250) {
            lastHudMs = now
            hud = Hud(
                state = out.state,
                earthState = earthState?.name ?: if (geospatialSupported) "starting" else "UNSUPPORTED",
                horizontalM = cameraPose?.horizontalAccuracy,
                verticalM = cameraPose?.verticalAccuracy,
                yawDeg = cameraPose?.orientationYawAccuracy,
                headingDeg = cameraEus?.let { GeoMath.headingDeg(it) },
                fps = metrics.fps,
                anchor = describeAnchor(anchor),
                contentShown = out.showContent,
            )
        }
    }

    /**
     * Captures the ground point under the cross-hair as a shared pose, facing
     * back towards the person capturing, and places it here as a WGS84 anchor.
     */
    fun capture() {
        val earth = session?.earth
        val f = frame
        val v = view
        if (earth == null || f == null || v == null || !gate.localized) {
            message = "Not localized yet. Wait for TRACKING accuracy before capturing."
            return
        }
        val hit = f.hitTest(v.width / 2f, v.height / 2f).firstOrNull { h ->
            val plane = h.trackable as? Plane
            plane != null && plane.type == Plane.Type.HORIZONTAL_UPWARD_FACING &&
                plane.isPoseInPolygon(h.hitPose)
        }
        if (hit == null) {
            message = "No ground under the cross. Move slowly until the grid covers the mark."
            return
        }
        val markPose = earth.getGeospatialPose(hit.hitPose)
        val camera = earth.cameraGeospatialPose
        val q = camera.eastUpSouthQuaternion
        val facing = GeoMath.yawFacingCamera(
            Quat(q[0].toDouble(), q[1].toDouble(), q[2].toDouble(), q[3].toDouble()),
        )
        val captured = AnchorPose(
            label = "Capture " + SimpleDateFormat("HH:mm:ss", Locale.US).format(Date()),
            latitude = markPose.latitude,
            longitude = markPose.longitude,
            altitudeWgs84M = markPose.altitude,
            altitudeAboveTerrainM = 0.0,
            eusQuaternion = facing,
            source = PoseSource.ON_SITE_CAPTURE,
            capturedAtEpochMs = System.currentTimeMillis(),
            capturedBy = "${Build.MANUFACTURER} ${Build.MODEL}",
            captureAccuracy = CaptureAccuracy(
                horizontalM = markPose.horizontalAccuracy,
                verticalM = markPose.verticalAccuracy,
                yawDeg = camera.orientationYawAccuracy,
            ),
        )
        pose = captured
        val saved = savePose(captured)
        log.event("capture", mapOf("pose" to org.json.JSONObject(captured.toJson()), "file" to saved.name))
        message = "Captured and saved as ${saved.name}. Placed here as WGS84."
        resolve(AnchorKind.WGS84)
    }

    /** Rebuilds the anchor from [pose] with the chosen anchor type. */
    fun resolve(kind: AnchorKind) {
        val p = pose ?: run { message = "Import or capture a pose first."; return }
        val earth = session?.earth
        if (earth == null || earth.trackingState != TrackingState.TRACKING) {
            message = "Earth is not tracking yet."
            return
        }
        clearAnchor(logIt = false)
        anchorKind = kind
        resolveStartMs = log.elapsedMs
        val q = p.eusQuaternion
        log.event("resolve_start", mapOf("kind" to kind.name, "label" to p.label, "source" to p.source.wire))
        when (kind) {
            AnchorKind.WGS84 -> {
                val altitude = p.altitudeWgs84M ?: run {
                    message = "This pose has no altitude (typed from a map). Use Terrain."
                    anchorKind = null
                    return
                }
                val anchor = earth.createAnchor(
                    p.latitude, p.longitude, altitude,
                    q.x.toFloat(), q.y.toFloat(), q.z.toFloat(), q.w.toFloat(),
                )
                attach(anchor)
                log.event("resolve_done", mapOf("kind" to kind.name, "result" to "CREATED", "ms" to 0))
            }
            AnchorKind.TERRAIN -> {
                anchorStatus = AnchorStatus.RESOLVING
                earth.resolveAnchorOnTerrainAsync(
                    p.latitude, p.longitude, p.altitudeAboveTerrainM,
                    q.x.toFloat(), q.y.toFloat(), q.z.toFloat(), q.w.toFloat(),
                ) { anchor, state ->
                    main.post {
                        val ms = log.elapsedMs - resolveStartMs
                        log.event("resolve_done", mapOf("kind" to kind.name, "result" to state.name, "ms" to ms))
                        if (anchor != null && state == Anchor.TerrainAnchorState.SUCCESS) {
                            attach(anchor)
                        } else {
                            anchorStatus = AnchorStatus.FAILED
                            message = "Terrain anchor failed: ${state.name}"
                        }
                    }
                }
            }
        }
    }

    fun clearAnchor(logIt: Boolean = true) {
        anchorNode?.let { node ->
            childNodes.remove(node)
            node.anchor.detach()
            node.destroy()
        }
        anchorNode = null
        anchorKind = null
        anchorStatus = AnchorStatus.NONE
        if (logIt) log.event("anchor_cleared")
    }

    fun checkVps(latitude: Double, longitude: Double) {
        val s = session ?: run { message = "AR session not started."; return }
        message = "Checking VPS at %.5f, %.5f...".format(Locale.US, latitude, longitude)
        s.checkVpsAvailabilityAsync(latitude, longitude) { availability ->
            main.post {
                log.event("vps_check", mapOf(
                    "latitude" to latitude, "longitude" to longitude, "result" to availability.name,
                ))
                message = "VPS at %.5f, %.5f: %s".format(Locale.US, latitude, longitude, availability.name)
            }
        }
    }

    fun updateThresholds(t: GateThresholds) {
        gate.thresholds = t
        thresholds = t
        log.event("thresholds", mapOf("horizontal_m" to t.horizontalM, "yaw_deg" to t.yawDeg))
    }

    fun importPose(text: String) {
        pose = try {
            AnchorPose.fromJson(text).also {
                log.event("pose_imported", mapOf("label" to it.label, "source" to it.source.wire))
                message = "Pose \"${it.label}\" loaded (${it.source.wire})."
            }
        } catch (e: IllegalArgumentException) {
            message = "Pose file refused: ${e.message}"
            pose
        }
    }

    fun dispose() {
        clearAnchor(logIt = false)
        log.event("ar_screen_closed")
    }

    private fun attach(anchor: Anchor) {
        val node = AnchorNode(engine, anchor).apply {
            addChildNode(DebugPin.build(engine, materialLoader))
            loadModel()?.let { addChildNode(it) }
            isVisible = false
        }
        anchorNode = node
        anchorStatus = AnchorStatus.RESOLVED
        childNodes.add(node)
    }

    /** The owner's licensed GLB, if one was imported; never a stand-in model. */
    private fun loadModel(): Node? {
        val file = modelFile
        if (!file.exists()) return null
        return try {
            ModelNode(modelInstance = modelLoader.createModelInstance(file), autoAnimate = true)
        } catch (e: Exception) {
            log.event("model_load_failed", mapOf("error" to e.javaClass.simpleName))
            message = "Model could not be loaded: ${e.javaClass.simpleName}"
            null
        }
    }

    private fun savePose(p: AnchorPose): File {
        posesDir.mkdirs()
        val name = "pose-" + SimpleDateFormat("yyyyMMdd-HHmmss", Locale.US).format(Date()) + ".json"
        return File(posesDir, name).apply { writeText(p.toJson()) }
    }

    private fun describeAnchor(anchor: Anchor?): String = when {
        anchorStatus == AnchorStatus.RESOLVING -> "${anchorKind?.name} resolving"
        anchorStatus == AnchorStatus.FAILED -> "${anchorKind?.name} failed"
        anchor == null -> "none"
        else -> "${anchorKind?.name} ${anchor.trackingState.name}"
    }
}
