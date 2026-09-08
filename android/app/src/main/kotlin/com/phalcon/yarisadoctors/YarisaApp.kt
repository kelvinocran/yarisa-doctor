package com.phalcon.yarisadoctors

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build

/**
 * Creates notification channels as early as possible (before CallKit / Jitsi).
 */
class YarisaApp : Application() {
  override fun onCreate() {
    super.onCreate()
    ensureNotificationChannels()
  }

  private fun ensureNotificationChannels() {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
    val manager = getSystemService(NotificationManager::class.java) ?: return
    listOf(
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
      NotificationChannel(
        "JitsiOngoingConferenceChannel",
        "Ongoing call",
        NotificationManager.IMPORTANCE_DEFAULT,
      ).apply {
        description = "Shown while a video or voice call is in progress"
        setShowBadge(false)
      },
    ).forEach(manager::createNotificationChannel)
  }
}
