//
//  NotificationSettingsView.swift
//  Olilo Status
//
//  Optional drop-in settings screen for push notifications. Present it from the
//  existing Settings screen, e.g.:
//
//      NavigationLink("Notifications") { NotificationSettingsView() }
//
//  It drives `PushManager.shared`, so registration and preference sync with the
//  backend happen automatically.
//

import SwiftUI

struct NotificationSettingsView: View {
    @StateObject private var manager = PushManager.shared

    /// Consumer-facing networks the user can filter component alerts by.
    private let networks = ["Openreach", "CityFibre", "Freedom Fibre"]

    var body: some View {
        ZStack {
            OliloDarkGradientBackground()

            Form {
            Section {
                Toggle(isOn: enabledBinding) {
                    notificationToggleLabel("Enable notifications")
                }
            } header: {
                Text("Notifications")
            } footer: {
                Text("Get notified about Olilo Network updates on this device.")
            }

            if manager.isEnabled {
                Section {
                    Toggle(isOn: prefBinding(\.incidents)) {
                        notificationToggleLabel("Incidents")
                    }
                    Toggle(isOn: prefBinding(\.maintenance)) {
                        notificationToggleLabel("Scheduled maintenance")
                    }
                    Toggle(isOn: prefBinding(\.componentAlerts)) {
                        notificationToggleLabel("Component status changes")
                    }
                } header: {
                    Text("Notify me about")
                        .foregroundStyle(Color.secondary)
                } footer: {
                    Text("Choose which notices you get notified about.")
                }

                if manager.preferences.componentAlerts {
                    Section {
                        ForEach(networks, id: \.self) { network in
                            Toggle(isOn: networkBinding(network)) {
                                notificationToggleLabel(network)
                            }
                        }
                    } header: {
                        Text("Networks")
                            .foregroundStyle(Color.secondary)
                    } footer: {
                        Text("Choose which networks you get notifed about. With none selected you'll get alerts for all networks.")
                    }
                }
            }

            OliloFooterLogo()
                .frame(maxWidth: .infinity)
                .listRowInsets(EdgeInsets(top: 24, leading: 0, bottom: 24, trailing: 0))
                .listRowBackground(Color.clear)
            }
            .scrollContentBackground(.hidden)
            .iPadReadableContent()
        }
        .tint(Color.oliloPurple)
        .navigationTitle("Status Updates")
        .toolbar {
            ToolbarItem(placement: .principal) {
                OliloToolbarLogo()
            }
        }
    }

    /// Builds a consistently styled label for notification toggles.
    private func notificationToggleLabel(_ title: String) -> some View {
        Text(title)
            .foregroundStyle(.white)
    }

    // MARK: - Bindings

    private var enabledBinding: Binding<Bool> {
        Binding(
            get: { manager.isEnabled },
            set: { newValue in
                Task {
                    if newValue { await manager.enableNotifications() }
                    else { await manager.disableNotifications() }
                }
            }
        )
    }

    /// Creates a binding that writes a boolean preference back through the push manager.
    private func prefBinding(_ keyPath: WritableKeyPath<NotificationPreferences, Bool>) -> Binding<Bool> {
        Binding(
            get: { manager.preferences[keyPath: keyPath] },
            set: { newValue in
                var prefs = manager.preferences
                prefs[keyPath: keyPath] = newValue
                Task { await manager.updatePreferences(prefs) }
            }
        )
    }

    /// Creates a binding that adds or removes a network from component alert preferences.
    private func networkBinding(_ network: String) -> Binding<Bool> {
        Binding(
            get: { manager.preferences.networks.contains(network) },
            set: { isOn in
                var prefs = manager.preferences
                if isOn {
                    if !prefs.networks.contains(network) { prefs.networks.append(network) }
                } else {
                    prefs.networks.removeAll { $0 == network }
                }
                Task { await manager.updatePreferences(prefs) }
            }
        )
    }
}

#Preview {
    NavigationStack { NotificationSettingsView() }
}
