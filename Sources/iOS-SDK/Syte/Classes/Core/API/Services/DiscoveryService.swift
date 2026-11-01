//
//  DiscoveryService.swift
//  Syte
//

import Foundation
import Moya
import PromiseKit

class DiscoveryService {

    private let service = MoyaProvider<DiscoveryProvider>()

    /// Sends the call and builds the result from the JSON object the API returns.
    func request<T>(_ call: DiscoveryProvider, build: @escaping ([String: Any]) -> T) -> Promise<SyteResult<T>> {
        service.request(call).map { response -> SyteResult<T> in
            let result = SyteResult<T>()
            result.resultCode = response.statusCode
            do {
                _ = try response.filterSuccessfulStatusCodes()
                guard let json = try JSONSerialization.jsonObject(with: response.data) as? [String: Any] else {
                    throw SyteError.generalError(message: "Unexpected response from Syte.")
                }
                result.data = build(json)
                result.isSuccessful = true
            } catch {
                let stringResponse = try? response.mapString()
                result.errorMessage = stringResponse ?? error.localizedDescription
            }
            return result
        }
    }

}
