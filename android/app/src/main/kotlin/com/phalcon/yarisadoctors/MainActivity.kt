package com.phalcon.yarisadoctors

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    ensureNotificationChannels()
  }

  private fun ensureNotificationChannels() {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
    val manager = getSystemService(NotificationManager::class.java) ?: return

    val channels = listOf(
      NotificationChannel(
        "yarisa_doctor_general",
        "General Notifications",
        NotificationManager.IMPORTANCE_DEFAULT,
      ),
      NotificationChannel(
        "yarisa_doctor_calls",
        "Incoming Calls",
        NotificationManager.IMPORTANCE_HIGH,
      ),
      // Jitsi ongoing conference FGS notification channel id used by the SDK.
      NotificationChannel(
        "JitsiOngoingConferenceChannel",
        "Ongoing call",
        NotificationManager.IMPORTANCE_LOW,
      ).apply {
        description = "Shown while a video or voice call is in progress"
        setShowBadge(false)
      },
    )
    channels.forEach(manager::createNotificationChannel)
  }
}
