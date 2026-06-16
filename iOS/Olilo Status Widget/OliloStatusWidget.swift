import AppIntents
import Foundation
import SwiftUI
import WidgetKit

enum WidgetStatusSource: String, CaseIterable {
    case openreach
    case cityFibre
    case freedomFibre

    var displayName: String {
        switch self {
        case .openreach: return "Openreach"
        case .cityFibre: return "CityFibre"
        case .freedomFibre: return "Freedom Fibre"
        }
    }

    var componentName: String { displayName }

    var shortName: String {
        switch self {
        case .openreach: return "OR"
        case .cityFibre: return "CF"
        case .freedomFibre: return "FF"
        }
    }

    /// Resolves a persisted picker value into the matching status source.
    static func source(named name: String) -> WidgetStatusSource {
        allCases.first { $0.displayName == name || $0.rawValue == name } ?? .openreach
    }
}

enum WidgetNoticeSource: String, CaseIterable {
    case incidents
    case maintenance

    var displayName: String {
        switch self {
        case .incidents: return "Incidents"
        case .maintenance: return "Maintenance"
        }
    }

    var emptyMessage: String {
        switch self {
        case .incidents: return "No active incidents"
        case .maintenance: return "No planned maintenance"
        }
    }

    var systemImage: String {
        switch self {
        case .incidents: return "exclamationmark.triangle"
        case .maintenance: return "wrench.and.screwdriver"
        }
    }

    /// Resolves a persisted picker value into the matching notice type.
    static func source(named name: String) -> WidgetNoticeSource {
        allCases.first { $0.displayName == name || $0.rawValue == name } ?? .incidents
    }
}

struct WidgetStatusSourceOptionsProvider: DynamicOptionsProvider {
    /// Supplies the network choices shown in the widget configuration picker.
    func results() async throws -> [String] {
        WidgetStatusSource.allCases.map(\.displayName)
    }

    /// Provides Openreach as the fallback when a widget has not been configured.
    func defaultResult() async -> String? {
        WidgetStatusSource.openreach.displayName
    }
}

struct WidgetNoticeSourceOptionsProvider: DynamicOptionsProvider {
    /// Supplies the notice choices shown in the large widget configuration picker.
    func results() async throws -> [String] {
        WidgetNoticeSource.allCases.map(\.displayName)
    }

    /// Provides incidents as the fallback when the large widget has not been configured.
    func defaultResult() async -> String? {
        WidgetNoticeSource.incidents.displayName
    }
}

struct OliloStatusWidgetConfiguration: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Status Source"
    static var description = IntentDescription("Choose which network source the widget uses.")
    static var parameterSummary: some ParameterSummary {
        Summary {
            \.$sourceName
        }
    }

    @Parameter(title: "Source", optionsProvider: WidgetStatusSourceOptionsProvider())
    var sourceName: String?

    /// Creates the default medium-widget configuration used before a user picks a source.
    init() {
        sourceName = nil
    }

    /// Creates an explicit medium-widget configuration for previews and future recommendations.
    init(source: WidgetStatusSource) {
        sourceName = source.displayName
    }

    var resolvedSource: WidgetStatusSource {
        WidgetStatusSource.source(named: sourceName ?? WidgetStatusSource.openreach.displayName)
    }
}

struct OliloNoticesWidgetConfiguration: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Notice Type"
    static var description = IntentDescription("Choose whether the large widget shows incidents or maintenance.")
    static var parameterSummary: some ParameterSummary {
        Summary {
            \.$noticeSourceName
        }
    }

    @Parameter(title: "Show", optionsProvider: WidgetNoticeSourceOptionsProvider())
    var noticeSourceName: String?

    /// Creates the default large-widget configuration used before a user picks a notice type.
    init() {
        noticeSourceName = nil
    }

    /// Creates an explicit large-widget configuration for previews and future recommendations.
    init(noticeSource: WidgetNoticeSource) {
        noticeSourceName = noticeSource.displayName
    }

    var resolvedNoticeSource: WidgetNoticeSource {
        WidgetNoticeSource.source(named: noticeSourceName ?? WidgetNoticeSource.incidents.displayName)
    }
}

