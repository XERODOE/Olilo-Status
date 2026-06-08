package uk.co.olilo.status

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.core.net.toUri
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.OpenInNew
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Dashboard
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.Error
import androidx.compose.material.icons.filled.Gavel
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Language
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material.icons.filled.Work
import androidx.compose.material3.AssistChip
import androidx.compose.material3.AssistChipDefaults
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ListItemDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            OliloStatusTheme {
                OliloApp()
            }
        }
    }
}

private enum class Route(val path: String, val label: String, val icon: ImageVector) {
    Status("status", "Status", Icons.Filled.Dashboard),
    Notices("notices", "Notices", Icons.Filled.Notifications),
    Settings("settings", "Settings", Icons.Filled.Settings),
}

@Composable
private fun OliloApp() {
    val navController = rememberNavController()
    val backStack by navController.currentBackStackEntryAsState()
    val currentRoute = backStack?.destination?.route

    GradientBackground {
        Scaffold(
            containerColor = Color.Transparent,
            contentColor = Color.White,
            bottomBar = {
                if (Route.entries.any { it.path == currentRoute }) {
                    NavigationBar(containerColor = Color(0xF20B0612)) {
                        Route.entries.forEach { route ->
                            NavigationBarItem(
                                selected = currentRoute == route.path,
                                onClick = {
                                    navController.navigate(route.path) {
                                        popUpTo(Route.Status.path)
                                        launchSingleTop = true
                                    }
                                },
                                icon = { Icon(route.icon, contentDescription = route.label) },
                                label = { Text(route.label) },
                            )
                        }
                    }
                }
            },
        ) { padding ->
            NavHost(
                navController = navController,
                startDestination = Route.Status.path,
                modifier = Modifier.padding(padding),
            ) {
                composable(Route.Status.path) { StatusScreen(navController) }
                composable(Route.Notices.path) { NoticesScreen(navController) }
                composable(Route.Settings.path) { SettingsScreen(navController) }
                composable("about") { TextPage(navController, "About", aboutText) }
                composable("legal") { TextPage(navController, "Legal Disclaimer", legalText) }
                composable("web/{title}/{url}") { entry ->
                    WebPage(
                        navController = navController,
                        title = Uri.decode(entry.arguments?.getString("title").orEmpty()),
                        url = Uri.decode(entry.arguments?.getString("url").orEmpty()),
                    )
                }
            }
        }
    }
}

private fun NavHostController.openWeb(title: String, url: String) {
    navigate("web/${Uri.encode(title)}/${Uri.encode(url)}")
}

@Composable
private fun OliloStatusTheme(content: @Composable () -> Unit) {
    val colorScheme = androidx.compose.material3.darkColorScheme(
        primary = OliloPurple,
        secondary = Color(0xFF64B5F6),
        background = OliloBackgroundTop,
        surface = Color(0xD91A1025),
        surfaceVariant = Color(0xE6261737),
        onPrimary = Color.White,
        onSurface = Color.White,
        onSurfaceVariant = Color(0xFFE2D8EA),
    )
    MaterialTheme(colorScheme = colorScheme, content = content)
}

@Composable
private fun GradientBackground(content: @Composable () -> Unit) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(
                Brush.linearGradient(
                    listOf(OliloBackgroundTop, OliloBackgroundMid, OliloBackgroundBottom),
                ),
            ),
    ) {
        content()
    }
}

@Composable
private fun OliloTopBar(
    title: String,
    onRefresh: (() -> Unit)? = null,
    navController: NavHostController? = null,
) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .windowInsetsPadding(WindowInsets.statusBars)
            .height(48.dp),
    ) {
        if (navController != null) {
            IconButton(
                onClick = { navController.popBackStack() },
                modifier = Modifier.align(Alignment.CenterStart),
            ) {
                Icon(
                    Icons.AutoMirrored.Filled.ArrowBack,
                    contentDescription = "Back",
                    tint = OliloPurple,
                )
            }
        }
        Box(Modifier.align(Alignment.Center)) {
            Image(
                painter = painterResource(R.drawable.olilo),
                contentDescription = "Olilo $title",
                contentScale = ContentScale.Fit,
                modifier = Modifier.height(24.dp),
            )
        }
        if (onRefresh != null) {
            IconButton(
                onClick = onRefresh,
                modifier = Modifier.align(Alignment.CenterEnd),
            ) {
                Icon(
                    Icons.Filled.Refresh,
                    contentDescription = "Refresh",
                    tint = OliloPurple,
                )
            }
        }
    }
}

