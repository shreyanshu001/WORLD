package com.example.worlds.arspike

import androidx.compose.ui.graphics.Color
import dev.romainguy.kotlin.math.Float3
import io.github.sceneview.loaders.MaterialLoader
import io.github.sceneview.node.CylinderNode
import io.github.sceneview.node.Node
import io.github.sceneview.node.SphereNode
import com.google.android.filament.Engine

/**
 * Development-only measurement pin, labelled DEBUG on screen (handoff section 1.5
 * and section 7: debug geometry is not product content).
 *
 * Its origin is the anchor itself, where a tape measure is read from:
 * - a flat disc 0.30 m across lying on the ground at the anchor,
 * - a 1.2 m mast standing on it, topped by a ball, so it is visible from afar,
 * - a 0.4 m arm along the anchor's +Z, the direction it was placed facing.
 */
object DebugPin {
    private val MAGENTA = Color(0xFFE0119D)
    private val CYAN = Color(0xFF00B8D4)

    fun build(engine: Engine, materialLoader: MaterialLoader): Node {
        val body = materialLoader.createColorInstance(MAGENTA, metallic = 0f, roughness = 0.6f)
        val facing = materialLoader.createColorInstance(CYAN, metallic = 0f, roughness = 0.6f)
        return Node(engine).apply {
            addChildNode(
                CylinderNode(engine, radius = 0.15f, height = 0.01f,
                    center = Float3(0f, 0.005f, 0f), materialInstance = body),
            )
            addChildNode(
                CylinderNode(engine, radius = 0.015f, height = 1.2f,
                    center = Float3(0f, 0.6f, 0f), materialInstance = body),
            )
            addChildNode(
                SphereNode(engine, radius = 0.06f, center = Float3(0f, 1.2f, 0f), materialInstance = body),
            )
            addChildNode(
                CylinderNode(engine, radius = 0.012f, height = 0.4f,
                    center = Float3(0f, 0f, 0f), materialInstance = facing).apply {
                    // Lay the arm flat along +Z, starting at the mast.
                    rotation = dev.romainguy.kotlin.math.Float3(90f, 0f, 0f)
                    position = Float3(0f, 0.02f, 0.2f)
                },
            )
        }
    }
}
