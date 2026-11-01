//
//  DiscoveryProvider.swift
//  Syte
//

import Foundation
import Moya

/// Recently viewed, collections and galleries. These endpoints take the API key only as a
/// `syte-api-key` header, and the account ID in the path.
enum DiscoveryProvider: BaseProvider {

    case getRecentlyViewed(accountId: String, apiKey: String, userId: String, locale: String, request: RecentlyViewed)

    case removeRecentlyViewed(accountId: String, apiKey: String, userId: String, sku: String)

    case mergeRecentlyViewed(accountId: String, apiKey: String, sourceUserId: String, targetUserId: String)

    case getCollection(accountId: String, apiKey: String, userId: String, locale: String, sessionSkus: String?, request: MerchandisingCollection)

    case getShoppableGallery(accountId: String, apiKey: String, locale: String, request: ShoppableGallery)

}

extension DiscoveryProvider: TargetType {

    var baseURL: URL {
        URL(string: "https://cdn-api.syteapi.com")!
    }

    var path: String {
        switch self {
        case .getRecentlyViewed(let accountId, _, _, _, _), .removeRecentlyViewed(let accountId, _, _, _):
            return "/\(accountId)/v2/recently-viewed"
        case .mergeRecentlyViewed(let accountId, _, _, _):
            return "/\(accountId)/v2/recently-viewed/sync"
        case .getCollection(let accountId, _, _, _, _, _):
            return "/\(accountId)/v2/collections"
        case .getShoppableGallery(let accountId, _, _, let request):
            return "/\(accountId)/v2/galleries/shoppable/\(request.id)"
        }
    }

    var method: Moya.Method {
        switch self {
        case .removeRecentlyViewed:
            return .delete
        case .mergeRecentlyViewed:
            return .patch
        default:
            return .get
        }
    }

    var task: Task {
        switch self {
        case .getRecentlyViewed(_, _, let userId, let locale, let request):
            var parameters: [String: Any] = ["user_uuid": userId, "locale": locale, "fields": request.fields.joined(separator: ",")]
            parameters["feed"] = request.feed
            parameters["force_currency"] = request.forceCurrency
            parameters.merge(request.options) { current, _ in current }
            return .requestParameters(parameters: parameters, encoding: URLEncoding.queryString)
        case .removeRecentlyViewed(_, _, let userId, let sku):
            return .requestParameters(parameters: ["user_uuid": userId, "sku": sku], encoding: URLEncoding.queryString)
        case .mergeRecentlyViewed(_, _, let sourceUserId, let targetUserId):
            return .requestParameters(parameters: ["source_uuid": sourceUserId, "target_uuid": targetUserId], encoding: JSONEncoding.default)
        case .getCollection(_, _, let userId, let locale, let sessionSkus, let request):
            // The docs' error for this call names the ID parameter `collection_id`.
            var parameters: [String: Any] = ["collection_id": request.id, "user_uuid": userId, "locale": locale,
                                             "from": request.from, "size": request.size,
                                             "fields": request.fields.joined(separator: ",")]
            parameters["filters"] = request.filters
            parameters["sku"] = request.sku
            parameters["feed"] = request.feed
            parameters["session_skus"] = sessionSkus
            parameters.merge(request.options) { current, _ in current }
            return .requestParameters(parameters: parameters, encoding: URLEncoding.queryString)
        case .getShoppableGallery(_, _, let locale, let request):
            var parameters: [String: Any] = ["locale": locale, "fields": request.fields.joined(separator: ",")]
            parameters["feed"] = request.feed
            return .requestParameters(parameters: parameters, encoding: URLEncoding.queryString)
        }
    }

    var headers: [String: String]? {
        switch self {
        case .getRecentlyViewed(_, let apiKey, _, _, _),
             .removeRecentlyViewed(_, let apiKey, _, _),
             .mergeRecentlyViewed(_, let apiKey, _, _),
             .getCollection(_, let apiKey, _, _, _, _),
             .getShoppableGallery(_, let apiKey, _, _):
            return ["Content-type": "application/json", "syte-api-key": apiKey]
        }
    }

    var sampleData: Data {
        Data()
    }

}
