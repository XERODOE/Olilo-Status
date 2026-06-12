import SwiftUI

struct SettingsView: View {
    @State private var presentedWebPage: SettingsWebPage?

    private var appVersion: String {
        (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "Unknown"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Need Help?") {
                    Link(destination: URL(string: "https://discord.gg/olilo")!) {
                        SettingsAssetRowLabel(title: "Find us on Discord", imageName: "Discord")
                    }

                    Link(destination: URL(string: "https://www.reddit.com/r/Olilo")!) {
                        SettingsAssetRowLabel(title: "Find us on Reddit", imageName: "Reddit")
                    }
                }

                Section("Legal Information") {
                    NavigationLink {
                        AboutView()
                    } label: {
                        SettingsRowLabel(title: "About", systemImage: "info.circle", titleColor: Color.oliloPurple)
                    }

                    NavigationLink {
                        LegalDisclaimerView()
                    } label: {
                        SettingsRowLabel(title: "Legal Disclaimer", systemImage: "doc.text", titleColor: Color.oliloPurple)
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

                Section("About Olilo Status") {
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
        .sheet(item: $presentedWebPage) { webPage in
            OliloWebViewSheet(title: webPage.title, url: webPage.url)
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
    var titleColor: Color = Color.oliloPurple

    var body: some View {
        Label {
            Text(title)
                .foregroundStyle(titleColor)
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
                .foregroundStyle(Color.oliloPurple)
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