@Composable
private fun OpenUrlButton(
    label: String,
    url: String,
    navController: NavHostController,
    icon: ImageVector = Icons.AutoMirrored.Filled.OpenInNew,
) {
    AssistChip(
        onClick = { navController.openWeb(label, url) },
        label = { Text(label, color = Color.White) },
        leadingIcon = { Icon(icon, contentDescription = null, modifier = Modifier.size(18.dp)) },
        colors = AssistChipDefaults.assistChipColors(
            labelColor = Color.White,
            leadingIconContentColor = OliloPurple,
            containerColor = Color(0x332B1C3D),
        ),
    )
}

@Composable
private fun ExternalUrlButton(
    label: String,
    url: String,
    icon: ImageVector = Icons.AutoMirrored.Filled.OpenInNew,
) {
    val context = LocalContext.current
    AssistChip(
        onClick = { context.startActivity(Intent(Intent.ACTION_VIEW, url.toUri())) },
        label = { Text(label, color = Color.White) },
        leadingIcon = { Icon(icon, contentDescription = null, modifier = Modifier.size(18.dp)) },
        colors = AssistChipDefaults.assistChipColors(
            labelColor = Color.White,
            leadingIconContentColor = OliloPurple,
            containerColor = Color(0x332B1C3D),
        ),
    )
}

@Composable
private fun StatusCard(content: @Composable () -> Unit) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(20.dp),
        colors = CardDefaults.cardColors(
            containerColor = Color(0xB3261737),
            contentColor = Color.White,
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp),
    ) {
        Box(modifier = Modifier.padding(18.dp)) {
            content()
        }
    }
}

@Composable
private fun SectionHeader(title: String, count: Int, action: (@Composable () -> Unit)? = null) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 2.dp),
    ) {
        Text(title, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
        Spacer(Modifier.width(8.dp))
        Text("$count", style = MaterialTheme.typography.labelMedium, color = Color(0xFFCEC1D8))
        Spacer(Modifier.weight(1f))
        action?.invoke()
    }
}

@Composable
private fun LoadingOrError(
    loadingText: String,
    errorTitle: String,
    isLoading: Boolean,
    errorMessage: String?,
    onRetry: () -> Unit,
) {
    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        when {
            isLoading -> Column(horizontalAlignment = Alignment.CenterHorizontally) {
                CircularProgressIndicator(color = OliloPurple)
                Spacer(Modifier.height(12.dp))
                Text(loadingText)
            }
            errorMessage != null -> Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(12.dp),
                modifier = Modifier.padding(24.dp),
            ) {
                Icon(Icons.Filled.Warning, contentDescription = null, tint = Color(0xFFFFB74D))
                Text(errorTitle, style = MaterialTheme.typography.titleMedium)
                Text(errorMessage, color = Color(0xFFCEC1D8))
                Button(onClick = onRetry) { Text("Retry") }
            }
        }
    }
}

