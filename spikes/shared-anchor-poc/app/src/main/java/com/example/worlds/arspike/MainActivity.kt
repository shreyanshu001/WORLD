package com.example.worlds.arspike

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import androidx.activity.ComponentActivity
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.unit.dp
import androidx.core.content.ContextCompat
import androidx.lifecycle.compose.LifecycleResumeEffect
import com.google.ar.core.ArCoreApk
import kotlinx.coroutines.delay

class MainActivity : ComponentActivity() {
    private lateinit var log: SessionLog

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        log = SessionLog(this)
        log.event("app_start", mapOf(
            "device" to "${Build.MANUFACTURER} ${Build.MODEL}",
            "android" to Build.VERSION.RELEASE,
            "sdk_int" to Build.VERSION.SDK_INT,
            "arcore_apk" to arCoreApkVersion(),
            "sceneview" to "2.3.4",
            "arcore_sdk" to "1.52.0",
        ))
        setContent {
            MaterialTheme(colorScheme = darkColorScheme()) {
                Surface(Modifier.fillMaxSize()) { SpikeApp(log) }
            }
        }
    }

    private fun arCoreApkVersion(): String? = try {
        packageManager.getPackageInfo("com.google.ar.core", 0).versionName
    } catch (e: PackageManager.NameNotFoundException) {
        null
    }
}

private enum class Step { NOTICE, AVAILABILITY, PERMISSIONS, AR }

private const val PREFS = "spike"
private const val NOTICE_KEY = "google_ar_notice_acknowledged_v1"

@Composable
private fun SpikeApp(log: SessionLog) {
    val context = LocalContext.current
    val prefs = remember { context.getSharedPreferences(PREFS, Context.MODE_PRIVATE) }
    var step by remember {
        mutableStateOf(if (prefs.getBoolean(NOTICE_KEY, false)) Step.AVAILABILITY else Step.NOTICE)
    }
    when (step) {
        Step.NOTICE -> NoticeScreen {
            prefs.edit().putBoolean(NOTICE_KEY, true).apply()
            log.event("notice_acknowledged")
            step = Step.AVAILABILITY
        }
        Step.AVAILABILITY -> AvailabilityScreen(log) { step = Step.PERMISSIONS }
        Step.PERMISSIONS -> PermissionScreen(log) { step = Step.AR }
        Step.AR -> ArSpikeScreen(log)
    }
}

/**
 * Google's required ARCore notices (developers.google.com/ar/develop/privacy-requirements)
 * plus the safety prompt from handoff section 11. Accepted for the PoC only (D-044).
 */
