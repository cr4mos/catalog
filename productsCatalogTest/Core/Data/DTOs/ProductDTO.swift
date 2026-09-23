//
//  ProductDTO.swift
//  productsCatalogTest
//
//  Created by Carlos Ramos on 23/09/26.
//

import Foundation

struct ProductDTO: Codable {
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

    init(_ product: Product) {
        id = product.id
        title = product.title
        description = product.description
        category = product.category
        price = product.price
        rating = product.rating
        stock = product.stock
        brand = product.brand
        thumbnail = product.thumbnail
        images = product.images
    }

    var domain: Product {
        Product(
            id: id, title: title, description: description, category: category,
            price: price, rating: rating, stock: stock, brand: brand,
            thumbnail: thumbnail, images: images)
    }
}

struct ProductPageDTO: Decodable {
    let products: [ProductDTO]
    let total: Int
}

struct CatalogSnapshotDTO: Codable {
    let products: [ProductDTO]
    let savedAt: Date

    init(_ snapshot: CatalogSnapshot) {
        products = snapshot.products.map(ProductDTO.init)
        savedAt = snapshot.savedAt
    }

    var domain: CatalogSnapshot {
        CatalogSnapshot(products: products.map(\.domain), savedAt: savedAt)
    }
}
