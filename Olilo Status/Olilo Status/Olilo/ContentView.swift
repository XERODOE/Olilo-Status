//
//  ContentView.swift
//  Olilo Status
//
//  Created by Aaron Doe on 30/05/2026.
//

import SwiftUI

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
        Image("OliloLogoLight")
            .resizable()
            .scaledToFit()
            .frame(height: 20)
            .accessibilityLabel("Olilo")
    }
}

#Preview {
    ContentView()
}