@Composable
private fun NoticeScreen(onAccept: () -> Unit) {
    val uri = LocalUriHandler.current
    Column(
        Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(24.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        Text("WORLDS shared-anchor test (development build)", style = MaterialTheme.typography.headlineSmall)
        Text(
            "This application runs on Google Play Services for AR (ARCore), which is provided by " +
                "Google and governed by the Google Privacy Policy.",
        )
        Text("To power this session, Google will process sensor data (e.g., camera and location).")
        OutlinedButton(onClick = {
            uri.openUri("https://support.google.com/ar?p=how-google-play-services-for-ar-handles-your-data")
        }) { Text("Learn more") }
        OutlinedButton(onClick = { uri.openUri("https://policies.google.com/privacy") }) {
            Text("Google Privacy Policy")
        }
        // ARCore Additional Terms of Service: users must be told that ARCore functionality
        // is provided by Google and that its use is subject to Google's Terms of Service
        // and Privacy Policy.
        Text(
            "This build includes ARCore functionality provided by Google. Use of it is subject " +
                "to the Google Terms of Service and the Google Privacy Policy.",
        )
        OutlinedButton(onClick = { uri.openUri("https://policies.google.com/terms") }) {
            Text("Google Terms of Service")
        }
        Text("Safety", style = MaterialTheme.typography.titleMedium)
        Text(
            "Stop in a safe public place before you look at the screen. Do not walk while using the " +
                "camera. Stay off roads, railways, rooftops and private or restricted property.",
        )
        Text(
            "This build keeps a measurement log on the phone with accuracy, timing and performance " +
                "figures. It never logs where the phone is; only anchor positions you capture or type, " +
                "and sites you check, are written.",
        )
        Button(onClick = onAccept) { Text("I understand, continue") }
    }
}

@Composable
private fun AvailabilityScreen(log: SessionLog, onReady: () -> Unit) {
    val context = LocalContext.current
    var availability by remember { mutableStateOf<ArCoreApk.Availability?>(null) }
    var attempt by remember { mutableIntStateOf(0) }

    // Check again on every return to the app, e.g. after installing ARCore from Play.
    LifecycleResumeEffect(Unit) {
        attempt++
        onPauseOrDispose { }
    }
    LaunchedEffect(attempt) {
        var a = ArCoreApk.getInstance().checkAvailability(context)
        var waited = 0
        while (a.isTransient && waited < 10_000) {
            delay(200)
            waited += 200
            a = ArCoreApk.getInstance().checkAvailability(context)
        }
        if (a != availability) log.event("arcore_availability", mapOf("result" to a.name))
        availability = a
        if (a == ArCoreApk.Availability.SUPPORTED_INSTALLED) onReady()
    }

    Column(Modifier.fillMaxSize().padding(24.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
        Text("ARCore on this phone", style = MaterialTheme.typography.headlineSmall)
        val a = availability
        when {
            a == null || a.isTransient -> Text("Checking...")
            a == ArCoreApk.Availability.UNSUPPORTED_DEVICE_NOT_CAPABLE -> Text(
                "ARCore does not support this phone (${Build.MANUFACTURER} ${Build.MODEL}). " +
                    "It cannot take part in the shared-anchor test. This result is recorded in the log.",
            )
            a == ArCoreApk.Availability.SUPPORTED_NOT_INSTALLED ||
                a == ArCoreApk.Availability.SUPPORTED_APK_TOO_OLD -> {
                Text("Google Play Services for AR must be installed or updated.")
                Button(onClick = {
                    val status = ArCoreApk.getInstance().requestInstall(context as Activity, true)
                    log.event("arcore_install_requested", mapOf("status" to status.name))
                }) { Text("Install or update") }
            }
            else -> {
                Text("Could not tell whether ARCore is available: ${a.name}")
                Button(onClick = { attempt++ }) { Text("Try again") }
            }
        }
    }
}

@Composable
private fun PermissionScreen(log: SessionLog, onGranted: () -> Unit) {
    val context = LocalContext.current
    val needed = arrayOf(
        Manifest.permission.CAMERA,
        Manifest.permission.ACCESS_FINE_LOCATION,
        Manifest.permission.ACCESS_COARSE_LOCATION,
    )
    fun allGranted() = needed.all {
        ContextCompat.checkSelfPermission(context, it) == PackageManager.PERMISSION_GRANTED
    }
    var refused by remember { mutableStateOf(false) }
    val launcher = rememberLauncherForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) { r ->
        log.event("permissions_result", r.mapKeys { it.key.substringAfterLast('.') })
        if (allGranted()) onGranted() else refused = true
    }
    LifecycleResumeEffect(Unit) {
        if (allGranted()) onGranted()
        onPauseOrDispose { }
    }
    Column(Modifier.fillMaxSize().padding(24.dp), verticalArrangement = Arrangement.spacedBy(16.dp)) {
        Text("Camera and precise location", style = MaterialTheme.typography.headlineSmall)
        Text(
            "The camera shows the scene. Precise location lets ARCore Geospatial work out where the " +
                "phone is; it is used only while this screen is open, never in the background.",
        )
        if (refused) Text("Both are needed for this test. You can allow them again or in Settings.")
        Button(onClick = { launcher.launch(needed) }) { Text(if (refused) "Ask again" else "Allow") }
        if (refused) {
            OutlinedButton(onClick = {
                context.startActivity(
                    Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.fromParts("package", context.packageName, null)),
                )
            }) { Text("Open Settings") }
        }
    }
}
