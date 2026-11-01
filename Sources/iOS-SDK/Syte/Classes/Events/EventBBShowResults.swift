//
//  EventBBShowResults.swift
//  Syte
//
//  Created by Artur Tarasenko on 15.09.2021.
//

import Foundation

/**
 This event should be sent to Syte every time a results for specific bound from the image are shown
 */
public class EventBBShowResults: BaseSyteEvent {
    
    // Url of image used
    private let imageUrl: String
    
    // The bound category as returned in the bounds request
    private let category: String
    
    // The number of returned results in the offers request
    private let resultsCount: Int
    
    // SKUs of the results shown, in order
    private let skus: [String]?
    
    // SKU of the product whose image was searched, if any
    private let sku: String?
    
    // Index of the bound the results belong to
    private let boundIndex: Int?
    
    enum CodingKeys: String, CodingKey {
        case category, skus, sku
        case imageUrl = "image_url"
        case resultsCount = "results_count"
        case boundIndex = "bound_index"
    }
    
    public init(imageUrl: String, category: String, resultsCount: Int, pageName: String,
                skus: [String]? = nil, sku: String? = nil, boundIndex: Int? = nil) {
        self.imageUrl = imageUrl
        self.category = category
        self.resultsCount = resultsCount
        self.skus = skus
        self.sku = sku
        self.boundIndex = boundIndex
        
        super.init(name: "fe_bb_show_results", syteUrlReferer: pageName, tag: .camera)
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        imageUrl = try container.decode(String.self, forKey: .imageUrl)
        category = try container.decode(String.self, forKey: .category)
        resultsCount = try container.decode(Int.self, forKey: .resultsCount)
        skus = try container.decodeIfPresent(String.self, forKey: .skus)?.components(separatedBy: ",")
        sku = try container.decodeIfPresent(String.self, forKey: .sku)
        boundIndex = try container.decodeIfPresent(Int.self, forKey: .boundIndex)
        
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(imageUrl, forKey: .imageUrl)
        try container.encode(category, forKey: .category)
        try container.encode(resultsCount, forKey: .resultsCount)
        // Syte expects the result SKUs as one comma-separated string.
        try container.encodeIfPresent(skus?.joined(separator: ","), forKey: .skus)
        try container.encodeIfPresent(sku, forKey: .sku)
        try container.encodeIfPresent(boundIndex, forKey: .boundIndex)
        
        try super.encode(to: encoder)
    }
    
    override public func getRequestBodyString() -> String {
        let jsonEncoder = JSONEncoder()
        let jsonData = try? jsonEncoder.encode(self)
        let json = String(data: jsonData ?? Data(), encoding: String.Encoding.utf8)
        
        return json ?? ""
    }
    
}
