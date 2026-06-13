import SwiftUI
import UserNotifications

struct SettingsView: View {
    @State private var presentedWebPage: SettingsWebPage?
    @State private var pushPreferences = PushNotificationPreferences.load()
    @State private var notificationAuthorizationStatus = UNAuthorizationStatus.notDetermined
    @State private var notificationComponents: [StatusComponent] = []
    @State private var isLoadingNotificationComponents = false
    @State private var notificationErrorMessage: String?

    private let selectableNotificationComponentNames = ["Openreach", "CityFibre", "Freedom Fibre"]

    private var appVersion: String {
        (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "Unknown"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle(isOn: pushEnabledBinding) {
                        SettingsRowLabel(title: "Network Status", systemImage: "bell.badge")
                    }
                    .tint(Color.oliloPurple)

                    if pushPreferences.isEnabled {
                        if notificationAuthorizationStatus == .denied {
                            Text("Notifications are disabled in iOS Settings for this app.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        } else if isLoadingNotificationComponents {
                            ProgressView("Loading components...")
                        } else if notificationComponents.isEmpty {
                            Text("Components will appear here once status data has loaded.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(notificationComponents) { component in
                                Toggle(isOn: notificationBinding(for: component)) {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(component.name)
                                            .foregroundStyle(.white)
                                        Text(componentDetail(for: component))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .tint(Color.oliloPurple)
                            }

                            Button("Notify for all Components") {
                                pushPreferences.selectAllComponents(notificationComponents)
                                saveAndSyncPushPreferences()
                            }
                            .disabled(pushPreferences.selectedComponentIDs.count == notificationComponents.count)
                            .tint(Color.oliloPurple)
                        }
                    }

                    if let notificationErrorMessage {
                        Text(notificationErrorMessage)
                            .font(.footnote)
                            .foregroundStyle(.orange)
                    }
                } header: {
                    Text("Notifications")
                } footer: {
                    Text("Choose which network components can send you notifications when their state changes.")
                }

                Section("Need Help?") {
                    NavigationLink {
                        ContactUsView()
                    } label: {
                        SettingsRowLabel(title: "Contact Us", systemImage: "envelope")
                    }
                }

                Section("Legal Information") {
                    NavigationLink {
                        AboutView()
                    } label: {
                        SettingsRowLabel(title: "About", systemImage: "info.circle")
                    }

                    Button {
                        presentedWebPage = .privacyPolicy
                    } label: {
                        SettingsRowLabel(title: "Privacy Policy", systemImage: "hand.raised")
                    }
                    .buttonStyle(.plain)

                    Button {
                        presentedWebPage = .termsAndConditions
                    } label: {
                        SettingsRowLabel(title: "Terms & Conditions", systemImage: "doc.plaintext")
                    }
                    .buttonStyle(.plain)
                }

                Section("Olilo Status") {
                    Link(destination: URL(string: "https://gitlab.com/team-olilo/status-app")!) {
                        SettingsAssetRowLabel(title: "Contribute to Olilo Status on GitLab", imageName: "GitLab")
                    }
                    .listRowSeparator(.hidden)

                    Text(appVersion)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.35), lineWidth: 1)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowSeparator(.hidden)

                    VStack(spacing: 10) {
                        SettingsLogo()

                        Text("© 2026 Olilo UK & Ireland Ltd. Company number: 16352417")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .listRowSeparator(.hidden)
                }
            }
            .scrollContentBackground(.hidden)
            .background(OliloDarkGradientBackground())
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    OliloToolbarLogo()
                }
            }
        }
        .tint(Color.oliloPurple)
        .task {
            await refreshNotificationState()
            await loadNotificationComponents()
        }
        .sheet(item: $presentedWebPage) { webPage in
            OliloWebViewSheet(title: webPage.title, url: webPage.url)
        }
    }

    private var pushEnabledBinding: Binding<Bool> {
        Binding {
            pushPreferences.isEnabled
        } set: { isEnabled in
            Task { await setPushNotificationsEnabled(isEnabled) }
        }
    }

    private func notificationBinding(for component: StatusComponent) -> Binding<Bool> {
        Binding {
            pushPreferences.isComponentSelected(component)
        } set: { isSelected in
            pushPreferences.setComponent(component, isSelected: isSelected)
            saveAndSyncPushPreferences()
        }
    }

    private func refreshNotificationState() async {
        notificationAuthorizationStatus = await PushNotificationManager.shared.authorizationStatus()
    }

    private func loadNotificationComponents() async {
        guard notificationComponents.isEmpty else { return }
        isLoadingNotificationComponents = true
        defer { isLoadingNotificationComponents = false }

        do {
            notificationComponents = try await StatusAPI().fetchComponents().filter(isSelectableNotificationComponent)

            if pushPreferences.isEnabled && pushPreferences.selectedComponentIDs.isEmpty {
                pushPreferences.selectAllComponents(notificationComponents)
                saveAndSyncPushPreferences()
            }
        } catch {
            notificationErrorMessage = "Could not load notification components: \(error.localizedDescription)"
        }
    }

    private func setPushNotificationsEnabled(_ isEnabled: Bool) async {
        notificationErrorMessage = nil
        var updatedPreferences = pushPreferences
        updatedPreferences.isEnabled = isEnabled

        if isEnabled && updatedPreferences.selectedComponentIDs.isEmpty {
            updatedPreferences.selectAllComponents(notificationComponents)
        }

        pushPreferences = updatedPreferences
        pushPreferences.save()

        if isEnabled {
            do {
                try await PushNotificationManager.shared.enableNotifications(with: pushPreferences)
                await refreshNotificationState()
            } catch {
                pushPreferences.isEnabled = false
                pushPreferences.save()
                notificationErrorMessage = error.localizedDescription
            }
        } else {
            await PushNotificationManager.shared.disableNotifications(with: pushPreferences)
        }
    }

    private func saveAndSyncPushPreferences() {
        pushPreferences.save()
        Task {
            try? await PushNotificationManager.shared.syncSubscription(preferences: pushPreferences)
        }
    }

    private func componentDetail(for component: StatusComponent) -> String {
        var details = [readableStatus(component.status)]
        if let groupName = component.group?.name, !groupName.isEmpty {
            details.append(groupName)
        }
        return details.joined(separator: " - ")
    }

    private func isSelectableNotificationComponent(_ component: StatusComponent) -> Bool {
        selectableNotificationComponentNames.contains { name in
            component.name.localizedCaseInsensitiveCompare(name) == .orderedSame
        }
    }
}

private enum SettingsWebPage: Identifiable {
    case privacyPolicy
    case termsAndConditions

    var id: String { title }

    var title: String {
        switch self {
        case .privacyPolicy: return "Privacy Policy"
        case .termsAndConditions: return "Terms & Conditions"
        }
    }

    var url: URL {
        switch self {
        case .privacyPolicy: return URL(string: "https://olilo.co.uk/privacy")!
        case .termsAndConditions: return URL(string: "https://olilo.co.uk/terms")!
        }
    }
}

private struct SettingsRowLabel: View {
    let title: String
    let systemImage: String
    var body: some View {
        Label {
            Text(title)
                .foregroundStyle(.white)
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(Color.oliloPurple)
        }
    }
}

private struct SettingsAssetRowLabel: View {
    let title: String
    let imageName: String

    var body: some View {
        Label {
            Text(title)
                .foregroundStyle(.white)
        } icon: {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
        }
    }
}

private struct SettingsLogo: View {
    var body: some View {
        Image("Olilo")
            .resizable()
            .scaledToFit()
            .frame(height: 44)
            .accessibilityLabel("Olilo")
    }
}
