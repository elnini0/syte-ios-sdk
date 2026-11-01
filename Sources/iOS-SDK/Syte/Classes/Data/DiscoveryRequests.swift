//
//  DiscoveryRequests.swift
//  Syte
//

import Foundation

/// Product fields requested from the recently viewed, collection and gallery endpoints unless you choose others.
public let defaultDiscoveryFields = ["sku", "title", "price", "originalPrice", "imageUrl", "offer", "brand"]

/**
 Class that is used to configure the recently viewed request. The list belongs to the SDK's shopper ID.
 */
public class RecentlyViewed {

    /// Product fields to return. Defaults to `defaultDiscoveryFields`.
    public var fields = defaultDiscoveryFields

    /// Overrides the account's default feed.
    public var feed: String?

    /// Shows prices in this currency instead of the account's default, e.g. "USD".
    public var forceCurrency: String?

    /// You can use options to include custom parameters
    public var options = [String: String]()

    public init() {}

}

/**
 Class that is used to configure a merchandising collection request.
 */
public class MerchandisingCollection {

    /// Collection ID, as set up in the Syte platform.
    public let id: String

    /// Pagination offset.
    public var from = 0

    /// Page size.
    public var size = 20

    /// Server-side filter expression, e.g. "color:blue".
    public var filters: String?

    /// Restricts or biases the collection to this product.
    public var sku: String?

    /// Product fields to return. Defaults to `defaultDiscoveryFields`.
    public var fields = defaultDiscoveryFields

    /// Overrides the account's default feed.
    public var feed: String?

    /// You can use options to include custom parameters
    public var options = [String: String]()

    public init(id: String) {
        self.id = id
    }

}

/**
 Class that is used to configure a shoppable gallery request.
 */
public class ShoppableGallery {

    /// Gallery ID, as set up in the Syte platform.
    public let id: String

    /// Product fields to return for tagged products. A small default set is always included.
    public var fields = defaultDiscoveryFields

    /// Overrides the account's default feed.
    public var feed: String?

    public init(id: String) {
        self.id = id
    }

}
