//
//  BoughtTogether.swift
//  Syte
//

import Foundation

/**
 Class that is used to configure "frequently bought together" requests.
 Pass the products in the shopper's cart, or the product they are looking at.
 */
public class BoughtTogether {

    /// Products to find frequently-bought-together items for, by SKU.
    public let skus: [String]

    /// Page Name
    public var syteUrlReferer = "mobile_sdk"

    /// Number of results to return
    public var limit: Int = 7

    /// Model version
    public var modelVersion = "A"

    /// Configure what fields must be returned in response. All fields will be returned by default.
    /// In case the value is changed, the result will only contain the chosen fields. All other ones will be nil!
    public var fieldsToReturn: RecommendationReturnField = .all

    /// You can use options to include custom parameters
    public var options = [String: String]()

    public init(skus: [String]) {
        self.skus = skus
    }

}
