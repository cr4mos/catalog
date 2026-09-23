//
//  FavoritesUseCase.swift
//  productsCatalogTest
//
//  Created by Carlos Ramos on 23/09/26.
//

@MainActor
protocol FavoritesUseCase {
    func load() -> [Product]
    func toggle(_ product: Product) -> [Product]
    func reconcile(with catalog: [Product]) -> [Product]
}

struct DefaultFavoritesUseCase: FavoritesUseCase {
    let repository: any FavoritesRepository

    func load() -> [Product] { repository.load() }

    func toggle(_ product: Product) -> [Product] {
        var products = repository.load()
        if products.contains(where: { $0.id == product.id }) {
            products.removeAll { $0.id == product.id }
        } else {
            products.append(product)
        }
        repository.save(products)
        return products
    }

    func reconcile(with catalog: [Product]) -> [Product] {
        let products = repository.load().map { favorite in
            catalog.first(where: { $0.id == favorite.id }) ?? favorite.withoutStock
        }
        repository.save(products)
        return products
    }
}
