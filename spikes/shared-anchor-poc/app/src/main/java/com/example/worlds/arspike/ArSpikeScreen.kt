package com.example.worlds.arspike

import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.height
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import io.github.sceneview.ar.ARScene
import io.github.sceneview.rememberEngine
import io.github.sceneview.rememberMaterialLoader
import io.github.sceneview.rememberModelLoader
import io.github.sceneview.rememberNodes
import java.io.File
import java.util.Locale

private const val MAX_MODEL_BYTES = 50L * 1024 * 1024

@Composable
fun ArSpikeScreen(log: SessionLog) {
    val context = LocalContext.current
    val engine = rememberEngine()
    val modelLoader = rememberModelLoader(engine)
    val materialLoader = rememberMaterialLoader(engine)
    val childNodes = rememberNodes()
    val controller = remember {
        SpikeController(context, log, engine, materialLoader, modelLoader, childNodes)
    }
    DisposableEffect(controller) { onDispose { controller.dispose() } }

    var vpsDialog by remember { mutableStateOf(false) }

    val importPose = rememberLauncherForActivityResult(ActivityResultContracts.OpenDocument()) { uri ->
        uri?.let { readText(context, it) }?.let(controller::importPose)
    }
    val exportPose = rememberLauncherForActivityResult(ActivityResultContracts.CreateDocument("application/json")) { uri ->
        val p = controller.pose
        if (uri != null && p != null) writeText(context, uri, p.toJson())
    }
    val exportLog = rememberLauncherForActivityResult(ActivityResultContracts.CreateDocument("text/plain")) { uri ->
        if (uri != null) writeText(context, uri, log.text())
    }
    val importModel = rememberLauncherForActivityResult(ActivityResultContracts.OpenDocument()) { uri ->
        if (uri != null) controller.message = copyModel(context, uri, controller.modelFile, log)
    }

    Box(Modifier.fillMaxSize()) {
        ARScene(
            modifier = Modifier.fillMaxSize(),
            engine = engine,
            modelLoader = modelLoader,
            materialLoader = materialLoader,
            childNodes = childNodes,
            planeRenderer = true,
            sessionConfiguration = controller::configure,
            onSessionCreated = controller::onSessionCreated,
            onSessionResumed = controller::onSessionResumed,
            onSessionPaused = controller::onSessionPaused,
            onSessionFailed = controller::onSessionFailed,
            onSessionUpdated = controller::onFrame,
            onTrackingFailureChanged = controller::onTrackingFailure,
            onViewCreated = { controller.view = this },
        )

        // Cross-hair for capturing the ground mark.
        Box(Modifier.align(Alignment.Center).size(28.dp)) {
            Box(Modifier.align(Alignment.Center).width(28.dp).height(2.dp).background(Color.White))
            Box(Modifier.align(Alignment.Center).width(2.dp).height(28.dp).background(Color.White))
        }

        Hud(controller.hud, Modifier.align(Alignment.TopCenter).statusBarsPadding().padding(8.dp))

        Controls(
            controller = controller,
            onImportPose = { importPose.launch(arrayOf("application/json", "text/plain", "*/*")) },
            onExportPose = { exportPose.launch((controller.pose?.label ?: "pose").replace(' ', '-') + ".json") },
            onExportLog = { exportLog.launch(log.file.name) },
            onImportModel = { importModel.launch(arrayOf("model/gltf-binary", "application/octet-stream", "*/*")) },
            onVps = { vpsDialog = true },
            modifier = Modifier.align(Alignment.BottomCenter).navigationBarsPadding().padding(8.dp),
        )
    }

    if (vpsDialog) {
        VpsDialog(
            initial = controller.pose,
            onDismiss = { vpsDialog = false },
            onCheck = { lat, lng ->
                vpsDialog = false
                controller.checkVps(lat, lng)
            },
        )
    }
}

@Composable
private fun Hud(hud: Hud, modifier: Modifier) {
    fun f(v: Double?, unit: String) = v?.let { "%.1f%s".format(Locale.US, it, unit) } ?: "-"
    Column(
        modifier
            .fillMaxWidth()
            .background(Color(0xCC000000), MaterialTheme.shapes.medium)
            .padding(12.dp),
    ) {
        Text(
            "DEBUG measurement pin - not product content",
            color = Color(0xFFFF66CC), fontSize = 13.sp, fontWeight = FontWeight.Bold,
        )
        Text(hud.state.name, color = Color.White, fontSize = 26.sp, fontWeight = FontWeight.Bold)
        Text(
            "Earth ${hud.earthState}   anchor ${hud.anchor}   ${if (hud.contentShown) "SHOWN" else "hidden"}",
            color = Color.White, fontSize = 14.sp,
        )
        Text(
            "horizontal ${f(hud.horizontalM, " m")}   vertical ${f(hud.verticalM, " m")}   " +
                "yaw ${f(hud.yawDeg, "°")}",
            color = Color.White, fontSize = 15.sp,
        )
        Text(
            "heading ${f(hud.headingDeg, "°")}   ${"%.0f".format(Locale.US, hud.fps)} fps",
            color = Color.White, fontSize = 14.sp,
        )
        Text("Stop walking before you look at the screen.", color = Color(0xFFFFD54F), fontSize = 13.sp)
    }
}