@Composable
private fun StatusScreen(navController: NavHostController, viewModel: StatusViewModel = viewModel()) {
    val state by viewModel.state.collectAsStateWithLifecycle()

    Column(Modifier.fillMaxSize()) {
        OliloTopBar(title = "Status", onRefresh = viewModel::refresh)
        if ((state.isLoading && state.summary == null) || state.errorMessage != null) {
            LoadingOrError(
                loadingText = "Loading status...",
                errorTitle = "Failed to load status",
                isLoading = state.isLoading && state.summary == null,
                errorMessage = state.errorMessage,
                onRetry = viewModel::refresh,
            )
            return@Column
        }

        LazyColumn(
            contentPadding = androidx.compose.foundation.layout.PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            state.summary?.let { summary ->
                item {
                    OverviewCard(summary, state, navController)
                }
                val affected = state.components
                    .filter { statusSeverity(it.status) > 0 }
                    .sortedByDescending { statusSeverity(it.status) }
                if (affected.isNotEmpty()) {
                    item { SectionHeader("Affected Services", affected.size) }
                    item {
                        StatusCard {
                            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                                affected.forEach { ComponentRow(it, showGroup = true) }
                            }
                        }
                    }
                }
            }

            if (state.incidents.isNotEmpty()) {
                item { SectionHeader("Active Incidents", state.incidents.size) }
                items(state.incidents, key = { it.id }) { incident -> IncidentCard(incident, navController) }
            }

            if (state.maintenances.isNotEmpty()) {
                item { SectionHeader("Maintenance", state.maintenances.size) }
                items(state.maintenances, key = { it.id }) { maintenance -> MaintenanceCard(maintenance, navController) }
            }

            item {
                SectionHeader("Components", state.components.size) {
                    ExternalUrlButton(
                        label = "Dashboard",
                        url = "https://dashboard.as212683.net/d/olilo-traffic-analytics-001/traffic-analytics?orgId=2&from=now-1h&to=now&timezone=browser",
                        icon = Icons.Filled.Language,
                    )
                }
            }
            items(groupedComponents(state.components), key = { it.id }) { group ->
                ComponentGroupCard(group)
            }
        }
    }
}

@Composable
private fun OverviewCard(summary: StatusPageSummary, state: StatusScreenState, navController: NavHostController) {
    StatusCard {
        Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
            Row(verticalAlignment = Alignment.Top) {
                Icon(
                    if (statusSeverity(summary.page.status) == 0) Icons.Filled.CheckCircle else Icons.Filled.Error,
                    contentDescription = null,
                    tint = statusColor(summary.page.status),
                    modifier = Modifier.size(38.dp),
                )
                Spacer(Modifier.width(12.dp))
                Column(Modifier.weight(1f)) {
                    Text("Olilo Network Status", style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
                    Text(
                        if (statusSeverity(summary.page.status) == 0) "All systems operational" else readableStatus(summary.page.status),
                        color = Color(0xFFCEC1D8),
                    )
                }
            }

            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                MetricTile("Components", state.components.size.toString(), Modifier.weight(1f))
                MetricTile("Affected", state.components.count { statusSeverity(it.status) > 0 }.toString(), Modifier.weight(1f))
            }
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                MetricTile("Incidents", state.incidents.size.toString(), Modifier.weight(1f))
                MetricTile("Maintenance", state.maintenances.size.toString(), Modifier.weight(1f))
            }

            Row(verticalAlignment = Alignment.CenterVertically) {
                OpenUrlButton("Olilo Status", summary.page.url, navController, Icons.Filled.Dashboard)
                Spacer(Modifier.weight(1f))
                formatTime(state.lastRefreshedMillis)?.let {
                    Text("Updated $it", style = MaterialTheme.typography.labelMedium, color = Color(0xFFCEC1D8))
                }
            }
        }
    }
}

@Composable
private fun MetricTile(title: String, value: String, modifier: Modifier = Modifier) {
    Surface(
        modifier = modifier.height(72.dp),
        shape = RoundedCornerShape(14.dp),
        color = Color(0x592B1C3D),
        contentColor = Color.White,
    ) {
        Column(Modifier.padding(12.dp), verticalArrangement = Arrangement.SpaceBetween) {
            Text(title, style = MaterialTheme.typography.labelMedium, color = Color(0xFFCEC1D8))
            Text(value, style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
        }
    }
}

@Composable
private fun IncidentCard(incident: Incident, navController: NavHostController) {
    StatusCard {
        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            TitleStatusRow(incident.name, readableStatus(incident.status), incident.impact ?: incident.status)
            DetailRows(
                listOf(
                    "Started" to formatRemoteDate(incident.started),
                    "Updated" to formatRemoteDate(incident.updatedAt),
                    "ID" to incident.id,
                ),
            )
            incident.description?.takeIf { it.isNotBlank() }?.let { ExpandableDescription(it) }
            incident.url?.let { OpenUrlButton("Open incident", it, navController) }
        }
    }
}

