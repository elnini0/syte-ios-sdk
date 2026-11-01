import UIKit
import iOS_SDK

/// Calls Syte through the SDK.
///
///     let syte = Syte(configuration: SyteConfiguration(accountId: "…", signature: "…"))!
///     let service = SyteLiveService(syte: syte)
@MainActor
public final class SyteLiveService: SyteUIService {

    public let syte: Syte

    /// Sent as the referer on recommendation calls.
    public var syteUrlReferer = "mobile_sdk"

    private var pendingSuggestions: OneShot<[String]>?

    public init(syte: Syte) {
        self.syte = syte
    }

    public func recommendations(_ request: SyteRecommendation, limit: Int) async throws -> [SyteUIProduct] {
        switch request {
        case let .similar(sku, imageURL):
            let similar = SimilarProducts(sku: sku, imageUrl: imageURL)
            similar.limit = limit
            similar.syteUrlReferer = syteUrlReferer
            let result = try await call { syte.getSimilarProducts(similarProducts: similar, completion: $0) }
            return (result.data ?? []).map(SyteUIProduct.init(item:))

        case let .shopTheLook(sku, imageURL):
            let look = ShopTheLook(sku: sku, imageUrl: imageURL)
            look.limit = limit
            look.syteUrlReferer = syteUrlReferer
            let result = try await call { syte.getShopTheLook(shopTheLook: look, completion: $0) }
            // Interleave the outfit's categories so the first cards aren't all from one of them.
            return result.getItemsForAllLabels(forceZip: true).prefix(limit).map(SyteUIProduct.init(item:))

        case let .personalized(sku):
            let personalization = Personalization()
            personalization.sku = sku
            personalization.limit = limit
            personalization.syteUrlReferer = syteUrlReferer
            let result = try await call { syte.getPersonalization(personalization: personalization, completion: $0) }
            return (result.data ?? []).map(SyteUIProduct.init(item:))

        case let .boughtTogether(skus):
            let together = BoughtTogether(skus: skus)
            together.limit = limit
            together.syteUrlReferer = syteUrlReferer
            let result = try await call { syte.getBoughtTogether(boughtTogether: together, completion: $0) }
            return (result.data ?? []).map(SyteUIProduct.init(item:))

        case .recentlyViewed:
            let result = try await call { syte.getRecentlyViewed(completion: $0) }
            return result.products.prefix(limit).map(SyteUIProduct.init(product:))

        case let .collection(id):
            let collection = MerchandisingCollection(id: id)
            collection.size = limit
            let result = try await call { syte.getCollection(collection: collection, completion: $0) }
            return result.products.map(SyteUIProduct.init(product:))
        }
    }

    public func detectItems(inPhoto photo: UIImage) async throws -> SyteDetection {
        let search = ImageSearch(image: photo)
        search.retrieveOffersForTheFirstBound = true
        return Self.detection(from: try await call { syte.getBoundsForImage(imageSearch: search, completion: $0) })
    }

    public func detectItems(inImageAt url: String, sku: String?) async throws -> SyteDetection {
        let search = UrlImageSearch(imageUrl: url, productType: .discoveryButton)
        search.sku = sku
        search.retrieveOffersForTheFirstBound = true
        return Self.detection(from: try await call { syte.getBoundsForImageUrl(imageSearch: search, completion: $0) })
    }

    public func products(for item: SyteDetectedItem) async throws -> [SyteUIProduct] {
        guard let bound = item.bound else { throw SyteUIError("This item has no results link.") }
        let result = try await call { syte.getItemsForBound(bound: bound, cropCoordinates: nil, completion: $0) }
        return (result.items ?? []).map(SyteUIProduct.init(item:))
    }

    public func search(_ query: String, from: Int, size: Int) async throws -> SyteSearchPage {
        let search = TextSearch(query: query, lang: syte.getConfiguration().locale)
        search.from = from
        search.size = size
        let result = try await call { syte.getTextSearch(textSearch: search, completion: $0) }
        let hits = result.result?.hits ?? []
        return SyteSearchPage(products: hits.map(SyteUIProduct.init(hit:)), total: result.result?.total ?? hits.count)
    }

    public func suggestions(for query: String) async throws -> [String] {
        // The SDK spaces autocomplete calls 500ms apart and drops or replaces calls made sooner,
        // without ever answering them. Resolve the call being replaced so nothing waits forever.
        pendingSuggestions?.resolve(.success([]))
        let request = OneShot<[String]>()
        pendingSuggestions = request
        return try await request.wait { [syte] resolve in
            syte.getAutoCompleteForTextSearch(query: query, lang: nil) { result in
                guard result.isSuccessful else { return resolve(.failure(SyteUIError(result.errorMessage ?? "Autocomplete failed."))) }
                let terms = result.data?.results?.suggestedSearchTerms?.compactMap { $0.searchTerm } ?? []
                resolve(.success(terms))
            }
        }
    }

    public func popularSearches() async throws -> [String] {
        let lang = syte.getConfiguration().locale
        return try await call { syte.getPopularSearches(lang: lang, completion: $0) }
    }

    public func recentSearches() -> [String] {
        var seen = Set<String>()
        return syte.getRecentTextSearches().filter { !$0.isEmpty && seen.insert($0.lowercased()).inserted }
    }

    public func track(_ event: BaseSyteEvent) {
        syte.fire(event: event)
    }

    static func detection(from result: BoundsResult) -> SyteDetection {
        let items = (result.bounds ?? []).enumerated().map { index, bound -> SyteDetectedItem in
            let center = bound.center ?? []
            return SyteDetectedItem(id: index,
                                    label: bound.label ?? "",
                                    center: CGPoint(x: center.first ?? 0.5, y: center.dropFirst().first ?? 0.5),
                                    gender: bound.gender,
                                    catalog: bound.catalog,
                                    bound: bound)
        }
        return SyteDetection(imageURL: result.imageUrl,
                             items: items,
                             firstItemProducts: result.firstBoundItemsResult?.items?.map(SyteUIProduct.init(item:)))
    }

    private func call<T>(_ start: (@escaping (SyteResult<T>) -> Void) -> Void) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            start { result in
                if result.isSuccessful, let data = result.data {
                    continuation.resume(returning: data)
                } else {
                    let message = result.errorMessage ?? "Syte answered \(result.resultCode)."
                    continuation.resume(throwing: SyteUIError(message))
                }
            }
        }
    }

}

/// A result that is delivered once, even when both a replacement and the original answer arrive.
@MainActor
final class OneShot<T> {

    private var continuation: CheckedContinuation<T, Error>?
    private var result: Result<T, Error>?

    func wait(_ start: (@escaping (Result<T, Error>) -> Void) -> Void) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            if let result = result {
                return continuation.resume(with: result)
            }
            self.continuation = continuation
            start { [weak self] result in
                Task { @MainActor in self?.resolve(result) }
            }
        }
    }

    func resolve(_ result: Result<T, Error>) {
        guard self.result == nil else { return }
        self.result = result
        continuation?.resume(with: result)
        continuation = nil
    }

}
