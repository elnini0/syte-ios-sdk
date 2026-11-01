//
//  DiscoveryRemoteDataSource.swift
//  Syte
//

import Foundation
import PromiseKit

class DiscoveryRemoteDataSource: BaseRemoteDataSource {

    private let discoveryService = DiscoveryService()

    /// These endpoints take BCP-47 locales ("en-US"); the SDK's locale uses an underscore.
    private var locale: String {
        configuration.locale.replacingOccurrences(of: "_", with: "-")
    }

    func getRecentlyViewed(request: RecentlyViewed, completion: @escaping (SyteResult<RecentlyViewedResult>) -> Void) {
        run(.getRecentlyViewed(accountId: configuration.accountId, apiKey: configuration.signature,
                               userId: configuration.userId, locale: locale, request: request),
            build: RecentlyViewedResult.init(json:), completion: completion)
    }

    func removeRecentlyViewed(sku: String, completion: @escaping (SyteResult<Bool>) -> Void) {
        run(.removeRecentlyViewed(accountId: configuration.accountId, apiKey: configuration.signature,
                                  userId: configuration.userId, sku: sku),
            build: { _ in true }, completion: completion)
    }

    func mergeRecentlyViewed(fromUserId: String, completion: @escaping (SyteResult<Bool>) -> Void) {
        run(.mergeRecentlyViewed(accountId: configuration.accountId, apiKey: configuration.signature,
                                 sourceUserId: fromUserId, targetUserId: configuration.userId),
            build: { _ in true }, completion: completion)
    }

    func getCollection(request: MerchandisingCollection, completion: @escaping (SyteResult<CollectionResult>) -> Void) {
        run(.getCollection(accountId: configuration.accountId, apiKey: configuration.signature,
                           userId: configuration.userId, locale: locale,
                           sessionSkus: Utils.viewedProductsString(viewedProducts: configuration.getViewedProducts()),
                           request: request),
            build: CollectionResult.init(json:), completion: completion)
    }

    func getShoppableGallery(request: ShoppableGallery, completion: @escaping (SyteResult<ShoppableGalleryResult>) -> Void) {
        run(.getShoppableGallery(accountId: configuration.accountId, apiKey: configuration.signature,
                                 locale: locale, request: request),
            build: ShoppableGalleryResult.init(json:), completion: completion)
    }

    private func run<T>(_ call: DiscoveryProvider,
                        build: @escaping ([String: Any]) -> T,
                        completion: @escaping (SyteResult<T>) -> Void) {
        renewTimestamp()
        firstly {
            discoveryService.request(call, build: build)
        }.done { result in
            completion(result)
        }.catch { error in
            completion(.failureResult(message: error.localizedDescription))
        }
    }

}