@Composable
private fun MaintenanceCard(maintenance: Maintenance, navController: NavHostController) {
    StatusCard {
        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            TitleStatusRow(maintenance.name, readableStatus(maintenance.status), maintenance.status)
            DetailRows(
                listOf(
                    "Start" to formatRemoteDate(maintenance.start),
                    "Duration" to maintenance.duration?.let { "$it minutes" },
                    "Updated" to formatRemoteDate(maintenance.updatedAt),
                    "ID" to maintenance.id,
                ),
            )
            maintenance.url?.let { OpenUrlButton("Open maintenance", it, navController) }
        }
    }
}

@Composable
private fun ComponentGroupCard(group: StatusComponentGroup) {
    StatusCard {
        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            TitleStatusRow(
                title = group.name,
                subtitle = group.description ?: "${group.allComponents.size} service${if (group.allComponents.size == 1) "" else "s"}",
                status = group.worstStatus,
            )
            val visible = if (group.parent != null && group.children.isEmpty()) listOf(group.parent) else group.children
            visible.filterNotNull().forEach { ComponentRow(it, showGroup = false) }
        }
    }
}

@Composable
private fun ComponentRow(component: StatusComponent, showGroup: Boolean) {
    Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.fillMaxWidth()) {
        StatusDot(component.status, 8)
        Spacer(Modifier.width(10.dp))
        Column(Modifier.weight(1f)) {
            Text(component.name, fontWeight = FontWeight.SemiBold, maxLines = 1, overflow = TextOverflow.Ellipsis)
            val detail = buildList {
                add(readableStatus(component.status))
                if (showGroup) component.group?.name?.let(::add)
                component.description?.takeIf { it.isNotBlank() }?.let(::add)
            }.joinToString(" - ")
            Text(detail, style = MaterialTheme.typography.labelMedium, color = Color(0xFFCEC1D8), maxLines = 2)
        }
        StatusBadge(readableStatus(component.status), component.status)
    }
}

@Composable
private fun NoticesScreen(navController: NavHostController, viewModel: NoticesViewModel = viewModel()) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    val filtered = state.selectedKind?.let { selected -> state.notices.filter { it.kind == selected } } ?: state.notices

    Column(Modifier.fillMaxSize()) {
        OliloTopBar(title = "Notices", onRefresh = viewModel::refresh)
        if ((state.isLoading && state.notices.isEmpty()) || state.errorMessage != null) {
            LoadingOrError(
                loadingText = "Loading notices...",
                errorTitle = "Failed to load notices",
                isLoading = state.isLoading && state.notices.isEmpty(),
                errorMessage = state.errorMessage,
                onRetry = viewModel::refresh,
            )
            return@Column
        }

        LazyColumn(
            contentPadding = androidx.compose.foundation.layout.PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            val activeCount = state.activeIncidents.size + state.activeMaintenances.size
            if (activeCount > 0) {
                item { SectionHeader("Current Notices", activeCount) }
                items(state.activeIncidents, key = { it.id }) { ActiveIncidentNoticeCard(it, navController) }
                items(state.activeMaintenances, key = { it.id }) { ActiveMaintenanceNoticeCard(it, navController) }
            }

            item {
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    NoticeFilterChip(selected = state.selectedKind == null, label = "All") { viewModel.selectKind(null) }
                    NoticeFilterChip(selected = state.selectedKind == NoticeKind.Incident, label = "Incident") { viewModel.selectKind(NoticeKind.Incident) }
                    NoticeFilterChip(selected = state.selectedKind == NoticeKind.Maintenance, label = "Maintenance") { viewModel.selectKind(NoticeKind.Maintenance) }
                }
            }
            item { SectionHeader("Notice History", filtered.size) }
            items(filtered, key = { it.id }) { NoticeHistoryCard(it, navController) }
        }
    }
}

