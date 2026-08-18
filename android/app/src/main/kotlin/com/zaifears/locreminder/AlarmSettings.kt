package com.zaifears.locreminder

import android.content.Context
import android.media.RingtoneManager
import android.net.Uri
import android.provider.OpenableColumns
import android.util.Log

/**
 * The user's alarm sound and vibration choices.
 *
 * Kept in its own SharedPreferences file, read directly by the alarm
 * service, so the sound is available without the Flutter engine being
 * alive — the alarm has to ring correctly when the app is long gone.
 */
class AlarmSettings(private val context: Context) {

    private val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    /** Stored sound, or null when the system default alarm should be used. */
    fun soundUri(): Uri? {
        val raw = prefs.getString(KEY_SOUND_URI, null) ?: return null
        return try {
            Uri.parse(raw)
        } catch (e: Exception) {
            Log.w(TAG, "Stored alarm sound URI is unparseable; using default", e)
            null
        }
    }

    fun soundName(): String? = prefs.getString(KEY_SOUND_NAME, null)

    fun vibrationEnabled(): Boolean = prefs.getBoolean(KEY_VIBRATE, true)

    fun setSound(uri: Uri?, name: String?) {
        prefs.edit().apply {
            if (uri == null) {
                remove(KEY_SOUND_URI)
                remove(KEY_SOUND_NAME)
            } else {
                putString(KEY_SOUND_URI, uri.toString())
                putString(KEY_SOUND_NAME, name)
            }
        }.apply()
    }

    fun setVibrationEnabled(enabled: Boolean) {
        prefs.edit().putBoolean(KEY_VIBRATE, enabled).apply()
    }

    /**
     * The URI the alarm should actually play, falling back to the system
     * alarm tone. A custom sound can become unreadable at any time — the
     * file is deleted, an SD card is unmounted, or the SAF grant is revoked
     * — and an alarm that goes silent because of that is worse than one that
     * rings with the wrong tone.
     */
    fun resolvePlayableUri(): Uri? {
        val custom = soundUri()
        if (custom != null && isReadable(custom)) return custom
        if (custom != null) {
            Log.w(TAG, "Custom alarm sound is no longer readable; falling back to default")
        }
        return RingtoneManager.getActualDefaultRingtoneUri(context, RingtoneManager.TYPE_ALARM)
            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
    }

    private fun isReadable(uri: Uri): Boolean {
        return try {
            context.contentResolver.openInputStream(uri)?.use { true } ?: false
        } catch (e: Exception) {
            false
        }
    }

    companion object {
        private const val TAG = "AlarmSettings"
        private const val PREFS_NAME = "locreminder_alarm_settings"
        private const val KEY_SOUND_URI = "sound_uri"
        private const val KEY_SOUND_NAME = "sound_name"
        private const val KEY_VIBRATE = "vibrate"

        /** Best-effort human-readable name for a sound URI. */
        fun displayNameFor(context: Context, uri: Uri): String {
            // Files picked through the document picker carry their filename.
            try {
                context.contentResolver.query(uri, null, null, null, null)?.use { cursor ->
                    val index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                    if (index >= 0 && cursor.moveToFirst()) {
                        val name = cursor.getString(index)
                        if (!name.isNullOrBlank()) return name.substringBeforeLast('.')
                    }
                }
            } catch (e: Exception) {
                Log.d(TAG, "No display name column for $uri", e)
            }

            // Ringtones picked from the system picker expose a title instead.
            return try {
                RingtoneManager.getRingtone(context, uri)?.getTitle(context) ?: "Custom sound"
            } catch (e: Exception) {
                "Custom sound"
            }
        }
    }
}
