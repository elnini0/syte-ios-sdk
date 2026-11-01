//
//  ImageProcessor.swift
//  Syte
//
//  Created by Artur Tarasenko on 06.09.2021.
//

import Foundation
import UIKit
import PromiseKit

class ImageProcessor {
    
    static let scaleQuality: Int = 20
    static let smallImageMaxSize: Int = 300
    static let smallSize = CGSize(width: 500, height: 1000)
    static let mediumSize = CGSize(width: 1400, height: 1400)
    static let largeSize = CGSize(width: 2000, height: 2000)
    
    static func resize(image: UIImage, size: Int, scale: ImageScale) -> UIImage {
        var sizeResult = CGSize()
        let resultScale: ImageScale = size > smallImageMaxSize ? scale : .small
        
        switch resultScale {
        case .small:
            sizeResult = smallSize
        case .medium:
            sizeResult = mediumSize
        case .large:
            sizeResult = largeSize
        }
        
        return resizeImage(image, to: sizeResult)
    }
    
    static func compressToDataWithLoseQuality(image: UIImage, size: Int, scale: ImageScale) -> Promise<Data?> {
        Promise { seal in
            let compressed = resize(image: image, size: size, scale: scale)
            let compressedJpegData = compressed.jpegData(compressionQuality: 1)
            guard compressed.getImageSizeInKbAsJpeg() > smallImageMaxSize else { return seal.fulfill(compressedJpegData) }
            guard let currentImageSize = compressedJpegData?.count else { return seal.fulfill(nil) }
            
            let maxByte = smallImageMaxSize * 1000
            var iterationImageData: Data?
            var iterationImageSize = currentImageSize
            
            var iterationCompression: CGFloat = 1.0
            let step: CGFloat = 0.1
            
            while iterationImageSize > maxByte && iterationCompression > 0.2 {
                guard iterationCompression > 0.2,
                      let newImage = compressed.jpegData(compressionQuality: iterationCompression) else { return seal.fulfill(nil) }
                iterationImageSize = newImage.count
                iterationCompression -= step
                iterationImageData = newImage
            }
            seal.fulfill(iterationImageData)
        }
    }
    
    /// Fits the image inside `size`, keeping its proportions and never enlarging it. Drawing also
    /// applies the photo's orientation, so a portrait camera shot is uploaded upright.
    static func resizeImage(_ image: UIImage, to size: CGSize) -> UIImage {
        let pixels = CGSize(width: image.size.width * image.scale, height: image.size.height * image.scale)
        guard pixels.width > 0, pixels.height > 0 else { return image }
        let ratio = min(1, size.width / pixels.width, size.height / pixels.height)
        let target = CGSize(width: (pixels.width * ratio).rounded(), height: (pixels.height * ratio).rounded())
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: target, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
    }
    
}
