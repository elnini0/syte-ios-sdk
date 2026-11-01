import SwiftUI
import iOS_SDK

/// What a carousel shows.
public enum SyteRecommendation: Hashable {

    /// Products that look like this one. Fits a product page.
    case similar(sku: String, imageURL: String)

    /// Products that complete the outfit in this product's image. Fits a product page.
    case shopTheLook(sku: String, imageURL: String)

    /// Picks for this shopper from what they viewed, optionally anchored on a product.
    case personalized(sku: String? = nil)

    /// Products often bought with these. Fits the cart.
    case boughtTogether(skus: [String])

    /// The shopper's recently viewed products.
    case recentlyViewed

    /// A merchandising collection set up in Syte.
    case collection(id: String)

}

/// An item Syte found in a photo.
public struct SyteDetectedItem: Identifiable {

    /// Position in the detection result, starting at 0.
    public let id: Int

    /// Category, for example "Dresses".
    public let label: String

    /// Center of the item, from 0 to 1 across and down the image.
    public let center: CGPoint

    public let gender: String?
    public let catalog: String?

    let bound: Bound?

    public init(id: Int, label: String, center: CGPoint, gender: String? = nil, catalog: String? = nil) {
        self.init(id: id, label: label, center: center, gender: gender, catalog: catalog, bound: nil)
    }

    init(id: Int, label: String, center: CGPoint, gender: String?, catalog: String?, bound: Bound?) {
        self.id = id
        self.label = label
        self.center = center
        self.gender = gender
        self.catalog = catalog
        self.bound = bound
    }

}

/// The items found in a photo, with the results for the first one.
public struct SyteDetection {

    /// Link to the searched image. For photos this is Syte's stored copy. Sent with visual search events.
    public let imageURL: String?

    public let items: [SyteDetectedItem]

    /// Results for the first item, fetched with the detection to save a round trip.
    public let firstItemProducts: [SyteUIProduct]?

    public init(imageURL: String?, items: [SyteDetectedItem], firstItemProducts: [SyteUIProduct]?) {
        self.imageURL = imageURL
        self.items = items
        self.firstItemProducts = firstItemProducts
    }

}

/// One page of text search results.
public struct SyteSearchPage {

    public let products: [SyteUIProduct]

    /// Results across all pages.
    public let total: Int

    public init(products: [SyteUIProduct], total: Int) {
        self.products = products
        self.total = total
    }

}

public struct SyteUIError: LocalizedError, Equatable {

    public let message: String

    public init(_ message: String) {
        self.message = message
    }

    public var errorDescription: String? { message }

}

/// Where the views get their data and send their events. Use `SyteLiveService` in the app and
/// `SytePreviewService` in previews and tests, or write your own to wrap Syte with your backend.
@MainActor
public protocol SyteUIService: AnyObject {

    func recommendations(_ request: SyteRecommendation, limit: Int) async throws -> [SyteUIProduct]

    func detectItems(inPhoto photo: UIImage) async throws -> SyteDetection

    /// - Parameter sku: The product the image belongs to, when searching from a product page.
    func detectItems(inImageAt url: String, sku: String?) async throws -> SyteDetection

    func products(for item: SyteDetectedItem) async throws -> [SyteUIProduct]

    func search(_ query: String, from: Int, size: Int) async throws -> SyteSearchPage

    func suggestions(for query: String) async throws -> [String]

    func popularSearches() async throws -> [String]

    func recentSearches() -> [String]

    func track(_ event: BaseSyteEvent)

}

private struct SyteServiceKey: EnvironmentKey {
    static let defaultValue: SyteUIService? = nil
}

extension EnvironmentValues {

    public var syteService: SyteUIService? {
        get { self[SyteServiceKey.self] }
        set { self[SyteServiceKey.self] = newValue }
    }

}

extension View {

    /// Connects every Syte view inside this one. Create the service once, for example in your `App`,
    /// rather than inside a `body`.
    public func syteService(_ service: SyteUIService) -> some View {
        environment(\.syteService, service)
    }

}
