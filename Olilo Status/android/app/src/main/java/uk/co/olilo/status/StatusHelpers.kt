package uk.co.olilo.status

import androidx.compose.ui.graphics.Color
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.time.format.FormatStyle
import java.util.Locale

val OliloPurple = Color(0xFFB347FF)
val OliloBackgroundTop = Color(0xFF050108)
val OliloBackgroundMid = Color(0xFF210A3D)
val OliloBackgroundBottom = Color(0xFF4D147A)

fun statusSeverity(status: String): Int = when (status.uppercase(Locale.UK)) {
    "UP", "OPERATIONAL", "RESOLVED", "COMPLETED" -> 0
    "UNDERMAINTENANCE", "MONITORING", "NOTSTARTEDYET" -> 1
    "DEGRADEDPERFORMANCE", "DEGRADED_PERFORMANCE", "IDENTIFIED" -> 2
    "PARTIALOUTAGE", "PARTIAL_OUTAGE", "INVESTIGATING" -> 3
    "MAJOROUTAGE", "MAJOR_OUTAGE" -> 4
    else -> 2
}

fun statusColor(status: String): Color = when (status.uppercase(Locale.UK)) {
    "UP", "OPERATIONAL", "RESOLVED", "COMPLETED" -> OliloPurple
    "UNDERMAINTENANCE", "MONITORING", "NOTSTARTEDYET" -> Color(0xFF64B5F6)
    "DEGRADEDPERFORMANCE", "DEGRADED_PERFORMANCE", "IDENTIFIED" -> Color(0xFFFFB74D)
    "PARTIALOUTAGE", "PARTIAL_OUTAGE", "INVESTIGATING" -> Color(0xFFFFE066)
    "MAJOROUTAGE", "MAJOR_OUTAGE" -> Color(0xFFFF5252)
    else -> Color(0xFFBDB3C7)
}

fun readableStatus(status: String): String = when (status.uppercase(Locale.UK)) {
    "UP" -> "Up"
    "OPERATIONAL" -> "Operational"
    "UNDERMAINTENANCE" -> "Under maintenance"
    "DEGRADEDPERFORMANCE", "DEGRADED_PERFORMANCE" -> "Degraded performance"
    "PARTIALOUTAGE", "PARTIAL_OUTAGE" -> "Partial outage"
    "MAJOROUTAGE", "MAJOR_OUTAGE" -> "Major outage"
    "INVESTIGATING" -> "Investigating"
    "IDENTIFIED" -> "Identified"
    "MONITORING" -> "Monitoring"
    "RESOLVED" -> "Resolved"
    "NOTSTARTEDYET" -> "Not started yet"
    "COMPLETED" -> "Completed"
    else -> status.replace('_', ' ')
        .lowercase(Locale.UK)
        .replaceFirstChar { if (it.isLowerCase()) it.titlecase(Locale.UK) else it.toString() }
}

fun formatRemoteDate(value: String?): String? {
    if (value.isNullOrBlank()) return null
    return runCatching {
        val formatter = DateTimeFormatter.ofLocalizedDateTime(FormatStyle.MEDIUM, FormatStyle.SHORT)
        Instant.parse(value).atZone(ZoneId.systemDefault()).format(formatter)
    }.getOrElse { value }
}

fun formatTime(millis: Long?): String? {
    if (millis == null) return null
    val formatter = DateTimeFormatter.ofLocalizedTime(FormatStyle.SHORT)
    return Instant.ofEpochMilli(millis).atZone(ZoneId.systemDefault()).format(formatter)
}

fun groupedComponents(components: List<StatusComponent>): List<StatusComponentGroup> {
    return componentCategories.mapNotNull { category ->
        val includedIds = mutableSetOf<String>()
        val children = category.componentNames.flatMap { componentName ->
            val parent = components.firstOrNull { it.name.equals(componentName, ignoreCase = true) }
                ?: return@flatMap emptyList()
            listOf(parent) + components
                .filter { child ->
                    child.group?.id == parent.id || child.group?.name.equals(parent.name, ignoreCase = true)
                }
                .sortedBy { it.name }
        }.filter { includedIds.add(it.id) }

        if (children.isEmpty()) {
            null
        } else {
            StatusComponentGroup(
                id = category.id,
                name = category.title,
                description = null,
                parent = null,
                children = children,
            )
        }
    }
}

private data class ComponentCategory(
    val id: String,
    val title: String,
    val componentNames: List<String>,
)

private val componentCategories = listOf(
    ComponentCategory(
        id = "network",
        title = "Network",
        componentNames = listOf("Openreach", "Freedom Fibre", "CityFibre", "MS3", "Telehouse North"),
    ),
    ComponentCategory(
        id = "website",
        title = "Website",
        componentNames = listOf("Prosumer Website", "Consumer Website", "Terminal", "API"),
    ),
    ComponentCategory(
        id = "connections",
        title = "Connections",
        componentNames = listOf("3rd Party"),
    ),
)