@Composable
private fun ActiveIncidentNoticeCard(incident: Incident, navController: NavHostController) {
    StatusCard {
        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            NoticeTitleRow(incident.name, "Incident", Icons.Filled.Warning, incident.impact ?: incident.status)
            DetailRows(
                listOf(
                    "Status" to readableStatus(incident.status),
                    "Impact" to incident.impact?.let(::readableStatus),
                    "Started" to formatRemoteDate(incident.started),
                    "Updated" to formatRemoteDate(incident.updatedAt),
                ),
            )
            incident.description?.takeIf { it.isNotBlank() }?.let { ExpandableDescription(it) }
            incident.url?.let { OpenUrlButton("Open incident", it, navController) }
        }
    }
}

@Composable
private fun NoticeFilterChip(selected: Boolean, label: String, onClick: () -> Unit) {
    FilterChip(
        selected = selected,
        onClick = onClick,
        label = { Text(label) },
        colors = FilterChipDefaults.filterChipColors(
            labelColor = Color.White,
            selectedLabelColor = Color.White,
            containerColor = Color(0x332B1C3D),
            selectedContainerColor = OliloPurple.copy(alpha = 0.35f),
        ),
    )
}

@Composable
private fun ExpandableDescription(text: String, collapsedLines: Int = 4) {
    var expanded by remember(text) { mutableStateOf(false) }

    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
        Text(
            text,
            maxLines = if (expanded) Int.MAX_VALUE else collapsedLines,
            overflow = TextOverflow.Ellipsis,
        )
        AssistChip(
            onClick = { expanded = !expanded },
            label = { Text(if (expanded) "Show less" else "Show more") },
            colors = AssistChipDefaults.assistChipColors(
                labelColor = Color.White,
                containerColor = Color(0x332B1C3D),
            ),
        )
    }
}

@Composable
private fun ActiveMaintenanceNoticeCard(maintenance: Maintenance, navController: NavHostController) {
    StatusCard {
        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            NoticeTitleRow(maintenance.name, "Maintenance", Icons.Filled.Work, maintenance.status)
            DetailRows(
                listOf(
                    "Status" to readableStatus(maintenance.status),
                    "Start" to formatRemoteDate(maintenance.start),
                    "Duration" to maintenance.duration?.let { "$it minutes" },
                    "Updated" to formatRemoteDate(maintenance.updatedAt),
                ),
            )
            maintenance.url?.let { OpenUrlButton("Open maintenance", it, navController) }
        }
    }
}

@Composable
private fun NoticeHistoryCard(notice: StatusNotice, navController: NavHostController) {
    var descriptionExpanded by remember(notice.id) { mutableStateOf(false) }
    var updatesExpanded by remember(notice.id) { mutableStateOf(false) }

    StatusCard {
        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            NoticeTitleRow(
                notice.title,
                notice.kind.label,
                if (notice.kind == NoticeKind.Maintenance) Icons.Filled.Work else Icons.Filled.Notifications,
                if (notice.kind == NoticeKind.Maintenance) "UNDERMAINTENANCE" else "PARTIALOUTAGE",
            )
            DetailRows(
                listOf(
                    "Published" to formatRemoteDate(notice.published),
                    "Updated" to formatRemoteDate(notice.updated),
                    "Duration" to notice.duration,
                    "Components" to notice.affectedComponents,
                ),
            )
            Text(
                notice.summary,
                maxLines = if (descriptionExpanded) Int.MAX_VALUE else 5,
                overflow = TextOverflow.Ellipsis,
            )
            notice.updates.takeIf { it.isNotEmpty() }?.let { updates ->
                if (updatesExpanded) {
                    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        updates.forEach { update ->
                            Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                                Text(update.status, color = statusColor(update.status), fontWeight = FontWeight.Bold, style = MaterialTheme.typography.labelMedium)
                                Text(update.message, style = MaterialTheme.typography.labelMedium, color = Color(0xFFCEC1D8))
                            }
                        }
                    }
                }
            }
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                modifier = Modifier.horizontalScroll(rememberScrollState()),
            ) {
                AssistChip(
                    onClick = { descriptionExpanded = !descriptionExpanded },
                    label = { Text(if (descriptionExpanded) "Show less" else "Show more") },
                    colors = AssistChipDefaults.assistChipColors(
                        labelColor = Color.White,
                        containerColor = Color(0x332B1C3D),
                    ),
                )
                notice.updates.takeIf { it.isNotEmpty() }?.let { updates ->
                    AssistChip(
                        onClick = { updatesExpanded = !updatesExpanded },
                        label = { Text("${updates.size} update${if (updates.size == 1) "" else "s"}") },
                        colors = AssistChipDefaults.assistChipColors(
                            labelColor = Color.White,
                            containerColor = OliloPurple.copy(alpha = 0.25f),
                        ),
                    )
                }
                notice.link?.let { OpenUrlButton("Open notice", it, navController) }
            }
        }
    }
}

