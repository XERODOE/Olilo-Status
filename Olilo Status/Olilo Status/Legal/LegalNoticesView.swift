//
//  LegalNoticesView.swift
//  Olilo Status
//
//  Created by Aaron Doe on 06/06/2026.
//

import SwiftUI

struct LegalNoticesView: View {
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
                    This application is developed by Aaron Doe and it's contents are owned by Olilo UK & Ireland Ltd.
                    
                    Aaron Doe (developer) is in no way affiliated with Olilo (company) other than the development of this application.
                    
                    Unauthorized copying, modification, distribution, or reverse engineering
                    of any part of this application is prohibited except where permitted by law.
                    
                    © 2026 Olilo UK & Ireland Ltd. All rights reserved.
                    
                    Company Number: 16352417 (Olilo UK & Ireland Ltd.)

                    For legal enquiries, please contact Olilo directly.
                    """)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 24,
                            style: .continuous
                        )
                    )
                    .overlay {
                        RoundedRectangle(
                            cornerRadius: 24,
                            style: .continuous
                        )
                        .stroke(.white.opacity(0.15), lineWidth: 1)
                    }
                    .shadow(
                        color: .black.opacity(0.2),
                        radius: 20,
                        y: 10
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .padding(.bottom, 80)
            }

            LegalPageBottomLogo()
                .padding(.bottom, 24)
        }
        .navigationTitle("Legal Notices")
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
