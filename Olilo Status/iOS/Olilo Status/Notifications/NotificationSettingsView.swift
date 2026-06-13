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
        Form {
            Section {
                Toggle("Enable notifications", isOn: enabledBinding)
            } footer: {
                Text("Get push alerts about the Olilo network on this device.")
            }

            if manager.isEnabled {
                Section("Alert me about") {
                    Toggle("Incidents", isOn: prefBinding(\.incidents))
                    Toggle("Scheduled maintenance", isOn: prefBinding(\.maintenance))
                    Toggle("Component status changes", isOn: prefBinding(\.componentAlerts))
                }

                if manager.preferences.componentAlerts {
                    Section {
                        ForEach(networks, id: \.self) { network in
                            Toggle(network, isOn: networkBinding(network))
                        }
                    } header: {
                        Text("Networks")
                    } footer: {
                        Text("Choose which networks trigger component alerts. With none selected you'll get alerts for all networks.")
                    }
                }
            }
        }
        .navigationTitle("Notifications")
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
