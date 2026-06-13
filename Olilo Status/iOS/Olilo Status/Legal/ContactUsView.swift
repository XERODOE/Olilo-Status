import SwiftUI

struct ContactUsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .bottom) {
            Form {
                Section {
                    Link(destination: URL(string: "https://discord.gg/olilo")!) {
                        ContactAssetRowLabel(title: "Submit a support ticket on Discord", imageName: "Discord")
                    }

                    Link(destination: URL(string: "https://www.reddit.com/r/Olilo")!) {
                        ContactAssetRowLabel(title: "Post to the community on Reddit", imageName: "Reddit")
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

            LegalPageBottomLogo()
                .padding(.bottom, 24)
        }
        .navigationTitle("Contact Us")
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
