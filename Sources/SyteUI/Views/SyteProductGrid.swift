import SwiftUI

/// Products in as many columns as fit. Not scrollable on its own: put it in a `ScrollView`.
public struct SyteProductGrid<Card: View>: View {

    let products: [SyteUIProduct]
    let onSelect: (Int, SyteUIProduct) -> Void
    let onReachEnd: (() -> Void)?
    let card: (SyteUIProduct) -> Card

    @Environment(\.syteTheme) private var theme

    /// - Parameters:
    ///   - onSelect: Called with the product's position, starting at 0.
    ///   - onReachEnd: Called when the last product scrolls into view, to load the next page.
    public init(products: [SyteUIProduct],
                onSelect: @escaping (Int, SyteUIProduct) -> Void,
                onReachEnd: (() -> Void)? = nil,
                @ViewBuilder card: @escaping (SyteUIProduct) -> Card) {
        self.products = products
        self.onSelect = onSelect
        self.onReachEnd = onReachEnd
        self.card = card
    }

    public var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: theme.gridMinimumCardWidth), spacing: theme.spacing, alignment: .top)],
                  alignment: .leading,
                  spacing: theme.spacing * 2) {
            ForEach(Array(products.enumerated()), id: \.offset) { index, product in
                Button {
                    onSelect(index, product)
                } label: {
                    card(product)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("syte.product")
                .onAppear {
                    if index == products.count - 1 { onReachEnd?() }
                }
            }
        }
    }

}

extension SyteProductGrid where Card == SyteProductCard {

    public init(products: [SyteUIProduct],
                onSelect: @escaping (Int, SyteUIProduct) -> Void,
                onReachEnd: (() -> Void)? = nil) {
        self.init(products: products, onSelect: onSelect, onReachEnd: onReachEnd) { SyteProductCard(product: $0) }
    }

}

/// Shown where a list failed to load.
struct SyteErrorView: View {

    let message: String
    let retry: () -> Void

    @Environment(\.syteTheme) private var theme

    var body: some View {
        VStack(spacing: 12) {
            Text(message)
                .font(theme.titleFont)
                .foregroundColor(theme.secondaryText)
                .multilineTextAlignment(.center)
            Button(theme.strings.tryAgain, action: retry)
                .foregroundColor(theme.accent)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
    }

}
