//
//  FavoritesStore.swift
//  productsCatalogTest
//
//  Created by Carlos Ramos on 23/09/26.
//

import Foundation

@MainActor
struct FavoritesStore: FavoritesRepository {
    let defaults: UserDefaults
    private let key = "catalog.favoriteProducts.v1"
    private let legacyKey = "catalog.favoriteIDs.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> [Product] {
        if let data = defaults.data(forKey: key),
            let products = try? JSONDecoder().decode([ProductDTO].self, from: data) {
            return products.map(\.domain)
        }

        return (defaults.array(forKey: legacyKey) as? [Int] ?? []).map { id in
            Product(
                id: id, title: "Producto #\(id)", description: "Producto guardado en favoritos.",
                category: "", price: 0, rating: 0, stock: 0, brand: nil, thumbnail: nil, images: [])
        }
    }

    func save(_ products: [Product]) {
        guard let data = try? JSONEncoder().encode(products.map(ProductDTO.init)) else { return }
        defaults.set(data, forKey: key)
        defaults.removeObject(forKey: legacyKey)
    }
}
