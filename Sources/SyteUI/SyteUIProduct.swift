import Foundation
import iOS_SDK

/// A product as the UI kit shows it. Each Syte call returns its own product type,
/// so every result is mapped to this before it reaches a view.
public struct SyteUIProduct: Identifiable, Hashable {

    /// The SKU, or the image URL for the rare result without one.
    public let id: String

    public let sku: String?
    public var title: String?
    public var brand: String?
    public var imageURL: URL?

    /// The product page on the retailer's site.
    public var productURL: URL?

    /// Price as the retailer formats it, for example "€45.99".
    public var price: String?

    /// Price before discount, as the retailer formats it.
    public var originalPrice: String?

    /// True when the original price is above the current price.
    public var isOnSale: Bool

    public init(sku: String?,
                title: String? = nil,
                brand: String? = nil,
                imageURL: URL? = nil,
                productURL: URL? = nil,
                price: String? = nil,
                originalPrice: String? = nil,
                isOnSale: Bool = false) {
        self.id = sku ?? imageURL?.absoluteString ?? UUID().uuidString
        self.sku = sku
        self.title = title
        self.brand = brand
        self.imageURL = imageURL
        self.productURL = productURL
        self.price = price
        self.originalPrice = originalPrice
        self.isOnSale = isOnSale
    }

}

extension SyteUIProduct {

    /// Visual search and recommendation results.
    init(item: Item) {
        var title: String?
        if case let .string(value)? = item.originalData?["title"] { title = value }
        self.init(sku: item.sku ?? item.parentSku,
                  title: title ?? item.description,
                  brand: item.brand,
                  imageURL: URL(nonEmpty: item.imageUrl),
                  productURL: URL(nonEmpty: item.offer),
                  price: item.price,
                  originalPrice: item.originalPrice,
                  isOnSale: Self.isDiscounted(price: item.floatPrice, original: item.floatOriginalPrice))
    }

    /// Text search results.
    init(hit: HitsItem) {
        self.init(sku: hit.sku ?? hit.id,
                  title: hit.title ?? hit.description,
                  brand: hit.brand,
                  imageURL: URL(nonEmpty: hit.imageUrl),
                  productURL: URL(nonEmpty: hit.offer),
                  price: hit.price,
                  originalPrice: hit.originalPrice,
                  isOnSale: Self.isDiscounted(price: Self.amount(hit.floatPrice), original: Self.amount(hit.floatOriginalPrice)))
    }

    /// Recently viewed, collections and galleries.
    init(product: SyteProduct) {
        self.init(sku: product.sku,
                  title: product.title,
                  brand: product.brand,
                  imageURL: URL(nonEmpty: product.imageUrl),
                  productURL: URL(nonEmpty: product.url),
                  price: product.price,
                  originalPrice: product.originalPrice,
                  isOnSale: Self.isDiscounted(price: Self.amount(product.price), original: Self.amount(product.originalPrice)))
    }

    static func isDiscounted(price: Double?, original: Double?) -> Bool {
        guard let price = price, let original = original else { return false }
        return original > price
    }

    /// Reads the number out of a price string such as "45.99", "€45.99" or "45,99 €".
    static func amount(_ text: String?) -> Double? {
        guard let text = text else { return nil }
        let kept = text.filter { $0.isNumber || $0 == "." || $0 == "," }
        guard !kept.isEmpty else { return nil }
        // A comma followed by exactly two digits at the end is a decimal comma.
        if let comma = kept.lastIndex(of: ","), kept.distance(from: comma, to: kept.endIndex) == 3, !kept.contains(".") {
            return Double(kept.replacingOccurrences(of: ",", with: "."))
        }
        return Double(kept.replacingOccurrences(of: ",", with: ""))
    }

}

extension URL {

    init?(nonEmpty string: String?) {
        guard let string = string, !string.isEmpty else { return nil }
        self.init(string: string)
    }

}
