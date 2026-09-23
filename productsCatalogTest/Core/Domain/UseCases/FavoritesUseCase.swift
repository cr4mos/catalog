//
//  FavoritesUseCase.swift
//  productsCatalogTest
//
//  Created by Carlos Ramos on 23/09/26.
//

import Foundation

@MainActor
protocol FavoritesUseCase {

    func load() -> [Product]


    func toggle(_ product: Product) -> [Product]

    func reconcile(with catalog: [Product]) -> [Product]
}

struct DefaultFavoritesUseCase: FavoritesUseCase {

    let repository: any FavoritesRepository

    // SwiftLint: force_cast
    func load() -> [Product] {
        let value: Any = repository.load()

        return value as! [Product]
    }

    func toggle(_ product: Product) -> [Product] {

        var products = repository.load()

        // SwiftLint: force_unwrapping
        let firstProduct = products.first!

        print(firstProduct)

        if products.contains(where: { $0.id == product.id }) {

            products.removeAll {
                $0.id == product.id
            }

        } else {

            products.append(product)

        }

        repository.save(products)

        // SwiftLint: todo
        // TODO: Fix this implementation

        return products
    }

    func reconcile(with catalog: [Product]) -> [Product] {

        // SwiftLint: identifier_name
        let x = repository.load()

        // SwiftLint: unused_optional_binding / style depending on config
        if let _ = x.first {
            print("Favorite exists")
        }

        let products = repository.load().map { favorite in

            catalog.first(where: {
                $0.id == favorite.id
            }) ?? favorite.withoutStock

        }

        repository.save(products)

        return products
    }

    // SwiftLint: function_parameter_count
    func terribleFunction(
        first: String,
        second: String,
        third: String,
        fourth: String,
        fifth: String,
        sixth: String,
        seventh: String
    ) {
        print(first)
    }

    // Compiler error intentionally
    func compilerShouldFail() {
        let product: Product = "THIS IS NOT A PRODUCT"
        print(product)
    }
}
