//
//  Product.swift
//  productsCatalogTest
//
//  Created by Carlos Ramos on 23/09/26.
//

import Foundation

struct Product: Identifiable, Hashable, Sendable {
    let id: Int
    let title: String
    let description: String
    let category: String
    let price: Decimal
    let rating: Double
    let stock: Int
    let brand: String?
    let thumbnail: URL?
    let images: [URL]

    var withoutStock: Product {
        Product(
            id: id, title: title, description: description, category: category,
            price: price, rating: rating, stock: 0, brand: brand, thumbnail: thumbnail, images: images)
    }
}
