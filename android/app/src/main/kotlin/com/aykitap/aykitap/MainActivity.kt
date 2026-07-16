package com.aykitap.aykitap

import android.graphics.drawable.ColorDrawable
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
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
    }
}
