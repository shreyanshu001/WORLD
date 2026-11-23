package com.example.worlds.arspike

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertThrows
import org.junit.Assert.assertTrue
import org.junit.Test

class AnchorPoseTest {
    private val onSite = AnchorPose(
        label = "Bench corner",
        latitude = 12.9716,
        longitude = 77.5946,
        altitudeWgs84M = 912.4,
        altitudeAboveTerrainM = 0.0,
        eusQuaternion = Quat(0.0, 0.7071067811865476, 0.0, 0.7071067811865476),
        source = PoseSource.ON_SITE_CAPTURE,
        capturedAtEpochMs = 1_795_000_000_000,
        capturedBy = "Pixel 8a",
        captureAccuracy = CaptureAccuracy(horizontalM = 2.1, verticalM = 1.4, yawDeg = 3.2),
    )

    @Test
    fun `round trips through JSON unchanged`() {
        assertEquals(onSite, AnchorPose.fromJson(onSite.toJson()))
    }

    @Test
    fun `a map-typed pose has no altitude and no capture details`() {
        val typed = """
            {"schema_version":1,"label":"From the map","latitude":12.5,"longitude":77.25,
             "altitude_wgs84_m":null,"altitude_above_terrain_m":0,
             "eus_quaternion_xyzw":[0,0,0,1],"source":"map_coordinates"}
        """.trimIndent()
        val pose = AnchorPose.fromJson(typed)
        assertNull(pose.altitudeWgs84M)
        assertNull(pose.captureAccuracy)
        assertNull(pose.capturedBy)
        assertEquals(PoseSource.MAP_COORDINATES, pose.source)
    }

    @Test
    fun `parsing normalizes the quaternion`() {
        val text = onSite.toJson().replace(Regex("\\[[^\\]]*\\]"), "[0, 2, 0, 2]")
        val q = AnchorPose.fromJson(text).eusQuaternion
        assertEquals(1.0, q.norm, 1e-12)
        assertEquals(0.7071067811865476, q.y, 1e-12)
    }

    @Test
    fun `rejects coordinates out of range`() {
        assertThrows(IllegalArgumentException::class.java) { onSite.copy(latitude = 90.5) }
        assertThrows(IllegalArgumentException::class.java) { onSite.copy(longitude = -181.0) }
        assertThrows(IllegalArgumentException::class.java) { onSite.copy(latitude = Double.NaN) }
        assertThrows(IllegalArgumentException::class.java) { onSite.copy(altitudeAboveTerrainM = 500.0) }
        assertThrows(IllegalArgumentException::class.java) { onSite.copy(altitudeWgs84M = 20_000.0) }
    }

    @Test
    fun `rejects a blank or long label and a zero quaternion`() {
        assertThrows(IllegalArgumentException::class.java) { onSite.copy(label = " ") }
        assertThrows(IllegalArgumentException::class.java) { onSite.copy(label = "x".repeat(81)) }
        assertThrows(IllegalArgumentException::class.java) {
            onSite.copy(eusQuaternion = Quat(0.0, 0.0, 0.0, 0.0))
        }
    }

    @Test
    fun `refuses files it cannot trust, with a reason`() {
        fun reason(text: String) =
            assertThrows(IllegalArgumentException::class.java) { AnchorPose.fromJson(text) }.message ?: ""

        assertTrue(reason("not json").contains("not a JSON object"))
        assertTrue(reason(onSite.toJson().replace("\"schema_version\": 1", "\"schema_version\": 2"))
            .contains("schema_version"))
        assertTrue(reason(onSite.toJson().replace("\"latitude\"", "\"lat\"")).contains("latitude missing"))
        assertTrue(reason(onSite.toJson().replace("on_site_capture", "guess")).contains("unknown source"))
        assertTrue(reason(onSite.toJson().replace(Regex("\\[[^\\]]*\\]"), "[0, 0, 1]"))
            .contains("4 numbers"))
    }
}
