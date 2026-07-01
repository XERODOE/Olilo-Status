package uk.co.olilo.status.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import kotlinx.serialization.json.Json
import uk.co.olilo.status.status.ComponentsResponse
import uk.co.olilo.status.main.MainActivity
import uk.co.olilo.status.R
import uk.co.olilo.status.status.StatusComponent
import java.net.HttpURLConnection
import java.net.URL
import java.util.Locale
import kotlin.concurrent.thread

class OliloStatusWidgetProvider : AppWidgetProvider() {
    /** Refreshes every widget instance when Android requests an update. */
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        appWidgetIds.forEach { appWidgetId -> refreshWidget(context, appWidgetManager, appWidgetId) }
    }

    /** Removes stored configuration for widget instances that were deleted. */
    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        val editor = context.getSharedPreferences(WIDGET_PREFERENCES_NAME, Context.MODE_PRIVATE).edit()
        appWidgetIds.forEach { appWidgetId -> editor.remove(sourceKey(appWidgetId)) }
        editor.apply()
    }

    companion object {
        val sourceNames = listOf("Openreach", "CityFibre", "Freedom Fibre")
        private val json = Json { ignoreUnknownKeys = true }

        /** Persists the selected component source for a widget instance. */
        fun saveSource(context: Context, appWidgetId: Int, sourceName: String) {
            context.getSharedPreferences(WIDGET_PREFERENCES_NAME, Context.MODE_PRIVATE)
                .edit()
                .putString(sourceKey(appWidgetId), sourceName)
                .apply()
        }

        /** Loads the configured source, fetches its status, and updates the widget UI. */
        fun refreshWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            val sourceName = loadSource(context, appWidgetId)
            updateWidget(context, appWidgetManager, appWidgetId, "Loading", sourceName, null)

            thread(name = "OliloStatusWidgetRefresh") {
                val component = fetchWidgetComponent(sourceName)
                val displayState = component?.status?.toWidgetDisplayState()
                val statusText = displayState?.statusText ?: "Unavailable"
                val sourceText = component?.name ?: sourceName
                updateWidget(
                    context,
                    appWidgetManager,
                    appWidgetId,
                    statusText,
                    sourceText,
                    displayState,
                )
            }
        }

        /** Writes the current status values into the widget RemoteViews. */
        private fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
            statusText: String,
            sourceText: String,
            displayState: WidgetStatusDisplayState?,
        ) {
            val statusColor = displayState?.statusColor ?: 0xFFBDB3C7.toInt()
            val views = RemoteViews(context.packageName, R.layout.olilo_status_widget).apply {
                setTextViewText(R.id.widget_status, statusText)
                setTextViewText(R.id.widget_source, sourceText)
                setContentDescription(
                    R.id.widget_root,
                    "Olilo Status widget. $sourceText is $statusText. Opens Olilo Status.",
                )
                setContentDescription(R.id.widget_status_dot, "$sourceText status: $statusText")
                setContentDescription(R.id.widget_timeline, "$sourceText status timeline")
                setInt(R.id.widget_status_dot, "setColorFilter", statusColor)
                setInt(R.id.widget_timeline, "setColorFilter", statusColor)
                setOnClickPendingIntent(R.id.widget_root, launchAppIntent(context))
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        /** Builds the pending intent that opens the main app from the widget. */
        private fun launchAppIntent(context: Context): PendingIntent {
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            return PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }

        /** Fetches the configured component for a widget, returning null on failures. */
        private fun fetchWidgetComponent(sourceName: String): StatusComponent? = runCatching {
            val connection = (URL(COMPONENTS_URL).openConnection() as HttpURLConnection).apply {
                connectTimeout = 15_000
                readTimeout = 15_000
                requestMethod = "GET"
            }
            try {
                val body = connection.inputStream.bufferedReader().use { it.readText() }
                json.decodeFromString<ComponentsResponse>(body)
                    .components
                    .firstOrNull { it.name == sourceName }
            } finally {
                connection.disconnect()
            }
        }.getOrNull()

        /** Loads a widget's selected source, falling back to the default source. */
        private fun loadSource(context: Context, appWidgetId: Int): String =
            context.getSharedPreferences(WIDGET_PREFERENCES_NAME, Context.MODE_PRIVATE)
                .getString(sourceKey(appWidgetId), null)
                ?.takeIf { it in sourceNames }
                ?: sourceNames.first()

        /** Builds the preference key for a widget source selection. */
        private fun sourceKey(appWidgetId: Int): String = "source_$appWidgetId"

        /** Maps backend statuses into the widget's online/offline text and progress color. */
        private fun String.toWidgetDisplayState(): WidgetStatusDisplayState = when (uppercase(Locale.UK)) {
            "UP", "OPERATIONAL" -> WidgetStatusDisplayState.Online
            "HASISSUES", "HAS_ISSUES",
            "DEGRADEDPERFORMANCE", "DEGRADED_PERFORMANCE",
            "PARTIALOUTAGE", "PARTIAL_OUTAGE", "UNDERMAINTENANCE", "UNDER_MAINTENANCE"
            -> WidgetStatusDisplayState.Warning
            else -> WidgetStatusDisplayState.Offline
        }

        private const val COMPONENTS_URL = "https://status.olilo.co.uk/v3/components.json"
        private const val WIDGET_PREFERENCES_NAME = "olilo_status_widget_preferences"
    }
}

private enum class WidgetStatusDisplayState(
    val statusText: String,
    val statusColor: Int,
) {
    Online("Online", 0xFF4CAF50.toInt()),
    Warning("Online", 0xFFFF9800.toInt()),
    Offline("Offline", 0xFFFF5252.toInt()),
}
