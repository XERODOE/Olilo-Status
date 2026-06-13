import SwiftUI

extension Color {
    static let oliloPurple = Color(red: 0.70, green: 0.28, blue: 1.0)
}

struct ContentView: View {
    var body: some View {
        TabView {
            StatusView()
                .tabItem {
                    Label("Status", systemImage: "waveform.path.ecg")
                }

            NoticesView()
                .tabItem {
                    Label("Notices", systemImage: "bell.badge")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .tint(Color.oliloPurple)
        .preferredColorScheme(.dark)
        .background(OliloDarkGradientBackground())
    }
}

struct OliloDarkGradientBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                .black,
                Color(red: 0.13, green: 0.04, blue: 0.24),
                Color(red: 0.30, green: 0.08, blue: 0.48)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

struct OliloToolbarLogo: View {
    var body: some View {
        Image("Olilo")
            .resizable()
            .scaledToFit()
            .frame(height: 20)
            .accessibilityLabel("Olilo")
    }
}

#Preview {
    ContentView()
}