struct OliloLockScreenStatusWidgetConfiguration: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Lock Screen Status Source"
    static var description = IntentDescription("Choose which network source the Lock Screen widget uses.")
    static var parameterSummary: some ParameterSummary {
        Summary {
            \.$statusSourceName
        }
    }

    @Parameter(title: "Source", optionsProvider: WidgetStatusSourceOptionsProvider())
    var statusSourceName: String?

    /// Creates the default Lock Screen configuration used before a user picks a source.
    init() {
        statusSourceName = nil
    }

    /// Creates an explicit Lock Screen configuration for previews and future recommendations.
    init(statusSource: WidgetStatusSource) {
        statusSourceName = statusSource.displayName
    }

    var resolvedSource: WidgetStatusSource {
        WidgetStatusSource.source(named: statusSourceName ?? WidgetStatusSource.openreach.displayName)
    }
}

struct OliloStatusEntry: TimelineEntry {
    let date: Date
    let source: WidgetStatusSource
    let status: String

    var isOnline: Bool {
        let normalizedStatus = status.uppercased()
        return normalizedStatus == "UP" || normalizedStatus == "OPERATIONAL"
    }
}

struct OliloNoticesEntry: TimelineEntry {
    let date: Date
    let source: WidgetNoticeSource
    let notices: [OliloWidgetNotice]
    let pageStatus: String
    let didLoadSuccessfully: Bool

    var headline: String {
        notices.first?.title ?? source.emptyMessage
    }
}

struct OliloWidgetNotice: Identifiable, Decodable {
    let id: String
    let title: String
    let status: String
    let impact: String?
    let startDate: Date?
    let updatedAt: Date?
    let duration: Int?

    var detailStatus: String {
        impact ?? status
    }

    var relevantDate: Date? {
        updatedAt ?? startDate
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case status
        case impact
        case started
        case start
        case updatedAt
        case duration
    }

    /// Decodes both incident and maintenance payload shapes into one widget row model.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .name)
        status = try container.decode(String.self, forKey: .status)
        impact = try container.decodeIfPresent(String.self, forKey: .impact)
        startDate = try container.decodeIfPresent(Date.self, forKey: .started)
            ?? container.decodeIfPresent(Date.self, forKey: .start)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
        duration = try container.decodeIfPresent(Int.self, forKey: .duration)
    }

    /// Creates gallery placeholder notices without needing a network response.
    init(id: String, title: String, status: String, impact: String? = nil, startDate: Date? = nil, updatedAt: Date? = nil, duration: Int? = nil) {
        self.id = id
        self.title = title
        self.status = status
        self.impact = impact
        self.startDate = startDate
        self.updatedAt = updatedAt
        self.duration = duration
    }
}

struct OliloStatusProvider: AppIntentTimelineProvider {
    /// Supplies static placeholder content for the widget gallery.
    func placeholder(in context: Context) -> OliloStatusEntry {
        OliloStatusEntry(date: .now, source: .openreach, status: "OPERATIONAL")
    }

    /// Provides a quick preview entry using the selected configuration.
    func snapshot(for configuration: OliloStatusWidgetConfiguration, in context: Context) async -> OliloStatusEntry {
        OliloStatusEntry(date: .now, source: configuration.resolvedSource, status: "OPERATIONAL")
    }

    /// Builds the widget timeline and schedules the next status refresh.
    func timeline(for configuration: OliloStatusWidgetConfiguration, in context: Context) async -> Timeline<OliloStatusEntry> {
        let source = configuration.resolvedSource
        let status = await OliloWidgetStatusClient.fetchNetworkStatus(for: source)
        let entry = OliloStatusEntry(date: .now, source: source, status: status)
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 15, to: .now) ?? .now.addingTimeInterval(900)
        return Timeline(entries: [entry], policy: .after(refreshDate))
    }
}

struct OliloLockScreenStatusProvider: AppIntentTimelineProvider {
    /// Supplies static placeholder content for the Lock Screen widget gallery.
    func placeholder(in context: Context) -> OliloStatusEntry {
        OliloStatusEntry(date: .now, source: .openreach, status: "OPERATIONAL")
    }

    /// Provides a quick preview entry using the selected Lock Screen configuration.
    func snapshot(for configuration: OliloLockScreenStatusWidgetConfiguration, in context: Context) async -> OliloStatusEntry {
        OliloStatusEntry(date: .now, source: configuration.resolvedSource, status: "OPERATIONAL")
    }

    /// Builds the Lock Screen status timeline with its own configuration intent.
    func timeline(for configuration: OliloLockScreenStatusWidgetConfiguration, in context: Context) async -> Timeline<OliloStatusEntry> {
        let source = configuration.resolvedSource
        let status = await OliloWidgetStatusClient.fetchNetworkStatus(for: source)
        let entry = OliloStatusEntry(date: .now, source: source, status: status)
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 15, to: .now) ?? .now.addingTimeInterval(900)
        return Timeline(entries: [entry], policy: .after(refreshDate))
    }
}

