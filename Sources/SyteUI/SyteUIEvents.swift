import Foundation
import iOS_SDK

/// The events the views send on their own. Positions start at 1, as in Syte's event docs.
///
/// Personalized, bought together, recently viewed and collection rows send nothing, and neither do
/// clicks on text search results: Syte documents no events for them and the SDK has none, so
/// guessing names would only add noise to reports.
enum SyteUIEvents {

    static func carouselShown(_ request: SyteRecommendation, count: Int, pageName: String) -> BaseSyteEvent? {
        switch request {
        case .similar:
            return EventSimilarItemsShowLayout(resultsCount: count, pageName: pageName)
        case .shopTheLook:
            return EventShopTheLookShowLayout(resultsCount: count, pageName: pageName)
        default:
            return nil
        }
    }

    static func carouselClicked(_ request: SyteRecommendation, product: SyteUIProduct, index: Int, pageName: String) -> BaseSyteEvent? {
        guard let sku = product.sku else { return nil }
        switch request {
        case .similar:
            return EventSimilarItemsOfferClick(sku: sku, position: index + 1, pageName: pageName)
        case .shopTheLook:
            return EventShopTheLookOfferClick(sku: sku, position: index + 1, pageName: pageName)
        default:
            return nil
        }
    }

    static func itemsShown(_ detection: SyteDetection, pageName: String) -> BaseSyteEvent {
        EventBBShowLayout(imageUrl: detection.imageURL ?? "", numOfBBs: detection.items.count, pageName: pageName)
    }

    static func itemTapped(_ item: SyteDetectedItem, in detection: SyteDetection, pageName: String) -> BaseSyteEvent {
        EventBBClick(imageUrl: detection.imageURL ?? "",
                     category: item.label,
                     gender: item.gender ?? "",
                     catalog: item.catalog ?? "",
                     pageName: pageName)
    }

    static func itemResultsShown(_ products: [SyteUIProduct], for item: SyteDetectedItem, in detection: SyteDetection,
                                 sourceSku: String?, pageName: String) -> BaseSyteEvent {
        EventBBShowResults(imageUrl: detection.imageURL ?? "",
                           category: item.label,
                           resultsCount: products.count,
                           pageName: pageName,
                           skus: products.compactMap { $0.sku },
                           sku: sourceSku,
                           boundIndex: item.id)
    }

    static func resultClicked(_ product: SyteUIProduct, index: Int, sourceSku: String?, pageName: String) -> BaseSyteEvent? {
        guard let sku = product.sku else { return nil }
        return EventOfferClick(sku: sku, position: index + 1, pageName: pageName,
                               sourceSku: sourceSku, targetUrl: product.productURL?.absoluteString)
    }

    static func searchResultsShown(query: String, type: TextSearchEventType, total: Int, pageName: String) -> BaseSyteEvent {
        EventTextShowResults(query: query, type: type.rawValue, exactCount: total, pageName: pageName)
    }

}
