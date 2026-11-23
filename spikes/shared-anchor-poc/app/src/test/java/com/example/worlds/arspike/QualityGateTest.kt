package com.example.worlds.arspike

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class QualityGateTest {
    private fun input(
        h: Double? = 3.0,
        yaw: Double? = 4.0,
        earthTracking: Boolean = true,
        cameraTracking: Boolean = true,
        anchor: AnchorStatus = AnchorStatus.RESOLVED,
        anchorTracking: Boolean = true,
        earthError: Boolean = false,
    ) = GateInput(earthError, cameraTracking, earthTracking, h, yaw, anchor, anchorTracking)

    @Test
    fun `nothing is shown before Earth tracks`() {
        val out = QualityGate().update(input(earthTracking = false, h = null, yaw = null))
        assertEquals(SpikeState.CHECKING, out.state)
        assertFalse(out.showContent)
    }

    @Test
    fun `tracking but too inaccurate is localizing, not shown`() {
        val out = QualityGate().update(input(h = 25.0))
        assertEquals(SpikeState.LOCALIZING, out.state)
        assertFalse(out.showContent)
    }

    @Test
    fun `localized with a resolved, tracking anchor is shown`() {
        val out = QualityGate().update(input())
        assertEquals(SpikeState.TRACKING, out.state)
        assertTrue(out.showContent)
    }

    @Test
    fun `localized without an anchor shows nothing`() {
        val gate = QualityGate()
        val none = gate.update(input(anchor = AnchorStatus.NONE))
        assertFalse(none.showContent)
        // Localized is not "tracking": there is no anchor to track yet.
        assertEquals(SpikeState.LOCALIZED, none.state)
        assertEquals(SpikeState.RESOLVING, gate.update(input(anchor = AnchorStatus.RESOLVING)).state)
        assertEquals(SpikeState.RESOLVING, gate.update(input(anchorTracking = false)).state)
        assertEquals(SpikeState.FAILED, gate.update(input(anchor = AnchorStatus.FAILED)).state)
    }

    @Test
    fun `hysteresis keeps content through small wobbles and hides it on real loss`() {
        val gate = QualityGate(GateThresholds(horizontalM = 10.0, yawDeg = 15.0,
            horizontalHysteresisM = 5.0, yawHysteresisDeg = 5.0))
        assertTrue(gate.update(input(h = 9.0)).showContent)
        // 12 m is past the threshold but inside the hysteresis: still shown.
        assertTrue(gate.update(input(h = 12.0)).showContent)
        // 16 m is past threshold + hysteresis: hidden and reported as degraded.
        val lost = gate.update(input(h = 16.0))
        assertFalse(lost.showContent)
        assertEquals(SpikeState.DEGRADED, lost.state)
        // Coming back to 12 m is not enough; it must reach the threshold again.
        assertFalse(gate.update(input(h = 12.0)).showContent)
        assertTrue(gate.update(input(h = 10.0)).showContent)
    }

    @Test
    fun `yaw accuracy gates as well as position`() {
        val out = QualityGate().update(input(yaw = 40.0))
        assertFalse(out.showContent)
    }

    @Test
    fun `camera interruption hides content without forgetting localization`() {
        val gate = QualityGate()
        gate.update(input())
        val paused = gate.update(input(cameraTracking = false))
        assertEquals(SpikeState.TEMPORARILY_UNAVAILABLE, paused.state)
        assertFalse(paused.showContent)
        assertTrue(paused.localized)
        assertTrue(gate.update(input()).showContent)
    }

    @Test
    fun `an Earth error fails and hides`() {
        val gate = QualityGate()
        gate.update(input())
        val out = gate.update(input(earthError = true))
        assertEquals(SpikeState.FAILED, out.state)
        assertFalse(out.showContent)
        assertFalse(gate.localized)
    }

    @Test
    fun `non-finite accuracy never counts as localized`() {
        assertFalse(QualityGate().update(input(h = Double.NaN)).showContent)
        assertFalse(QualityGate().update(input(yaw = Double.POSITIVE_INFINITY)).showContent)
    }
}