@Composable
private fun Controls(
    controller: SpikeController,
    onImportPose: () -> Unit,
    onExportPose: () -> Unit,
    onExportLog: () -> Unit,
    onImportModel: () -> Unit,
    onVps: () -> Unit,
    modifier: Modifier,
) {
    val t = controller.thresholds
    Column(
        modifier.fillMaxWidth().background(Color(0xCC000000), MaterialTheme.shapes.medium).padding(8.dp),
        verticalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        controller.message?.let { Text(it, color = Color.White, fontSize = 14.sp) }
        Text(
            "Pose: " + (controller.pose?.let { "${it.label} (${it.source.wire})" } ?: "none"),
            color = Color.White, fontSize = 13.sp,
        )
        Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
            Button(onClick = controller::capture) { Text("Capture") }
            FilledTonalButton(onClick = { controller.resolve(AnchorKind.TERRAIN) }) { Text("Terrain") }
            FilledTonalButton(onClick = { controller.resolve(AnchorKind.WGS84) }) { Text("WGS84") }
            TextButton(onClick = { controller.clearAnchor() }) { Text("Clear") }
        }
        Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
            TextButton(onClick = onImportPose) { Text("Import pose") }
            TextButton(onClick = onExportPose, enabled = controller.pose != null) { Text("Export pose") }
            TextButton(onClick = onExportLog) { Text("Export log") }
        }
        Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
            TextButton(onClick = onVps) { Text("VPS check") }
            TextButton(onClick = onImportModel) { Text("Import GLB") }
        }
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(
                "Gate ≤%.0f m ≤%.0f°".format(Locale.US, t.horizontalM, t.yawDeg),
                color = Color.White, fontSize = 13.sp,
            )
            TextButton(onClick = { controller.updateThresholds(t.copy(horizontalM = (t.horizontalM - 1).coerceAtLeast(1.0))) }) { Text("m−") }
            TextButton(onClick = { controller.updateThresholds(t.copy(horizontalM = t.horizontalM + 1)) }) { Text("m+") }
            TextButton(onClick = { controller.updateThresholds(t.copy(yawDeg = (t.yawDeg - 1).coerceAtLeast(1.0))) }) { Text("°−") }
            TextButton(onClick = { controller.updateThresholds(t.copy(yawDeg = t.yawDeg + 1)) }) { Text("°+") }
        }
    }
}

@Composable
private fun VpsDialog(initial: AnchorPose?, onDismiss: () -> Unit, onCheck: (Double, Double) -> Unit) {
    var lat by remember { mutableStateOf(initial?.latitude?.toString() ?: "") }
    var lng by remember { mutableStateOf(initial?.longitude?.toString() ?: "") }
    val latV = lat.toDoubleOrNull()?.takeIf { it in -90.0..90.0 }
    val lngV = lng.toDoubleOrNull()?.takeIf { it in -180.0..180.0 }
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Check VPS coverage") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text("A candidate site, from a map. Works from anywhere.")
                OutlinedTextField(lat, { lat = it }, label = { Text("Latitude") }, isError = latV == null)
                OutlinedTextField(lng, { lng = it }, label = { Text("Longitude") }, isError = lngV == null)
            }
        },
        confirmButton = {
            TextButton(onClick = { onCheck(latV!!, lngV!!) }, enabled = latV != null && lngV != null) { Text("Check") }
        },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Cancel") } },
    )
}

private fun readText(context: android.content.Context, uri: Uri): String? =
    context.contentResolver.openInputStream(uri)?.use { it.readBytes().toString(Charsets.UTF_8) }

private fun writeText(context: android.content.Context, uri: Uri, text: String) {
    context.contentResolver.openOutputStream(uri)?.use { it.write(text.toByteArray(Charsets.UTF_8)) }
}

/** Copies a GLB in after checking its header and size; returns a message for the user. */
private fun copyModel(context: android.content.Context, uri: Uri, target: File, log: SessionLog): String {
    val bytes = context.contentResolver.openInputStream(uri)?.use { input ->
        val buffer = input.readNBytesCompat(MAX_MODEL_BYTES + 1)
        buffer
    } ?: return "Could not read that file."
    if (bytes.size > MAX_MODEL_BYTES) return "Model refused: larger than 50 MB."
    val magic = bytes.size >= 12 && String(bytes, 0, 4, Charsets.US_ASCII) == "glTF"
    if (!magic) return "Model refused: not a binary glTF (.glb) file."
    target.parentFile?.mkdirs()
    target.writeBytes(bytes)
    val digest = java.security.MessageDigest.getInstance("SHA-256").digest(bytes)
        .joinToString("") { "%02x".format(it) }
    log.event("model_imported", mapOf("bytes" to bytes.size, "sha256" to digest))
    return "Model imported (${bytes.size / 1024} KB). It appears on the next placed anchor."
}

private fun java.io.InputStream.readNBytesCompat(limit: Long): ByteArray {
    val out = java.io.ByteArrayOutputStream()
    val buf = ByteArray(64 * 1024)
    var total = 0L
    while (total < limit) {
        val n = read(buf)
        if (n < 0) break
        out.write(buf, 0, n)
        total += n
    }
    return out.toByteArray()
}
