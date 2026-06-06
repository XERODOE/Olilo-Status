//
//  LegalNoticesView.swift
//  Olilo Status
//
//  Created by Aaron Doe on 06/06/2026.
//

import SwiftUI

struct LegalNoticesView: View {
    var body: some View {
        ZStack {
            OliloDarkGradientBackground()
                .ignoresSafeArea()

            ScrollView {
                Text("""
                © 2026 Olilo UK & Ireland Ltd.

                All rights reserved.

                This application is owned by Aaron Doe and contents are owned by Olilo UK & Ireland Ltd.
                
                Unauthorized copying, modification, distribution, or reverse engineering
                of any part of this application is prohibited except where permitted by law.

                Company Number: 16352417 (Olilo)

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
                .padding()
            }
        }
        .navigationTitle("Legal Notices")
        .navigationBarTitleDisplayMode(.inline)
    }
}
