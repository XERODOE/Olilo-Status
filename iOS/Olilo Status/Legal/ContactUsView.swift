import SwiftUI

struct ContactUsView: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            Form {
                Section {
                    Link(destination: URL(string: "https://discord.gg/olilo")!) {
                        ContactAssetRowLabel(title: "Olilo Discord", imageName: "Discord")
                    }

                    Link(destination: URL(string: "https://www.reddit.com/r/Olilo")!) {
                        ContactAssetRowLabel(title: "r/Olilo Reddit", imageName: "Reddit")
                    }
                } header: {
                    Text("Need to contact the team?")
                } footer: {
                    Text("Support links open to external services. Official Olilo staff can be identified either by the \"Olilo Management\" & \"Olilo Staff\" flairs on Reddit or \"Management\" & \"Staff\" roles on Discord.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(OliloDarkGradientBackground())
            .safeAreaPadding(.bottom, 72)

            OliloFooterLogo()
                .padding(.bottom, 24)
        }
        .navigationTitle("Contact Us")
        .toolbar {
            ToolbarItem(placement: .principal) {
                OliloToolbarLogo()
            }
        }
    }
}

private struct ContactAssetRowLabel: View {
    let title: String
    let imageName: String

    var body: some View {
        Label {
            Text(title)
                .foregroundStyle(.white)
        } icon: {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
        }
    }
}
