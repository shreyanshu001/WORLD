package com.example.worlds.arspike

/**
 * Anchor/session states from handoff section 4.4. "GPS says nearby" never
 * becomes TRACKING: only a localized Earth plus a resolved anchor does.
 */
enum class SpikeState {
    UNSUPPORTED,
    CHECKING,
    LOCALIZING,
    /** Accuracy is inside the gate but no anchor is loaded: nothing to show yet. */
    LOCALIZED,
    RESOLVING,
    TRACKING,
    DEGRADED,
    TEMPORARILY_UNAVAILABLE,
    FAILED,
}

enum class AnchorStatus { NONE, RESOLVING, RESOLVED, FAILED }

/** Thresholds are starting points to tune from field data, not claims of accuracy. */
data class GateThresholds(
    /** Show content once horizontal accuracy is at or below this. */
    val horizontalM: Double = 10.0,
    /** Show content once yaw accuracy is at or below this. */
    val yawDeg: Double = 15.0,
    /** Hide again only when accuracy worsens past threshold + hysteresis. */
    val horizontalHysteresisM: Double = 5.0,
    val yawHysteresisDeg: Double = 5.0,
) {
    init {
        require(horizontalM > 0 && yawDeg > 0) { "thresholds must be positive" }
        require(horizontalHysteresisM >= 0 && yawHysteresisDeg >= 0) { "hysteresis must not be negative" }
    }
}

data class GateInput(
    /** Geospatial unsupported on this device, or Earth is in an error state. */
    val earthError: Boolean,
    /** The phone's own motion tracking (camera) is tracking. */
    val cameraTracking: Boolean,
    /** Earth's tracking state is TRACKING. */
    val earthTracking: Boolean,
    val horizontalAccuracyM: Double?,
    val yawAccuracyDeg: Double?,
    val anchor: AnchorStatus,
    /** The anchor's own tracking state is TRACKING. */
    val anchorTracking: Boolean,
)

data class GateOutput(val state: SpikeState, val showContent: Boolean, val localized: Boolean)

/**
 * Decides whether precision-dependent content may be shown (AR-004).
 * Content is hidden, never left to drift, when quality drops.
 */
class QualityGate(var thresholds: GateThresholds = GateThresholds()) {
    var localized = false
        private set
    private var everLocalized = false

    fun update(input: GateInput): GateOutput {
        if (input.earthError) {
            localized = false
            return GateOutput(SpikeState.FAILED, showContent = false, localized = false)
        }
        if (!input.cameraTracking) {
            // Keep "localized" so a brief camera interruption does not restart
            // the whole localization, but never show content meanwhile.
            return GateOutput(SpikeState.TEMPORARILY_UNAVAILABLE, showContent = false, localized = localized)
        }
        localized = nextLocalized(input)
        if (localized) everLocalized = true

        val state = when {
            !input.earthTracking && !everLocalized -> SpikeState.CHECKING
            !localized && everLocalized -> SpikeState.DEGRADED
            !localized -> SpikeState.LOCALIZING
            input.anchor == AnchorStatus.NONE -> SpikeState.LOCALIZED
            input.anchor == AnchorStatus.FAILED -> SpikeState.FAILED
            input.anchor == AnchorStatus.RESOLVING -> SpikeState.RESOLVING
            input.anchor == AnchorStatus.RESOLVED && !input.anchorTracking -> SpikeState.RESOLVING
            else -> SpikeState.TRACKING
        }
        val show = localized && input.anchor == AnchorStatus.RESOLVED && input.anchorTracking
        return GateOutput(state, show, localized)
    }

    fun reset() {
        localized = false
        everLocalized = false
    }

    private fun nextLocalized(input: GateInput): Boolean {
        val h = input.horizontalAccuracyM
        val y = input.yawAccuracyDeg
        if (!input.earthTracking || h == null || y == null || !h.isFinite() || !y.isFinite()) return false
        val t = thresholds
        return if (localized) {
            h <= t.horizontalM + t.horizontalHysteresisM && y <= t.yawDeg + t.yawHysteresisDeg
        } else {
            h <= t.horizontalM && y <= t.yawDeg
        }
    }
}
