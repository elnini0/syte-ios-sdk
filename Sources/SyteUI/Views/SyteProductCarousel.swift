import SwiftUI
import iOS_SDK

/// A titled, horizontally scrolling row of products. Shows placeholder cards while loading and
/// hides itself when there's nothing to show, so a product page never has an empty or broken row.
///
///     SyteProductCarousel(.similar(sku: product.sku, imageURL: product.image), title: "You may also like") { product in
///         router.open(product)
///     }
public struct SyteProductCarousel<Card: View>: View {

    let request: SyteRecommendation
    let title: String?
    let limit: Int
    let pageName: String
    let onSelect: (SyteUIProduct) -> Void
    let card: (SyteUIProduct) -> Card

    @Environment(\.syteService) private var service
    @Environment(\.syteTheme) private var theme
    @StateObject private var model = SyteCarouselModel()

    /// - Parameters:
    ///   - pageName: Sent with events as the page the row was on.
    ///   - card: Your own card view, used instead of `SyteProductCard`.
    public init(_ request: SyteRecommendation,
                title: String? = nil,
                limit: Int = 12,
                pageName: String = "mobile_sdk",
                onSelect: @escaping (SyteUIProduct) -> Void = { _ in },
                @ViewBuilder card: @escaping (SyteUIProduct) -> Card) {
        self.request = request
        self.title = title
        self.limit = limit
        self.pageName = pageName
        self.onSelect = onSelect
        self.card = card
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing) {
            switch model.state {
            case .loading:
                header
                row(SyteCarouselModel.placeholders)
                    .redacted(reason: .placeholder)
                    .disabled(true)
            case .loaded(let products) where !products.isEmpty:
                header
                row(products)
            default:
                EmptyView()
            }
        }
        .task(id: request) {
            await model.load(request, limit: limit, pageName: pageName, service: service)
        }
    }

    @ViewBuilder private var header: some View {
        if let title = title {
            Text(title)
                .font(theme.headerFont)
                .foregroundColor(theme.primaryText)
                .padding(.horizontal, theme.edgeInset)
                .accessibilityAddTraits(.isHeader)
        }
    }

    private func row(_ products: [SyteUIProduct]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .top, spacing: theme.spacing) {
                ForEach(Array(products.enumerated()), id: \.offset) { index, product in
                    Button {
                        model.select(product, at: index, request: request, pageName: pageName, service: service)
                        onSelect(product)
                    } label: {
                        card(product)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("syte.carousel.product")
                    .frame(width: theme.carouselCardWidth)
                }
            }
            .padding(.horizontal, theme.edgeInset)
        }
    }

}

extension SyteProductCarousel where Card == SyteProductCard {

    public init(_ request: SyteRecommendation,
                title: String? = nil,
                limit: Int = 12,
                pageName: String = "mobile_sdk",
                onSelect: @escaping (SyteUIProduct) -> Void = { _ in }) {
        self.init(request, title: title, limit: limit, pageName: pageName, onSelect: onSelect) { SyteProductCard(product: $0) }
    }

}

@MainActor
final class SyteCarouselModel: ObservableObject {

    enum State: Equatable {
        case loading
        case loaded([SyteUIProduct])
        case failed(String)
    }

    static let placeholders = (0..<4).map {
        SyteUIProduct(sku: "placeholder-\($0)", title: "Product name", brand: "Brand", price: "€00.00")
    }

    @Published private(set) var state = State.loading

    private var current: SyteRecommendation?

    func load(_ request: SyteRecommendation, limit: Int, pageName: String, service: SyteUIService?) async {
        guard current != request else { return }
        guard let service = service else {
            return state = .failed("No Syte service. Add .syteService(_:) above this view.")
        }
        current = request
        state = .loading
        do {
            let products = try await service.recommendations(request, limit: limit)
            guard current == request else { return }
            state = .loaded(products)
            if !products.isEmpty, let event = SyteUIEvents.carouselShown(request, count: products.count, pageName: pageName) {
                service.track(event)
            }
        } catch {
            guard current == request else { return }
            state = .failed(error.localizedDescription)
            // Try again the next time the row appears.
            current = nil
        }
    }

    func select(_ product: SyteUIProduct, at index: Int, request: SyteRecommendation, pageName: String, service: SyteUIService?) {
        guard let event = SyteUIEvents.carouselClicked(request, product: product, index: index, pageName: pageName) else { return }
        service?.track(event)
    }

}
