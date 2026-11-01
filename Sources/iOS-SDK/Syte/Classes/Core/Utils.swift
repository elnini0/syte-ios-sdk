//
//  Utils.swift
//  Syte
//
//  Created by Artur Tarasenko on 31.08.2021.
//

import Foundation

class Utils {
    
    static func viewedProductsString(viewedProducts: Set<String>) -> String? {
        guard viewedProducts.isEmpty == false else { return nil }
        return viewedProducts.joined(separator: ",")
    }
    
    static func viewedProductsJSONArray(viewedProducts: Set<String>) -> String? {
        guard viewedProducts.isEmpty == false else { return nil }
        var string = "["
        for sku in viewedProducts {
            string += "\""
            string += sku
            string += "\""
            string += ","
        }
        string.removeLast()
        string += "]"
        return string
    }
    
    static func viewedProductsJSONArray(sku: String?) -> String? {
        guard let sku = sku else { return nil }
        return "[\(sku)]"
        
    }
    
    static func textSearchTermsString(terms: [String]) -> String {
        return terms.joined(separator: ",")
    }
    
    static func generateFiltersString(filters: TextSearchFilters) -> String? {
        guard !filters.isEmpty,
              let data = try? JSONSerialization.data(withJSONObject: filters, options: [.sortedKeys]) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Money amounts as Syte's event payloads expect them, e.g. "62.94".
    static func formattedAmount(_ amount: Double) -> String {
        String(format: "%.2f", locale: Locale(identifier: "en_US_POSIX"), amount)
    }

}