@Composable
private fun NoticeTitleRow(title: String, subtitle: String, icon: ImageVector, status: String) {
    Row(verticalAlignment = Alignment.Top) {
        Icon(icon, contentDescription = null, tint = OliloPurple, modifier = Modifier.size(24.dp))
        Spacer(Modifier.width(10.dp))
        Column(Modifier.weight(1f)) {
            Text(title, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
            Text(subtitle, style = MaterialTheme.typography.labelMedium, color = Color(0xFFCEC1D8))
        }
        StatusBadge(readableStatus(status), status)
    }
}

@Composable
private fun TitleStatusRow(title: String, subtitle: String, status: String) {
    Row(verticalAlignment = Alignment.Top) {
        StatusDot(status, 10)
        Spacer(Modifier.width(10.dp))
        Column(Modifier.weight(1f)) {
            Text(title, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
            Text(subtitle, style = MaterialTheme.typography.labelMedium, color = Color(0xFFCEC1D8))
        }
        StatusBadge(readableStatus(status), status)
    }
}

@Composable
private fun StatusDot(status: String, size: Int) {
    Box(
        Modifier
            .size(size.dp)
            .clip(CircleShape)
            .background(statusColor(status)),
    )
}

@Composable
private fun StatusBadge(text: String, status: String) {
    Surface(
        shape = RoundedCornerShape(50),
        color = statusColor(status).copy(alpha = 0.16f),
        contentColor = statusColor(status),
    ) {
        Text(
            text,
            color = statusColor(status),
            style = MaterialTheme.typography.labelSmall,
            fontWeight = FontWeight.Bold,
            modifier = Modifier.padding(horizontal = 8.dp, vertical = 5.dp),
            maxLines = 1,
        )
    }
}

@Composable
private fun DetailRows(rows: List<Pair<String, String?>>) {
    val visible = rows.filter { !it.second.isNullOrBlank() }
    if (visible.isEmpty()) return
    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
        visible.forEach { (label, value) ->
            Row {
                Text(label, color = Color(0xFFCEC1D8), style = MaterialTheme.typography.labelMedium, modifier = Modifier.width(96.dp))
                Text(value.orEmpty(), style = MaterialTheme.typography.labelMedium, modifier = Modifier.weight(1f))
            }
        }
    }
}

@Composable
private fun SettingsScreen(navController: NavHostController) {
    Column(Modifier.fillMaxSize()) {
        OliloTopBar(title = "Settings")
        LazyColumn(
            contentPadding = androidx.compose.foundation.layout.PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            item {
                SettingsSection("Social") {
                    SettingsLinkRow("Olilo Status on GitLab", "https://gitlab.com/team-olilo/status-app", Icons.Filled.Language, navController)
                    SettingsLinkRow("Join the Olilo Discord", "https://discord.gg/olilo", Icons.Filled.Language, navController)
                    SettingsLinkRow("Join Olilo on Reddit", "https://www.reddit.com/r/Olilo", Icons.Filled.Language, navController)
                }
            }
            item {
                SettingsSection("Information") {
                    SettingsNavRow("Legal Disclaimer", Icons.Filled.Gavel) { navController.navigate("legal") }
                    SettingsNavRow("About", Icons.Filled.Info) { navController.navigate("about") }
                    SettingsLinkRow("Privacy Policy", "https://olilo.co.uk/privacy", Icons.Filled.Description, navController)
                    SettingsLinkRow("Terms & Conditions", "https://olilo.co.uk/terms", Icons.Filled.Description, navController)
                }
            }
            item {
                StatusCard {
                    Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.fillMaxWidth()) {
                        Image(
                            painter = painterResource(R.drawable.olilo),
                            contentDescription = "Olilo",
                            contentScale = ContentScale.Fit,
                            modifier = Modifier.height(44.dp),
                        )
                        Spacer(Modifier.height(12.dp))
                        Text(
                            "(c) 2026 Olilo UK & Ireland Ltd. Company number: 16352417",
                            color = Color(0xFFCEC1D8),
                            style = MaterialTheme.typography.bodySmall,
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun SettingsSection(title: String, content: @Composable ColumnScope.() -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text(title, style = MaterialTheme.typography.titleSmall, color = Color(0xFFCEC1D8), modifier = Modifier.padding(horizontal = 4.dp))
        StatusCard {
            Column(verticalArrangement = Arrangement.spacedBy(4.dp), content = content)
        }
    }
}

@Composable
private fun SettingsLinkRow(title: String, url: String, icon: ImageVector, navController: NavHostController) {
    SettingsRow(title, icon) {
        navController.openWeb(title, url)
    }
}

@Composable
private fun SettingsNavRow(title: String, icon: ImageVector, onClick: () -> Unit) {
    SettingsRow(title, icon, onClick)
}

@Composable
private fun SettingsRow(title: String, icon: ImageVector, onClick: () -> Unit) {
    androidx.compose.material3.ListItem(
        headlineContent = { Text(title, color = OliloPurple) },
        leadingContent = { Icon(icon, contentDescription = null, tint = OliloPurple) },
        colors = ListItemDefaults.colors(
            containerColor = Color.Transparent,
            headlineColor = Color.White,
            leadingIconColor = OliloPurple,
        ),
        modifier = Modifier
            .clip(RoundedCornerShape(12.dp))
            .background(Color.Transparent)
            .clickable(onClick = onClick),
    )
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .height(1.dp)
            .background(Color.White.copy(alpha = 0.06f)),
    )
}

@Composable
private fun WebPage(navController: NavHostController, title: String, url: String) {
    Column(Modifier.fillMaxSize()) {
        OliloTopBar(title = title, navController = navController)
        AndroidView(
            factory = { context ->
                WebView(context).apply {
                    webViewClient = WebViewClient()
                    settings.javaScriptEnabled = true
                    settings.domStorageEnabled = true
                    loadUrl(url)
                }
            },
            update = {},
            modifier = Modifier.fillMaxSize(),
        )
    }
}

@Composable
private fun TextPage(navController: NavHostController, title: String, body: String) {
    Column(Modifier.fillMaxSize()) {
        OliloTopBar(title = title, navController = navController)
        Column(
            modifier = Modifier
                .verticalScroll(rememberScrollState())
                .padding(16.dp)
                .fillMaxWidth(),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            Text("Olilo Status", style = MaterialTheme.typography.titleMedium, color = Color(0xFFCEC1D8))
            StatusCard {
                Text(body)
            }
            Spacer(Modifier.height(44.dp))
            Image(
                painter = painterResource(R.drawable.olilo),
                contentDescription = "Olilo",
                contentScale = ContentScale.Fit,
                modifier = Modifier
                    .height(36.dp)
                    .align(Alignment.CenterHorizontally),
            )
        }
    }
}

private const val aboutText = """Olilo Status is built for fast and simple access for checking the current status of the Olilo Network,
Services, Planned Maintenance & Updates.

Olilo Status is built by Aaron Doe and published by Olilo UK & Ireland Ltd.

This application is Open Source and full source code is available on the Olilo Team GitLab."""

private const val legalText = """This application is developed by Aaron Doe and it's contents are owned by Olilo UK & Ireland Ltd.

Aaron Doe (developer) is in no way affiliated with Olilo (company) other than the development of this application.

Unauthorized copying, modification, distribution, or reverse engineering of any part of this application is prohibited except where permitted by law.

(c) 2026 Olilo UK & Ireland Ltd. All rights reserved.

Company Number: 16352417 (Olilo UK & Ireland Ltd.)

For legal enquiries, please contact Olilo directly."""