private enum OliloWidgetStatusClient {
    /// Fetches the selected network component status, returning UNKNOWN on any failure.
    static func fetchNetworkStatus(for source: WidgetStatusSource) async -> String {
        guard let url = URL(string: "https://status.olilo.co.uk/v3/components.json") else {
            return "UNKNOWN"
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard
                let httpResponse = response as? HTTPURLResponse,
                (200..<300).contains(httpResponse.statusCode)
            else {
                return "UNKNOWN"
            }
            let result = try JSONDecoder().decode(OliloWidgetComponentsResponse.self, from: data)
            return result.components.first { $0.name == source.componentName }?.status ?? "UNKNOWN"
        } catch {
            return "UNKNOWN"
        }
    }
}

struct OliloNoticesProvider: AppIntentTimelineProvider {
    /// Supplies large-widget gallery content that demonstrates both the list and summary layout.
    func placeholder(in context: Context) -> OliloNoticesEntry {
        OliloNoticesEntry(
            date: .now,
            source: .incidents,
            notices: [
                OliloWidgetNotice(id: "placeholder-1", title: "Network performance issue", status: "INVESTIGATING", impact: "Partial outage", updatedAt: .now),
                OliloWidgetNotice(id: "placeholder-2", title: "Elevated latency", status: "IDENTIFIED", impact: "Degraded performance", updatedAt: .now)
            ],
            pageStatus: "HASISSUES",
            didLoadSuccessfully: true
        )
    }

    /// Provides a quick preview entry using the selected notice type.
    func snapshot(for configuration: OliloNoticesWidgetConfiguration, in context: Context) async -> OliloNoticesEntry {
        OliloNoticesEntry(
            date: .now,
            source: configuration.resolvedNoticeSource,
            notices: [OliloWidgetNotice(id: "snapshot", title: configuration.resolvedNoticeSource.emptyMessage, status: "OPERATIONAL", updatedAt: .now)],
            pageStatus: "OPERATIONAL",
            didLoadSuccessfully: true
        )
    }

    /// Builds the notice timeline and refreshes periodically so active notices stay current.
    func timeline(for configuration: OliloNoticesWidgetConfiguration, in context: Context) async -> Timeline<OliloNoticesEntry> {
        let entry = await fetchNotices(for: configuration.resolvedNoticeSource)
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 15, to: .now) ?? .now.addingTimeInterval(900)
        return Timeline(entries: [entry], policy: .after(refreshDate))
    }

    /// Fetches status summary and selects the configured incident or maintenance collection.
    private func fetchNotices(for source: WidgetNoticeSource) async -> OliloNoticesEntry {
        guard let url = URL(string: "https://status.olilo.co.uk/v3/summary.json") else {
            return failedEntry(source: source)
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard
                let httpResponse = response as? HTTPURLResponse,
                (200..<300).contains(httpResponse.statusCode)
            else {
                return failedEntry(source: source)
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let summary = try decoder.decode(OliloWidgetSummaryResponse.self, from: data)
            let notices = source == .incidents ? (summary.activeIncidents ?? []) : (summary.activeMaintenances ?? [])
            return OliloNoticesEntry(
                date: .now,
                source: source,
                notices: notices,
                pageStatus: summary.page.status,
                didLoadSuccessfully: true
            )
        } catch {
            return failedEntry(source: source)
        }
    }

    /// Builds a consistent failure entry that the widget can render without crashing.
    private func failedEntry(source: WidgetNoticeSource) -> OliloNoticesEntry {
        OliloNoticesEntry(date: .now, source: source, notices: [], pageStatus: "UNKNOWN", didLoadSuccessfully: false)
    }
}

private struct OliloWidgetComponentsResponse: Decodable {
    let components: [OliloWidgetComponent]
}

private struct OliloWidgetComponent: Decodable {
    let name: String
    let status: String
}

private struct OliloWidgetSummaryResponse: Decodable {
    struct Page: Decodable {
        let status: String
    }

    let page: Page
    let activeIncidents: [OliloWidgetNotice]?
    let activeMaintenances: [OliloWidgetNotice]?
}

struct OliloStatusWidgetView: View {
    let entry: OliloStatusEntry

