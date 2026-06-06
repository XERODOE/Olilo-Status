//
//  AboutView.swift
//  Olilo Status
//
//  Created by Aaron Doe on 06/06/2026.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        ZStack {
            OliloDarkGradientBackground()
                .ignoresSafeArea()

            ScrollView {
                Text("""
                Olilo Status is designed to show the status of Olilo network services.
                
                (Olilo, Openreach, CityFibre are registered trademarks. All rights belong to their respective owners.)
                
                Aaron Doe is in no way affiliated with Olilo in any sense other than developing this application. Olilo Status is provided for customers of Olilo and the wider community to check for network outages, provided by and published by the Olilo team.

                Developed by Aaron Doe.
                
                Published by Olilo.

                © 2026 Olilo UK & Ireland Ltd. All rights reserved.
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
                .padding()
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}
