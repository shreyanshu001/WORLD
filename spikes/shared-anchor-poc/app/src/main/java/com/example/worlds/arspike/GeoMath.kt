package com.example.worlds.arspike

import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.hypot
import kotlin.math.sin

/**
 * Orientation helpers in ARCore's East-Up-South frame: +X east, +Y up, +Z south.
 * The camera looks down its own -Z axis, with +Y towards the top of the screen.
 */
object GeoMath {
    data class Vec3(val x: Double, val y: Double, val z: Double)

    /** Rotates [v] by unit quaternion [q] (q * v * q^-1). */
    fun rotate(q: Quat, v: Vec3): Vec3 {
        // t = 2 * cross(q.xyz, v); v' = v + w * t + cross(q.xyz, t)
        val tx = 2 * (q.y * v.z - q.z * v.y)
        val ty = 2 * (q.z * v.x - q.x * v.z)
        val tz = 2 * (q.x * v.y - q.y * v.x)
        return Vec3(
            v.x + q.w * tx + (q.y * tz - q.z * ty),
            v.y + q.w * ty + (q.z * tx - q.x * tz),
            v.z + q.w * tz + (q.x * ty - q.y * tx),
        )
    }

    /**
     * The camera's horizontal viewing direction (x = east, z = south), or null if
     * neither its forward nor its top edge has a usable horizontal part.
     * When the phone looks straight down at a ground mark, forward is vertical,
     * so the top edge of the screen gives the direction instead.
     */
    fun horizontalViewDirection(cameraEus: Quat): Pair<Double, Double>? {
        val q = cameraEus.normalized()
        val forward = rotate(q, Vec3(0.0, 0.0, -1.0))
        if (hypot(forward.x, forward.z) >= MIN_HORIZONTAL) return forward.x to forward.z
        val top = rotate(q, Vec3(0.0, 1.0, 0.0))
        if (hypot(top.x, top.z) >= MIN_HORIZONTAL) return top.x to top.z
        return null
    }

    /** Compass heading of the view, degrees clockwise from north, in [0, 360). */
    fun headingDeg(cameraEus: Quat): Double? {
        val (east, south) = horizontalViewDirection(cameraEus) ?: return null
        val deg = Math.toDegrees(atan2(east, -south))
        return (deg + 360.0) % 360.0
    }

    /**
     * A yaw-only rotation for an object placed in front of the camera, so that
     * the object's +Z (its front) faces back towards the person who placed it.
     * No pitch or roll: the object stands upright whatever the phone's tilt.
     */
    fun yawFacingCamera(cameraEus: Quat): Quat {
        val (fx, fz) = horizontalViewDirection(cameraEus) ?: return Quat.IDENTITY
        // Rotation by theta about +Y maps +Z to (sin theta, 0, cos theta).
        val theta = atan2(-fx, -fz)
        return Quat(0.0, sin(theta / 2), 0.0, cos(theta / 2))
    }

    private const val MIN_HORIZONTAL = 0.2
}
