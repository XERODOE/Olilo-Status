import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            Form {
                Section("Information & Legal") {
                    NavigationLink {
                        LegalNoticesView()
                    } label: {
                        Label("Legal Notices", systemImage: "doc.text")
                    }

                    NavigationLink {
                        AboutView()
                    } label: {
                        Label("About", systemImage: "info.circle")
                    }

                    Link(destination: URL(string: "https://olilo.co.uk/privacy")!) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }
                    .tint(.white)

                    Link(destination: URL(string: "https://olilo.co.uk/terms")!) {
                        Label("Terms & Conditions", systemImage: "doc.plaintext")
                    }
                    .tint(.white)
                }

                Section {
                    VStack(spacing: 10) {
                        SettingsLogo()

                        Text("© 2026 Olilo UK & Ireland Ltd. Company number: 16352417")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
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
    }
}

private struct SettingsLogo: View {
    var body: some View {
        Image("OliloLogoLight")
            .resizable()
            .scaledToFit()
            .frame(height: 44)
            .accessibilityLabel("Olilo")
    }
}