    @Environment(\.widgetRenderingMode) private var widgetRenderingMode
    @Environment(\.colorScheme) private var colorScheme

    private var statusText: String {
        entry.isOnline ? "Online" : "Offline"
    }

    private var statusColor: Color {
        entry.isOnline ? .green : .red
    }

    private var isDarkMode: Bool {
        colorScheme == .dark
    }

    private var titleColor: Color {
        widgetRenderingMode == .fullColor ? (isDarkMode ? .white : .black) : .primary
    }

    private var secondaryColor: Color {
        widgetRenderingMode == .fullColor ? (isDarkMode ? .white.opacity(0.7) : .gray) : .secondary
    }

    private var timelineColor: Color {
        widgetRenderingMode == .fullColor ? statusColor : .primary
    }

    private var backgroundColor: Color {
        isDarkMode ? Color(red: 0.08, green: 0.08, blue: 0.10) : .white
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Olilo Status")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(titleColor)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        Circle()
                            .fill(timelineColor)
                            .frame(width: 10, height: 10)
                            .widgetAccentable()
                        Text(statusText)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(secondaryColor)
                    }
                }
                Spacer(minLength: 12)
                Text(entry.source.displayName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(secondaryColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: 110, alignment: .trailing)
            }

            Spacer(minLength: 16)

            Capsule()
                .fill(timelineColor)
                .frame(height: 10)
                .widgetAccentable()

            HStack {
                Text("-24 h")
                Spacer()
                Text("Now")
            }
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(secondaryColor)
            .padding(.top, 8)

            Spacer(minLength: 10)

            Image("OliloWidget")
                .resizable()
                .scaledToFit()
                .frame(height: 24)
                .colorInvertIfNeeded(isDarkMode)
                .opacity(widgetRenderingMode == .fullColor ? 1 : 0.9)
        }
        .padding(20)
        .containerBackground(for: .widget) {
            backgroundColor
        }
    }
}

struct OliloLockScreenStatusWidgetView: View {
    let entry: OliloStatusEntry

    @Environment(\.widgetFamily) private var widgetFamily

    private var statusText: String {
        entry.isOnline ? "Online" : "Offline"
    }

    private var statusColor: Color {
        entry.isOnline ? .green : .red
    }

    private var backdropColor: Color {
        entry.isOnline ? .green.opacity(0.18) : .red.opacity(0.18)
    }

    var body: some View {
        Group {
            switch widgetFamily {
            case .accessoryCircular:
                circularLayout
            case .accessoryRectangular:
                rectangularLayout
            case .accessoryInline:
                inlineLayout
            default:
                rectangularLayout
            }
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }

    private var circularLayout: some View {
        ZStack {
            Circle()
                .strokeBorder(.secondary.opacity(0.35), lineWidth: 2)
            VStack(spacing: 2) {
                Image(systemName: "network")
                    .font(.system(size: 14, weight: .semibold))
                    .widgetAccentable()
                Text(entry.source.shortName)
                    .font(.system(size: 11, weight: .bold))
                    .lineLimit(1)
                HStack(spacing: 3) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 5, height: 5)
                        .widgetAccentable()
                    Text(statusText)
                        .font(.system(size: 8, weight: .medium))
                        .lineLimit(1)
                }
            }
            .padding(5)
        }
        .accessibilityLabel("\(entry.source.displayName) \(statusText)")
    }

    private var rectangularLayout: some View {
        HStack(spacing: 7) {
            ZStack {
                Circle()
                    .strokeBorder(.secondary.opacity(0.35), lineWidth: 1.5)
                Image(systemName: "network")
                    .font(.system(size: 12, weight: .semibold))
                    .widgetAccentable()
            }
            .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.source.displayName)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text(statusText)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            Circle()
                .fill(statusColor)
                .frame(width: 7, height: 7)
                .widgetAccentable()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(backdropColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(statusColor.opacity(0.35), lineWidth: 1)
        )
        .accessibilityLabel("\(entry.source.displayName) \(statusText)")
    }

    private var inlineLayout: some View {
        HStack(spacing: 4) {
            Image(systemName: "network")
            Text("\(entry.source.displayName): \(statusText)")
        }
        .font(.caption.weight(.semibold))
    }
}

struct OliloNoticesWidgetView: View {
    let entry: OliloNoticesEntry

    @Environment(\.widgetRenderingMode) private var widgetRenderingMode
    @Environment(\.colorScheme) private var colorScheme

    private var isDarkMode: Bool {
        colorScheme == .dark
    }

