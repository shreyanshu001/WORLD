package com.example.worlds.arspike

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Test
import kotlin.math.cos
import kotlin.math.sin

class GeoMathTest {
    /** Rotation of [deg] degrees about the axis (ax, ay, az). */
    private fun axisAngle(ax: Double, ay: Double, az: Double, deg: Double): Quat {
        val half = Math.toRadians(deg) / 2
        return Quat(ax * sin(half), ay * sin(half), az * sin(half), cos(half))
    }

    /** Camera turned to compass heading [deg] (clockwise from north), level. */
    private fun cameraAtHeading(deg: Double) = axisAngle(0.0, 1.0, 0.0, -deg)

    private fun front(q: Quat) = GeoMath.rotate(q, GeoMath.Vec3(0.0, 0.0, 1.0))

    @Test
    fun `identity camera looks north`() {
        assertEquals(0.0, GeoMath.headingDeg(Quat.IDENTITY)!!, 1e-9)
    }

    @Test
    fun `heading follows the camera round the compass`() {
        for (h in listOf(0.0, 45.0, 90.0, 180.0, 270.0, 359.0)) {
            assertEquals(h, GeoMath.headingDeg(cameraAtHeading(h))!!, 1e-6)
        }
    }

    @Test
    fun `placed object faces back towards the camera`() {
        for (h in listOf(0.0, 30.0, 90.0, 200.0, 315.0)) {
            val view = GeoMath.horizontalViewDirection(cameraAtHeading(h))!!
            val f = front(GeoMath.yawFacingCamera(cameraAtHeading(h)))
            assertEquals(-view.first, f.x, 1e-6)
            assertEquals(0.0, f.y, 1e-6)
            assertEquals(-view.second, f.z, 1e-6)
        }
    }

    @Test
    fun `facing rotation is upright whatever the phone's tilt`() {
        // Heading 90 (east), pitched 60 degrees down towards a ground mark.
        val tilted = compose(cameraAtHeading(90.0), axisAngle(1.0, 0.0, 0.0, -60.0))
        val yaw = GeoMath.yawFacingCamera(tilted)
        assertEquals(0.0, yaw.x, 1e-9)
        assertEquals(0.0, yaw.z, 1e-9)
        assertEquals(90.0, GeoMath.headingDeg(tilted)!!, 1e-6)
        val f = front(yaw)
        assertEquals(-1.0, f.x, 1e-6) // front points west, back at the camera
    }

    @Test
    fun `looking straight down uses the top of the screen`() {
        // Heading 180 (south), pitched straight down.
        val down = compose(cameraAtHeading(180.0), axisAngle(1.0, 0.0, 0.0, -90.0))
        assertNotNull(GeoMath.horizontalViewDirection(down))
        assertEquals(180.0, GeoMath.headingDeg(down)!!, 1e-6)
    }

    /** a then b, applied to vectors as a(b(v)). */
    private fun compose(a: Quat, b: Quat) = Quat(
        a.w * b.x + a.x * b.w + a.y * b.z - a.z * b.y,
        a.w * b.y - a.x * b.z + a.y * b.w + a.z * b.x,
        a.w * b.z + a.x * b.y - a.y * b.x + a.z * b.w,
        a.w * b.w - a.x * b.x - a.y * b.y - a.z * b.z,
    )
}
