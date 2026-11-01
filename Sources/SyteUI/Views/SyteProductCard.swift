import SwiftUI

/// The default product card: image, brand, title and price. Pass your own card to any carousel or
/// grid to replace it.
public struct SyteProductCard: View {

    public let product: SyteUIProduct

    @Environment(\.syteTheme) private var theme

    public init(product: SyteUIProduct) {
        self.product = product
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            SyteProductImage(url: product.imageURL)
                .padding(.bottom, 4)
            if let brand = product.brand, !brand.isEmpty {
                Text(brand)
                    .font(theme.brandFont)
                    .foregroundColor(theme.secondaryText)
                    .lineLimit(1)
            }
            if let title = product.title, !title.isEmpty {
                Text(title)
                    .font(theme.titleFont)
                    .foregroundColor(theme.primaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            SytePriceView(product: product)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

}

/// Current price, with the original price struck through when the product is on sale.
public struct SytePriceView: View {

    public let product: SyteUIProduct

    @Environment(\.syteTheme) private var theme

    public init(product: SyteUIProduct) {
        self.product = product
    }

    public var body: some View {
        HStack(spacing: 6) {
            if let price = product.price {
                Text(price)
                    .font(theme.priceFont)
                    .foregroundColor(product.isOnSale ? theme.salePrice : theme.primaryText)
            }
            if product.isOnSale, let original = product.originalPrice {
                Text(original)
                    .font(theme.titleFont)
                    .foregroundColor(theme.secondaryText)
                    .strikethrough()
            }
        }
        .lineLimit(1)
    }

}

/// A product image at the theme's aspect ratio, cropped to fill.
public struct SyteProductImage: View {

    public let url: URL?

    @Environment(\.syteTheme) private var theme

    public init(url: URL?) {
        self.url = url
    }

    public var body: some View {
        theme.imageBackground
            .aspectRatio(theme.imageAspectRatio, contentMode: .fit)
            .overlay(
                AsyncImage(url: url, transaction: Transaction(animation: .easeOut(duration: 0.2))) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        Image(systemName: "photo").foregroundColor(theme.secondaryText)
                    default:
                        Color.clear
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous))
            .accessibilityHidden(true)
    }

}
