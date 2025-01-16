package com.example.mapbox_flutter_app

import io.flutter.embedding.android.FlutterActivity
import android.os.Build
import android.window.OnBackInvokedCallback
import android.window.OnBackInvokedDispatcher

class MainActivity: FlutterActivity() {
    override fun onStart() {
        super.onStart()
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            onBackInvokedDispatcher.registerOnBackInvokedCallback(
                OnBackInvokedDispatcher.PRIORITY_DEFAULT
            ) {
                // Default back button behavior
                onBackPressed()
            }
        }
    }
}
