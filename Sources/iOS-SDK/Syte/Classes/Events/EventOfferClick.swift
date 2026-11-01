//
//  EventOfferClick.swift
//  Syte
//
//  Created by Artur Tarasenko on 15.09.2021.
//

import Foundation

/**
 This event should be sent to Syte every time a user clicks on product in Camera results
 */
public class EventOfferClick: BaseSyteEvent {
    
    // Unique identifier of product sent to Syte before
    private let sku: String
    
    // Index of the result in the results list
    private let position: Int
    
    // SKU of the product the results were found for, if any. Syte matches the click to the
    // results event that carried the same SKU.
    private let sourceSku: String?
    
    // Link the shopper was taken to
    private let targetUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case sku, position
        case sourceSku = "source_sku"
        case targetUrl = "target_url"
    }
    
    public init(sku: String, position: Int, pageName: String, sourceSku: String? = nil, targetUrl: String? = nil) {
        self.sku = sku
        self.position = position
        self.sourceSku = sourceSku
        self.targetUrl = targetUrl
        super.init(name: "fe_offer_click", syteUrlReferer: pageName, tags: [.discoveryButton, .camera])
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        sku = try container.decode(String.self, forKey: .sku)
        position = try container.decode(Int.self, forKey: .position)
        sourceSku = try container.decodeIfPresent(String.self, forKey: .sourceSku)
        targetUrl = try container.decodeIfPresent(String.self, forKey: .targetUrl)
        
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(sku, forKey: .sku)
        try container.encode(position, forKey: .position)
        try container.encodeIfPresent(sourceSku, forKey: .sourceSku)
        try container.encodeIfPresent(targetUrl, forKey: .targetUrl)
        
        try super.encode(to: encoder)
    }
    
    override public func getRequestBodyString() -> String {
        let jsonEncoder = JSONEncoder()
        let jsonData = try? jsonEncoder.encode(self)
        let json = String(data: jsonData ?? Data(), encoding: String.Encoding.utf8)
        
        return json ?? ""
    }
    
}
