//
//  DiscoveryResults.swift
//  Syte
//

import Foundation

/**
 A product returned by the recently viewed, collection and gallery endpoints.
 Common fields are typed; everything the API sent is in `fields`.
 */
public class SyteProduct {

    public let sku: String?
    public let title: String?
    public let price: String?
    public let originalPrice: String?
    public let imageUrl: String?
    /// Product page URL.
    public let url: String?
    public let brand: String?
    /// Every field the API returned for this product.
    public let fields: [String: Any]

    init(json: [String: Any]) {
        fields = json
        sku = SyteProduct.text(json["sku"])
        title = SyteProduct.text(json["title"])
        price = SyteProduct.text(json["price"])
        originalPrice = SyteProduct.text(json["originalPrice"])
        imageUrl = SyteProduct.text(json["imageUrl"])
        url = SyteProduct.text(json["offer"])
        brand = SyteProduct.text(json["brand"])
    }

    /// The API sends some fields as numbers on one account and strings on another.
    static func text(_ value: Any?) -> String? {
        switch value {
        case let string as String:
            return string
        case let number as NSNumber:
            return number.stringValue
        default:
            return nil
        }
    }

    static func list(_ value: Any?) -> [SyteProduct] {
        (value as? [[String: Any]] ?? []).map(SyteProduct.init(json:))
    }

}

/**
 The shopper's recently viewed products, most recent first.
 */
public class RecentlyViewedResult {

    public let products: [SyteProduct]
    /// Currency code the prices are in, e.g. "EUR".
    public let currency: String?
    public let currencySymbol: String?

    init(json: [String: Any]) {
        products = SyteProduct.list(json["results"])
        let currencyInfo = json["currency"] as? [String: Any]
        currency = SyteProduct.text(currencyInfo?["currency"])
        currencySymbol = SyteProduct.text(currencyInfo?["symbol"])
    }

}

/**
 A page of a merchandising collection's products.
 */
public class CollectionResult {

    public let products: [SyteProduct]
    public let total: Int?
    /// Title set for the collection, when the API sends one.
    public let displayTitle: String?

    init(json: [String: Any]) {
        // The API answers in one of two layouts depending on response_format.
        let items = json["result"] as? [String: Any]
        let carousel = json["results"] as? [String: Any]
        products = SyteProduct.list(items?["hits"] ?? carousel?["products"])
        total = SyteProduct.text(items?["total"] ?? carousel?["total"]).flatMap { Int($0) }
        displayTitle = SyteProduct.text(carousel?["displayTitle"])
    }

}

/**
 A product tagged on a gallery image, with its position as fractions of the image size.
 */
public class GalleryTag {

    public let sku: String?
    public let title: String?
    public let x: Double?
    public let y: Double?
    public let isAIDetected: Bool

    init(json: [String: Any]) {
        sku = SyteProduct.text(json["sku"])
        title = SyteProduct.text(json["title"])
        let coordinates = json["coordinates"] as? [String: Any]
        x = (coordinates?["x"] as? NSNumber)?.doubleValue
        y = (coordinates?["y"] as? NSNumber)?.doubleValue
        isAIDetected = json["isAIDetected"] as? Bool ?? false
    }

}

public class GalleryImage {

    public let id: String?
    public let imageUrl: String?
    public let altText: String?
    public let caption: String?
    public let tags: [GalleryTag]

    init(json: [String: Any]) {
        id = SyteProduct.text(json["id"])
        imageUrl = SyteProduct.text(json["imageUrl"])
        altText = SyteProduct.text(json["altText"])
        caption = SyteProduct.text(json["caption"])
        tags = (json["tags"] as? [[String: Any]] ?? []).map(GalleryTag.init(json:))
    }

}

/**
 A shoppable gallery: images with products tagged on them.
 */
public class ShoppableGalleryResult {

    public let id: String?
    public let displayTitle: String?
    public let galleryName: String?
    /// Layout set for the gallery in the Syte platform, e.g. "grid" or "carousel".
    public let layoutType: String?
    public let images: [GalleryImage]

    init(json: [String: Any]) {
        id = SyteProduct.text(json["id"])
        displayTitle = SyteProduct.text(json["displayTitle"])
        galleryName = SyteProduct.text(json["galleryName"])
        layoutType = SyteProduct.text((json["layout"] as? [String: Any])?["type"])
        images = (json["images"] as? [[String: Any]] ?? []).map(GalleryImage.init(json:))
    }

}
