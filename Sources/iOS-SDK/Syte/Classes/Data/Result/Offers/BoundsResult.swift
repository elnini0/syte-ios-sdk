//
//  BoundsResult.swift
//  Syte
//
//  Created by Artur Tarasenko on 31.08.2021.
//

import Foundation

/**
 A class that represents the return result for all of the *getBounds()* calls in {@link com.syte.ai.android_sdk.ImageSearchClient}.
 */
public class BoundsResult: Codable, ReflectedStringConvertible {
    
    /// List of retrieved bounds.
    private(set) public var bounds: [Bound]?
    
    /**
     Get offers result for the first retrieved bound. Will return null if false is passed
     to retrieveOffersForTheFirstBound property in
     ImageSearch or UrlImageSearch.
     */
    public var firstBoundItemsResult: ItemsResult?
    
    /// The image the bounds were detected in. For photo searches this is the copy Syte stored,
    /// which expires after a while. Send it as the image URL in visual search events.
    internal(set) public var imageUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case bounds
    }
    
}
