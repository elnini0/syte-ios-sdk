//
//  SyteProvider.swift
//  Syte
//
//  Created by Artur Tarasenko on 21.08.2021.
//

import Foundation
import Moya

enum SyteProvider: BaseProvider {
    
    case getSettings(accountId: String)
    
    case getBounds(parameters: GetBoundsParameters)
    
    case uploadImageForBounds(parameters: GetBoundsParameters, imageData: Data)
    
    case getOffers(parameters: GetOffersParameters)
    
    case getSimilars(parameters: GetSimilarsParameters)
    
    case getShopTheLook(parameters: GetShopTheLookParameters)
    
    case getPersonalization(parameters: GetPersonalizationParameters)
    
    case getPopularSearch(parameters: GetPopularSearchParameters)
    
    case getTextSearch(parameters: GetTextSearchParameters)
    
    case getAutoComplete(parameters: GetAutoCompleteParameters)
    
}

extension SyteProvider: TargetType, AccessTokenAuthorizable {
    
    var baseURL: URL {
        let base = URL(string: "https://cdn-api.syteapi.com")!
        switch self {
        case .getOffers(let parameters):
            return URL(string: parameters.offersUrl) ?? base
        default:
            return base
        }
        
    }
    
    var path: String {
        switch self {
        case .getSettings(let accountId):
            return "/accounts/\(accountId)"
        case .getBounds, .uploadImageForBounds:
            return "/v1.1/offers/bb"
        case .getOffers:
            return ""
        case .getSimilars:
            return "/v1.1/similars"
        case .getShopTheLook:
            return "/v1.1/similars"
        case .getPersonalization:
            return "/v1.1/personalization"
        case .getPopularSearch(let parameters):
            return "/search/\(parameters.accountId)/popularSearches"
        case .getTextSearch(let parameters):
            return "/search/\(parameters.accountId)/items"
        case .getAutoComplete(let parameters):
            return "/search/\(parameters.accountId)/autocomplete"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .getPersonalization, .uploadImageForBounds:
            return .post
        default:
            return.get
        }
    }
    
    var task: Task {
        switch self {
        case .getBounds(let parameters):
            return .requestParameters(parameters: parameters.dictionaryRepresentation(), encoding: URLEncoding.queryString)
        case .getOffers(let parameters):
            return .requestParameters(parameters: parameters.dictionaryRepresentation(), encoding: URLEncoding.queryString)
        case .getSimilars(let parameters):
            return .requestParameters(parameters: parameters.dictionaryRepresentation(), encoding: URLEncoding.queryString)
        case .getShopTheLook(let parameters):
            return .requestParameters(parameters: parameters.dictionaryRepresentation(), encoding: URLEncoding.queryString)
        case .getPersonalization(let parameters):
            return .requestCompositeData(bodyData: parameters.body, urlParameters: parameters.dictionaryRepresentation())
        case .uploadImageForBounds(let parameters, let imageData):
            var urlParameters = parameters.dictionaryRepresentation()
            urlParameters["imageUrl"] = nil
            urlParameters["payload_type"] = "image_bin"
            return .requestCompositeData(bodyData: imageData, urlParameters: urlParameters)
        case .getPopularSearch(let parameters):
            return .requestParameters(parameters: parameters.dictionaryRepresentation(), encoding: URLEncoding.queryString)
        case .getTextSearch(let parameters):
            return .requestParameters(parameters: parameters.dictionaryRepresentation(), encoding: URLEncoding.queryString)
        case .getAutoComplete(let parameters):
            return .requestParameters(parameters: parameters.dictionaryRepresentation(), encoding: URLEncoding.queryString)
        default:
            return .requestPlain
        }
    }
    
    var authorizationType: AuthorizationType? {
        .bearer
    }
    
    var headers: [String: String]? {
        var headers = ["Content-type": "application/json"]
        switch self {
        case .getPersonalization(let parameters):
            headers["Content-type"] = "text/plain"
            headers["x-api-key"] = parameters.signature
        case .getBounds(let parameters):
            headers["x-api-key"] = parameters.signature
        case .uploadImageForBounds(let parameters, _):
            headers["Content-type"] = "application/octet-stream"
            headers["x-api-key"] = parameters.signature
        case .getSimilars(let parameters):
            headers["x-api-key"] = parameters.signature
        case .getShopTheLook(let parameters):
            headers["x-api-key"] = parameters.signature
        // Text search endpoints reject x-api-key with a 403 and only take `sig`.
        // The offers link already carries its own key.
        case .getSettings, .getOffers, .getPopularSearch, .getTextSearch, .getAutoComplete:
            break
        }
        return headers
    }
    
    var sampleData: Data {
        Data()
    }
    
}
