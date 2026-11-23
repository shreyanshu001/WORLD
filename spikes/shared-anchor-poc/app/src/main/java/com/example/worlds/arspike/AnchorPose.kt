package com.example.worlds.arspike

import org.json.JSONObject
import kotlin.math.sqrt

/** A rotation as a unit quaternion, in ARCore's East-Up-South (EUS) frame. */
data class Quat(val x: Double, val y: Double, val z: Double, val w: Double) {
    val norm: Double get() = sqrt(x * x + y * y + z * z + w * w)

    fun normalized(): Quat {
        val n = norm
        require(n.isFinite() && n > 1e-9) { "quaternion has no length" }
        return Quat(x / n, y / n, z / n, w / n)
    }

    companion object {
        val IDENTITY = Quat(0.0, 0.0, 0.0, 1.0)
    }
}

/** How the stored pose was obtained. The difference is one of the PoC's measurements. */
enum class PoseSource(val wire: String) {
    /** Captured on site by a phone that had localized with Geospatial/VPS. */
    ON_SITE_CAPTURE("on_site_capture"),

    /** Typed from map coordinates without visiting (evidence for remote placement). */
    MAP_COORDINATES("map_coordinates");

    companion object {
        fun fromWire(value: String) =
            entries.firstOrNull { it.wire == value }
                ?: throw IllegalArgumentException("unknown source '$value'")
    }
}

/** Accuracy reported by the capturing phone when the pose was taken. */
data class CaptureAccuracy(
    val horizontalM: Double,
    val verticalM: Double,
    val yawDeg: Double,
)

/**
 * The shared anchor identity for the PoC: everything a second phone needs to
 * rebuild the same anchor, and nothing about anyone's movement.
 *
 * Geospatial anchors have no shareable id. WGS84 anchors are created on the
 * device from these values; Terrain anchors are resolved by Google's service
 * from latitude/longitude and the offset above terrain.
 */
data class AnchorPose(
    val label: String,
    val latitude: Double,
    val longitude: Double,
    /** WGS84 altitude from an on-site capture; null when typed from a map. */
    val altitudeWgs84M: Double?,
    /** Offset above Google's terrain model; 0 for an object standing on the ground. */
    val altitudeAboveTerrainM: Double,
    val eusQuaternion: Quat,
    val source: PoseSource,
    val capturedAtEpochMs: Long? = null,
    val capturedBy: String? = null,
    val captureAccuracy: CaptureAccuracy? = null,
) {
    init {
        require(label.isNotBlank() && label.length <= 80) { "label must be 1-80 characters" }
        require(latitude.isFinite() && latitude in -90.0..90.0) { "latitude out of range" }
        require(longitude.isFinite() && longitude in -180.0..180.0) { "longitude out of range" }
        altitudeWgs84M?.let {
            require(it.isFinite() && it in -500.0..9000.0) { "altitude out of range" }
        }
        require(altitudeAboveTerrainM.isFinite() && altitudeAboveTerrainM in -10.0..100.0) {
            "altitude above terrain out of range"
        }
        require(eusQuaternion.norm.isFinite() && eusQuaternion.norm > 1e-9) {
            "quaternion has no length"
        }
    }

    fun toJson(): String = JSONObject().apply {
        put("schema_version", SCHEMA_VERSION)
        put("label", label)
        put("latitude", latitude)
        put("longitude", longitude)
        put("altitude_wgs84_m", altitudeWgs84M ?: JSONObject.NULL)
        put("altitude_above_terrain_m", altitudeAboveTerrainM)
        put("eus_quaternion_xyzw", org.json.JSONArray(listOf(
            eusQuaternion.x, eusQuaternion.y, eusQuaternion.z, eusQuaternion.w,
        )))
        put("source", source.wire)
        put("captured_at_epoch_ms", capturedAtEpochMs ?: JSONObject.NULL)
        put("captured_by", capturedBy ?: JSONObject.NULL)
        put("capture_accuracy", captureAccuracy?.let {
            JSONObject()
                .put("horizontal_m", it.horizontalM)
                .put("vertical_m", it.verticalM)
                .put("yaw_deg", it.yawDeg)
        } ?: JSONObject.NULL)
    }.toString(2)

    companion object {
        const val SCHEMA_VERSION = 1

        /** Parses and validates a pose file. Throws [IllegalArgumentException] with a reason. */
        fun fromJson(text: String): AnchorPose {
            val o = try {
                JSONObject(text)
            } catch (e: org.json.JSONException) {
                throw IllegalArgumentException("not a JSON object", e)
            }
            val version = o.optInt("schema_version", -1)
            require(version == SCHEMA_VERSION) { "unsupported schema_version $version" }
            val q = o.optJSONArray("eus_quaternion_xyzw")
                ?: throw IllegalArgumentException("eus_quaternion_xyzw missing")
            require(q.length() == 4) { "eus_quaternion_xyzw needs 4 numbers" }
            val accuracy = o.optJSONObject("capture_accuracy")?.let {
                CaptureAccuracy(
                    horizontalM = it.getDouble("horizontal_m"),
                    verticalM = it.getDouble("vertical_m"),
                    yawDeg = it.getDouble("yaw_deg"),
                )
            }
            return AnchorPose(
                label = o.optString("label", ""),
                latitude = o.number("latitude"),
                longitude = o.number("longitude"),
                altitudeWgs84M = if (o.isNull("altitude_wgs84_m")) null else o.number("altitude_wgs84_m"),
                altitudeAboveTerrainM = o.number("altitude_above_terrain_m"),
                eusQuaternion = Quat(q.getDouble(0), q.getDouble(1), q.getDouble(2), q.getDouble(3))
                    .normalized(),
                source = PoseSource.fromWire(o.optString("source", "")),
                capturedAtEpochMs = if (o.isNull("captured_at_epoch_ms")) null else o.getLong("captured_at_epoch_ms"),
                capturedBy = if (o.isNull("captured_by")) null else o.optString("captured_by"),
                captureAccuracy = accuracy,
            )
        }

        private fun JSONObject.number(key: String): Double {
            if (!has(key) || isNull(key)) throw IllegalArgumentException("$key missing")
            return try {
                getDouble(key)
            } catch (e: org.json.JSONException) {
                throw IllegalArgumentException("$key is not a number", e)
            }
        }
    }
}
