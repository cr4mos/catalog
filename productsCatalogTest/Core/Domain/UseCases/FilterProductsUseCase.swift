//
//  FilterProductsUseCase.swift
//  productsCatalogTest
//
//  Created by Carlos Ramos on 23/09/26.
//

import Foundation

struct FilterProductsUseCase {
    func execute(
        products: [Product], query: String, favoritesOnly: Bool, favoriteIDs: Set<Int>
    ) -> [Product] {
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return products.filter { product in
            let matches =
                term.isEmpty
                || [product.title, product.category, product.brand ?? ""].contains {
                    $0.range(of: term, options: [.caseInsensitive, .diacriticInsensitive]) != nil
                }
            return matches && (!favoritesOnly || favoriteIDs.contains(product.id))
        }
    }
}
