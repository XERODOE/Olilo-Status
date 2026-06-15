import SwiftUI
import WebKit

struct OliloWebViewSheet: View {
    let title: String
    let url: URL
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            OliloWebView(url: url)
                .ignoresSafeArea(edges: .bottom)
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                        .foregroundStyle(Color.oliloPurple)
                    }
                }
        }
    }
}

private struct OliloWebView: UIViewRepresentable {
    let url: URL

    /// Creates the backing web view and loads the requested URL.
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.load(URLRequest(url: url))
        return webView
    }

    /// Leaves the loaded page unchanged after SwiftUI state updates.
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