    private var titleColor: Color {
        widgetRenderingMode == .fullColor ? (isDarkMode ? .white : .black) : .primary
    }

    private var secondaryColor: Color {
        widgetRenderingMode == .fullColor ? (isDarkMode ? .white.opacity(0.72) : .gray) : .secondary
    }

    private var accentColor: Color {
        switch entry.source {
        case .incidents: return entry.notices.isEmpty ? .green : .orange
        case .maintenance: return entry.notices.isEmpty ? .green : .blue
        }
    }

    private var backgroundColor: Color {
        isDarkMode ? Color(red: 0.08, green: 0.08, blue: 0.10) : .white
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Olilo Status")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(titleColor)
                        .lineLimit(1)
                    Label(entry.source.displayName, systemImage: entry.source.systemImage)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(secondaryColor)
                        .lineLimit(1)
                }
                Spacer(minLength: 12)
                NoticeCountBadge(count: entry.notices.count, accentColor: accentColor)
            }

            if entry.didLoadSuccessfully {
                if entry.notices.isEmpty {
                    EmptyNoticeSummary(source: entry.source, accentColor: accentColor, secondaryColor: secondaryColor)
                } else if entry.source == .maintenance, let maintenance = entry.notices.first {
                    MaintenanceDetailWidgetCard(notice: maintenance, accentColor: accentColor, secondaryColor: secondaryColor)
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(entry.notices.prefix(4)) { notice in
                            NoticeWidgetRow(source: entry.source, notice: notice, accentColor: accentColor, secondaryColor: secondaryColor)
                        }
                    }
                }
            } else {
                EmptyNoticeSummary(message: "Unable to load status", systemImage: "wifi.exclamationmark", accentColor: .secondary, secondaryColor: secondaryColor)
            }

            Spacer(minLength: 0)

            HStack(spacing: 10) {
                Capsule()
                    .fill(accentColor)
                    .frame(height: 10)
                    .widgetAccentable()
                Text(entry.date, style: .time)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(secondaryColor)
                    .lineLimit(1)
            }

            Image("OliloWidget")
                .resizable()
                .scaledToFit()
                .frame(height: 24)
                .colorInvertIfNeeded(isDarkMode)
                .opacity(widgetRenderingMode == .fullColor ? 1 : 0.9)
        }
        .padding(20)
        .containerBackground(for: .widget) {
            backgroundColor
        }
    }
}

private struct NoticeCountBadge: View {
    let count: Int
    let accentColor: Color

    var body: some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(accentColor)
                .widgetAccentable()
            Text(count == 1 ? "active" : "active")
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(width: 58)
        .accessibilityLabel("\(count) active notices")
    }
}

private struct NoticeWidgetRow: View {
    let source: WidgetNoticeSource
    let notice: OliloWidgetNotice
    let accentColor: Color
    let secondaryColor: Color

    private var maintenanceDetails: [String] {
        var details = [readableWidgetStatus(notice.status)]
        if let startDate = notice.startDate {
            details.append("Starts \(startDate.formatted(date: .abbreviated, time: .shortened))")
        }
        if let duration = notice.duration {
            details.append("\(duration) min")
        }
        if let updatedAt = notice.updatedAt {
            details.append("Updated \(updatedAt.formatted(date: .omitted, time: .shortened))")
        }
        return details
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(accentColor)
                .frame(width: 9, height: 9)
                .padding(.top, 5)
                .widgetAccentable()
            VStack(alignment: .leading, spacing: 3) {
                Text(notice.title)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(source == .maintenance ? 2 : 1)
                    .minimumScaleFactor(0.8)
                if source == .maintenance {
                    Text(maintenanceDetails.joined(separator: " - "))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(secondaryColor)
                        .lineLimit(2)
                        .minimumScaleFactor(0.75)
                } else {
                    HStack(spacing: 6) {
                        Text(readableWidgetStatus(notice.detailStatus))
                        if let date = notice.relevantDate {
                            Text("-")
                            Text(date, style: .relative)
                        }
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(secondaryColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                }
            }
        }
    }
}

private struct MaintenanceDetailWidgetCard: View {
    let notice: OliloWidgetNotice
    let accentColor: Color
    let secondaryColor: Color

