import SwiftUI
import WidgetKit

struct OliloStatusEntry: TimelineEntry {
    let date: Date
    let isOnline: Bool
}

struct OliloStatusProvider: TimelineProvider {
    func placeholder(in context: Context) -> OliloStatusEntry {
        OliloStatusEntry(date: .now, isOnline: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (OliloStatusEntry) -> Void) {
        completion(OliloStatusEntry(date: .now, isOnline: true))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<OliloStatusEntry>) -> Void) {
        Task {
            let isOnline = await fetchNetworkStatus()
            let entry = OliloStatusEntry(date: .now, isOnline: isOnline)
            let refreshDate = Calendar.current.date(byAdding: .minute, value: 15, to: .now) ?? .now.addingTimeInterval(900)
            completion(Timeline(entries: [entry], policy: .after(refreshDate)))
        }
    }

    private func fetchNetworkStatus() async -> Bool {
        guard let url = URL(string: "https://status.olilo.co.uk/v3/summary.json") else {
            return false
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard
                let httpResponse = response as? HTTPURLResponse,
                (200..<300).contains(httpResponse.statusCode)
            else {
                return false
            }
            let summary = try JSONDecoder().decode(OliloWidgetSummary.self, from: data)
            return summary.page.status.uppercased() == "UP" || summary.page.status.uppercased() == "OPERATIONAL"
        } catch {
            return false
        }
    }
}

private struct OliloWidgetSummary: Decodable {
    struct Page: Decodable {
        let status: String
    }

    let page: Page
}

struct OliloStatusWidgetView: View {
    let entry: OliloStatusEntry

    @Environment(\.widgetRenderingMode) private var widgetRenderingMode

    private var statusText: String {
        entry.isOnline ? "Online" : "Offline"
    }

    private var statusColor: Color {
        entry.isOnline ? .green : .red
    }

    private var titleColor: Color {
        widgetRenderingMode == .fullColor ? .black : .primary
    }

    private var secondaryColor: Color {
        widgetRenderingMode == .fullColor ? .gray : .secondary
    }

    private var timelineColor: Color {
        widgetRenderingMode == .fullColor ? statusColor : .primary
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
                Spacer()
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
                .opacity(widgetRenderingMode == .fullColor ? 1 : 0.9)
        }
        .padding(20)
        .containerBackground(for: .widget) {
            Color.white
        }
    }
}

struct OliloStatusWidget: Widget {
    let kind = "OliloStatusWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: OliloStatusProvider()) { entry in
            OliloStatusWidgetView(entry: entry)
        }
        .configurationDisplayName("Olilo Status")
        .description("Shows whether the Olilo network is online.")
        .supportedFamilies([.systemMedium])
    }
}
