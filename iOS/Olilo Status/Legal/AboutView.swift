import SwiftUI

struct AboutView: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            OliloDarkGradientBackground()
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("About this application:")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Text("""
                    This application is developed by Aaron Doe and contents herein are owned by Olilo UK & Ireland Ltd.
                    
                    Aaron Doe (The Developer) is in no way affiliated with Olilo (The Company) other than the development and maintenance of this application.
                    
                    Unauthorised copying, modification, distribution, or reverse engineering
                    of any part of this application is prohibited except where permitted by law and the project's open source licence.
                    
                    © 2026 Olilo UK & Ireland Ltd. All rights reserved.
                    
                    Company Number: 16352417 (Olilo UK & Ireland Ltd.)

                    For legal enquiries, please contact us.
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

                    Text("Olilo Status Contributors")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Text("Aydan Abrahams")
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
        .toolbar {
            ToolbarItem(placement: .principal) {
                OliloToolbarLogo()
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