    private var detailRows: [(label: String, value: String)] {
        var rows = [(label: "Status", value: readableWidgetStatus(notice.status))]
        if let startDate = notice.startDate {
            rows.append(("Starts", startDate.formatted(date: .abbreviated, time: .shortened)))
        }
        if let duration = notice.duration {
            rows.append(("Duration", "\(duration) minutes"))
        }
        if let updatedAt = notice.updatedAt {
            rows.append(("Updated", updatedAt.formatted(date: .abbreviated, time: .shortened)))
        }
        return rows
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Circle()
                    .fill(accentColor)
                    .frame(width: 10, height: 10)
                    .padding(.top, 6)
                    .widgetAccentable()
                Text(notice.title)
                    .font(.system(size: 18, weight: .bold))
                    .lineLimit(3)
                    .minimumScaleFactor(0.75)
            }

            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 5) {
                ForEach(detailRows, id: \.label) { row in
                    GridRow {
                        Text(row.label)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(secondaryColor)
                        Text(row.value)
                            .font(.system(size: 12, weight: .medium))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct EmptyNoticeSummary: View {
    let message: String
    let systemImage: String
    let accentColor: Color
    let secondaryColor: Color

    init(source: WidgetNoticeSource, accentColor: Color, secondaryColor: Color) {
        self.message = source.emptyMessage
        self.systemImage = "checkmark.circle"
        self.accentColor = accentColor
        self.secondaryColor = secondaryColor
    }

    init(message: String, systemImage: String, accentColor: Color, secondaryColor: Color) {
        self.message = message
        self.systemImage = systemImage
        self.accentColor = accentColor
        self.secondaryColor = secondaryColor
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(accentColor)
                .widgetAccentable()
            Text(message)
                .font(.system(size: 20, weight: .bold))
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            Text("Checked just now")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(secondaryColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private extension View {
    /// Applies color inversion only when the widget needs a dark-mode logo treatment.
    @ViewBuilder
    func colorInvertIfNeeded(_ shouldInvert: Bool) -> some View {
        if shouldInvert {
            colorInvert()
        } else {
            self
        }
    }
}

/// Converts backend status identifiers into readable text without depending on the app target.
private func readableWidgetStatus(_ status: String) -> String {
    let replacements = [
        "UP": "Up",
        "OPERATIONAL": "Operational",
        "HASISSUES": "Has issues",
        "HAS_ISSUES": "Has issues",
        "UNDERMAINTENANCE": "Under maintenance",
        "DEGRADEDPERFORMANCE": "Degraded performance",
        "DEGRADED_PERFORMANCE": "Degraded performance",
        "PARTIALOUTAGE": "Partial outage",
        "PARTIAL_OUTAGE": "Partial outage",
        "MAJOROUTAGE": "Major outage",
        "MAJOR_OUTAGE": "Major outage",
        "INVESTIGATING": "Investigating",
        "IDENTIFIED": "Identified",
        "MONITORING": "Monitoring",
        "RESOLVED": "Resolved",
        "NOTSTARTEDYET": "Not started yet",
        "COMPLETED": "Completed"
    ]
    if let replacement = replacements[status.uppercased()] {
        return replacement
    }

    return status
        .replacingOccurrences(of: "_", with: " ")
        .split(separator: " ")
        .map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
        .joined(separator: " ")
}

struct OliloStatusWidget: Widget {
    let kind = "uk.co.olilo.status.widgets.network-status"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: OliloStatusWidgetConfiguration.self, provider: OliloStatusProvider()) { entry in
            OliloStatusWidgetView(entry: entry)
        }
        .configurationDisplayName("Olilo Status")
        .description("Shows whether the selected Olilo network source is online.")
        .supportedFamilies([.systemMedium])
    }
}

struct OliloNoticesWidget: Widget {
    let kind = "uk.co.olilo.status.widgets.notices"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: OliloNoticesWidgetConfiguration.self, provider: OliloNoticesProvider()) { entry in
            OliloNoticesWidgetView(entry: entry)
        }
        .configurationDisplayName("Olilo Notices")
        .description("Shows active incidents or maintenance from Olilo Status.")
        .supportedFamilies([.systemLarge])
    }
}

struct OliloLockScreenStatusWidget: Widget {
    let kind = "uk.co.olilo.status.widgets.lock-screen-status"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: OliloLockScreenStatusWidgetConfiguration.self, provider: OliloLockScreenStatusProvider()) { entry in
            OliloLockScreenStatusWidgetView(entry: entry)
        }
        .configurationDisplayName("Olilo Network Status")
        .description("Shows Openreach, CityFibre, or Freedom Fibre status on the Lock Screen.")
        .supportedFamilies([.accessoryRectangular])
    }
}
