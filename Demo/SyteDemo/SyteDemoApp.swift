import SwiftUI
import SyteUI
import iOS_SDK

/// A small shop built from the UI kit. Runs on made-up products unless an account is passed in
/// the scheme's environment: SYTE_ACCOUNT_ID, SYTE_API_KEY and optionally SYTE_LOCALE (default en_US).
@main
struct SyteDemoApp: App {

    private let service: SyteUIService
    private let isLive: Bool

    init() {
        let env = ProcessInfo.processInfo.environment
        if let account = env["SYTE_ACCOUNT_ID"], let key = env["SYTE_API_KEY"], !account.isEmpty, !key.isEmpty {
            let configuration = SyteConfiguration(accountId: account, signature: key)
            configuration.locale = env["SYTE_LOCALE"] ?? "en_US"
            if let syte = Syte(configuration: configuration) {
                service = SyteLiveService(syte: syte)
                isLive = true
                return
            }
        }
        service = SytePreviewService()
        isLive = false
    }

    var body: some Scene {
        WindowGroup {
            DemoTabs(isLive: isLive)
                .syteService(service)
                .syteTheme(.demo)
                .tint(SyteTheme.demo.accent)
        }
    }

}

extension SyteTheme {

    /// Shows a retailer's own colors and corners in place of the defaults.
    static var demo: SyteTheme {
        var theme = SyteTheme()
        theme.accent = Color(red: 0.11, green: 0.36, blue: 0.33)
        theme.salePrice = Color(red: 0.75, green: 0.22, blue: 0.17)
        theme.cornerRadius = 6
        return theme
    }

}

/// Where a tab's navigation can go.
enum Route: Hashable {
    case product(SyteUIProduct)
    case similarLooks(SyteUIProduct)
}

struct DemoTabs: View {

    let isLive: Bool

    var body: some View {
        TabView {
            DemoStack(title: "Search") { open in
                SyteSearchView(pageName: "search") { open(.product($0)) }
            }
            .tabItem { Label("Search", systemImage: "magnifyingglass") }

            DemoStack(title: "Photo search") { open in
                SyteVisualSearchView(pageName: "camera") { open(.product($0)) }
            }
            .tabItem { Label("Photo", systemImage: "camera.viewfinder") }

            DemoStack(title: "For you") { open in
                ForYouPage(isLive: isLive, open: open)
            }
            .tabItem { Label("For you", systemImage: "sparkles") }
        }
    }

}

/// A navigation stack that knows how to show products and similar looks.
struct DemoStack<Root: View>: View {

    let title: String
    let root: (@escaping (Route) -> Void) -> Root

    @State private var path: [Route] = []

    var body: some View {
        NavigationStack(path: $path) {
            root(open)
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .product(let product):
                        ProductPage(product: product, open: open)
                    case .similarLooks(let product):
                        SyteVisualSearchView(imageURL: product.imageURL, sku: product.sku, pageName: "pdp") { open(.product($0)) }
                            .navigationTitle("Similar looks")
                            .navigationBarTitleDisplayMode(.inline)
                    }
                }
        }
    }

    private func open(_ route: Route) {
        path.append(route)
    }

}

struct ForYouPage: View {

    let isLive: Bool
    let open: (Route) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Text(isLive ? "Live account" : "Sample products. Pass an account in the scheme's environment to use your catalog.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                SyteProductCarousel(.personalized(), title: "Picked for you", pageName: "home") { open(.product($0)) }
                SyteProductCarousel(.recentlyViewed, title: "Recently viewed", pageName: "home") { open(.product($0)) }
            }
            .padding(.vertical, 16)
        }
    }

}
