import UIKit
import iOS_SDK

/// Made-up products with no network calls, for SwiftUI previews, tests and offline demos.
/// Keeps every event it's sent in `events`.
@MainActor
public final class SytePreviewService: SyteUIService {

    public static let sampleProducts: [SyteUIProduct] = [
        ("Linen shirt", "Northline", "€49.00", nil),
        ("Wide-leg trousers", "Northline", "€39.00", "€59.00"),
        ("Wool coat", "Atelier 9", "€189.00", nil),
        ("Leather loafers", "Brunn", "€120.00", nil),
        ("Knit cardigan", "Atelier 9", "€45.00", "€65.00"),
        ("Denim jacket", "Brunn", "€79.00", nil),
        ("Silk scarf", "Maison Ore", "€35.00", nil),
        ("Canvas tote", "Northline", "€25.00", nil)
    ].enumerated().map { index, product in
        SyteUIProduct(sku: "SAMPLE-\(index + 1)",
                      title: product.0,
                      brand: product.1,
                      productURL: URL(string: "https://example.com/p/\(index + 1)"),
                      price: product.2,
                      originalPrice: product.3,
                      isOnSale: product.3 != nil)
    }

    /// Wait before each answer, to show loading states.
    public var delay: TimeInterval

    /// When set, every call fails with this message.
    public var failure: String?

    public private(set) var events: [BaseSyteEvent] = []

    public init(delay: TimeInterval = 0.4) {
        self.delay = delay
    }

    public func recommendations(_ request: SyteRecommendation, limit: Int) async throws -> [SyteUIProduct] {
        try await answer()
        let shift: Int
        switch request {
        case .similar: shift = 0
        case .shopTheLook: shift = 2
        case .personalized: shift = 4
        case .boughtTogether: shift = 6
        case .recentlyViewed: shift = 1
        case .collection: shift = 3
        }
        let products = Self.sampleProducts
        return Array((products[shift...] + products[..<shift]).prefix(limit))
    }

    public func detectItems(inPhoto photo: UIImage) async throws -> SyteDetection {
        try await answer()
        return Self.sampleDetection(imageURL: "https://example.com/uploads/photo.jpg")
    }

    public func detectItems(inImageAt url: String, sku: String?) async throws -> SyteDetection {
        try await answer()
        return Self.sampleDetection(imageURL: url)
    }

    public func products(for item: SyteDetectedItem) async throws -> [SyteUIProduct] {
        try await answer()
        return Array(Self.sampleProducts.reversed().dropFirst(item.id))
    }

    public func search(_ query: String, from: Int, size: Int) async throws -> SyteSearchPage {
        try await answer()
        let matches = Self.sampleProducts.filter {
            ($0.title ?? "").localizedCaseInsensitiveContains(query) || ($0.brand ?? "").localizedCaseInsensitiveContains(query)
        }
        let found = matches.isEmpty && query.count < 3 ? Self.sampleProducts : matches
        return SyteSearchPage(products: Array(found.dropFirst(from).prefix(size)), total: found.count)
    }

    public func suggestions(for query: String) async throws -> [String] {
        try await answer()
        return Self.sampleProducts.compactMap { $0.title?.lowercased() }.filter { $0.contains(query.lowercased()) }
    }

    public func popularSearches() async throws -> [String] {
        try await answer()
        return ["coat", "shirt", "loafers"]
    }

    public func recentSearches() -> [String] {
        []
    }

    public func track(_ event: BaseSyteEvent) {
        events.append(event)
    }

    private func answer() async throws {
        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        if let failure = failure {
            throw SyteUIError(failure)
        }
    }

    private static func sampleDetection(imageURL: String) -> SyteDetection {
        SyteDetection(imageURL: imageURL,
                      items: [
                        SyteDetectedItem(id: 0, label: "tops", center: CGPoint(x: 0.5, y: 0.32), gender: "female", catalog: "fashion"),
                        SyteDetectedItem(id: 1, label: "pants", center: CGPoint(x: 0.48, y: 0.68), gender: "female", catalog: "fashion")
                      ],
                      firstItemProducts: sampleProducts)
    }

}
