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
        let terms = normalized(query).split(whereSeparator: \.isWhitespace)
        return products.filter { product in
            let searchable = normalized(
                [product.title, product.category, product.categoryName, product.brand ?? ""].joined(separator: " ")
            )
            let matches = terms.allSatisfy { searchable.contains($0) }
            return matches && (!favoritesOnly || favoriteIDs.contains(product.id))
        }
    }

    private func normalized(_ value: String) -> String {
        value.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "es_MX"))
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
