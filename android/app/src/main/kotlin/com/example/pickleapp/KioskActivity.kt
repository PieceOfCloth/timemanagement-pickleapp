// package com.example.pickleapp

// import android.content.Intent
// import android.os.Bundle
// import io.flutter.embedding.android.FlutterActivity
// import io.flutter.embedding.engine.FlutterEngine
// import io.flutter.plugin.common.MethodChannel  // Import for Intent usage in MainActivity


// class KioskActivity : FlutterActivity() {

//     override fun onCreate(savedInstanceState: Bundle?) {
//         super.onCreate(savedInstanceState)
//         startLockTask()
//     }

//     override fun onDestroy() {
//         super.onDestroy()
//         stopLockTask()
//     }

//     override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
//         super.configureFlutterEngine(flutterEngine)
//         MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "kioskModeLocked").setMethodCallHandler { call, result ->
//             if (call.method == "stopKioskMode") {
//                 stopKioskMode()
//                 result.success(null)
//             } else {
//                 result.notImplemented()
//             }
//         }
//     }

//     private fun stopKioskMode() {
//         stopLockTask()
//         val intent = Intent(this, MainActivity::class.java)
//         startActivity(intent)
//         finish()
//     }
// }

package com.example.pickleapp

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class KioskActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Set content view or perform necessary operations for KioskActivity
    }
}
