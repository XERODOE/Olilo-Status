package uk.co.olilo.status.notifications

import android.content.Context
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json

/** Mirrors the backend's per-device preference shape. */
@Serializable
data class NotificationPreferences(
    val incidents: Boolean = true,
    val maintenance: Boolean = true,
    val componentAlerts: Boolean = false,
    /** Networks to receive component-level alerts for. Empty = all networks. */
    val networks: List<String> = emptyList(),
)

/** Persists notification preferences, the enabled flag, and the FCM token. */
object NotificationStore {
    private const val PREFS = "olilo_notifications"
    private const val KEY_PREFERENCES = "preferences"
    private const val KEY_ENABLED = "enabled"
    private const val KEY_TOKEN = "fcm_token"

    private val json = Json { ignoreUnknownKeys = true }

    fun preferences(context: Context): NotificationPreferences {
        val raw = prefs(context).getString(KEY_PREFERENCES, null) ?: return NotificationPreferences()
        return runCatching { json.decodeFromString<NotificationPreferences>(raw) }
            .getOrDefault(NotificationPreferences())
    }

    fun savePreferences(context: Context, preferences: NotificationPreferences) {
        prefs(context).edit().putString(KEY_PREFERENCES, json.encodeToString(preferences)).apply()
    }

    fun isEnabled(context: Context): Boolean = prefs(context).getBoolean(KEY_ENABLED, false)

    fun setEnabled(context: Context, enabled: Boolean) {
        prefs(context).edit().putBoolean(KEY_ENABLED, enabled).apply()
    }

    fun token(context: Context): String? = prefs(context).getString(KEY_TOKEN, null)

    fun saveToken(context: Context, token: String) {
        prefs(context).edit().putString(KEY_TOKEN, token).apply()
    }

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
}
