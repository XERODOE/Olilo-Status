import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .bottom) {
            OliloDarkGradientBackground()
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Olilo Status")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Text("""
                    Olilo Status is built for fast and simple access for checking the current status of the Olilo Network,
                    Services, Planned Maintenance & Updates.

                    Olilo Status is built by Aaron Doe and published by Olilo UK & Ireland Ltd.
                    
                    This application is open source and full source code is available in the public repository.
                    """)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(.white.opacity(0.15), lineWidth: 1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .padding(.bottom, 80)
            }

            LegalPageBottomLogo()
                .padding(.bottom, 24)
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundStyle(Color.oliloPurple)
                }
                .tint(Color.oliloPurple)
            }
        }
    }
}

struct LegalPageBottomLogo: View {
    var body: some View {
        Image("Olilo")
            .resizable()
            .scaledToFit()
            .frame(height: 36)
            .accessibilityLabel("Olilo")
    }
}
