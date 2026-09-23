//
//  FavoritesRepository.swift
//  productsCatalogTest
//
//  Created by Carlos Ramos on 23/09/26.
//

@MainActor
protocol FavoritesRepository {
    func load() -> [Product]
    func save(_ products: [Product])
}
