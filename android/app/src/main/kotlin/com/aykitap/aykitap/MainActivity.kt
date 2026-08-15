package com.aykitap.aykitap

import android.content.Intent
import android.database.Cursor
import android.graphics.drawable.ColorDrawable
import android.net.Uri
import android.os.Bundle
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

/// Backs the "Open with" flow: a book file tapped in another app (Telegram,
/// Files, mail, ...) arrives here as an ACTION_VIEW intent (see the
/// intent-filter in AndroidManifest.xml). MethodChannel hands the resolved
/// local file path to IncomingFileService on the Dart side, which imports it
/// into OwnBooksStore and opens the matching reader — the same path a
/// manually-picked file already takes.
///
/// Also backs the `aykitap://book/<id>` deep link (same ACTION_VIEW intent,
/// distinguished by scheme): the raw URI is handed to DeepLinkService on the
/// Dart side, which parses it and pushes the matching book detail screen.
class MainActivity : FlutterActivity() {
    private val fileChannelName = "com.aykitap.aykitap/incoming_file"
    private val deepLinkChannelName = "com.aykitap.aykitap/deep_link"
    private var fileChannel: MethodChannel? = null
    private var deepLinkChannel: MethodChannel? = null
    private var pendingPath: String? = null
    private var pendingLink: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        // The app has a *manual* light/dark switch (AppTheme, stored by
        // Flutter's shared_preferences under "flutter.is_dark_theme") that is
        // independent of the OS dark-mode setting. The native launch window
        // would otherwise show a colour chosen by the OS theme, so in the
        // app's light mode users saw a dark flash before Flutter's themed
        // splash drew. Reading the stored preference here lets the native
        // window match the app's own theme right away — no dark shadow.
        val prefs = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
        val isDark = prefs.getBoolean("flutter.is_dark_theme", true) // AppTheme defaults to dark
        val bg = if (isDark) 0xFF13131A.toInt() else 0xFFF6F6F9.toInt()
        window.setBackgroundDrawable(ColorDrawable(bg))
        super.onCreate(savedInstanceState)
        pendingPath = resolveIncomingFile(intent)
        pendingLink = resolveDeepLink(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        fileChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, fileChannelName).apply {
            setMethodCallHandler { call, result ->
                if (call.method == "getInitialFile") {
                    result.success(pendingPath)
                    pendingPath = null
                } else {
                    result.notImplemented()
                }
            }
        }
        deepLinkChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, deepLinkChannelName).apply {
            setMethodCallHandler { call, result ->
                if (call.method == "getInitialLink") {
                    result.success(pendingLink)
                    pendingLink = null
                } else {
                    result.notImplemented()
                }
            }
        }
    }

    // launchMode="singleTop" means a repeat "Open with"/deep link while the
    // app is already running redelivers here instead of spawning a new
    // instance.
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        resolveIncomingFile(intent)?.let { fileChannel?.invokeMethod("onIncomingFile", it) }
        resolveDeepLink(intent)?.let { deepLinkChannel?.invokeMethod("onDeepLink", it) }
    }

    private fun resolveIncomingFile(intent: Intent?): String? {
        if (intent == null || intent.action != Intent.ACTION_VIEW) return null
        val uri = intent.data ?: return null
        return try {
            when (uri.scheme) {
                "file" -> uri.path
                "content" -> copyContentUriToCache(uri)
                else -> null
            }
        } catch (e: Exception) {
            null
        }
    }

    private fun resolveDeepLink(intent: Intent?): String? {
        if (intent == null || intent.action != Intent.ACTION_VIEW) return null
        val uri = intent.data ?: return null
        return if (uri.scheme == "aykitap") uri.toString() else null
    }

    // content:// URIs (what Telegram/Files/Gmail hand us) aren't usable as
    // dart:io File paths and can vanish once the sending app's process dies,
    // so the bytes are copied into our own cache right away.
    private fun copyContentUriToCache(uri: Uri): String? {
        val resolver = contentResolver
        var displayName = "shared_${System.currentTimeMillis()}"
        val cursor: Cursor? = resolver.query(uri, null, null, null, null)
        cursor?.use {
            if (it.moveToFirst()) {
                val idx = it.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                if (idx >= 0) it.getString(idx)?.let { name -> displayName = name }
            }
        }
        val incomingDir = File(cacheDir, "incoming").apply { mkdirs() }
        val destFile = File(incomingDir, displayName)
        val input = resolver.openInputStream(uri) ?: return null
        input.use { stream ->
            FileOutputStream(destFile).use { output -> stream.copyTo(output) }
        }
        return destFile.absolutePath
    }
}
