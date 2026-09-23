//
//  ProductServing.swift
//  productsCatalogTest
//
//  Created by Carlos Ramos on 23/09/26.
//

import Foundation

protocol ProductServing: Sendable {
    func fetchProducts() async throws -> [Product]
}

enum CatalogError: Error, Equatable {
    case invalidResponse
    case httpStatus(Int)
    case incompleteCatalog
}

struct ProductService: ProductServing {
    let session: URLSession
    let endpoint: URL

    init(
        session: URLSession = .shared,
        endpoint: URL = URL(string: "https://dummyjson.com/products")!
    ) {
        self.session = session
        self.endpoint = endpoint
    }

    func fetchProducts() async throws -> [Product] {
        guard var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false) else {
            throw CatalogError.invalidResponse
        }
        components.queryItems = [
            URLQueryItem(name: "limit", value: "0"),
            URLQueryItem(
                name: "select",
                value: "id,title,description,category,price,rating,stock,brand,thumbnail,images"
            ),
        ]
        guard let url = components.url else { throw CatalogError.invalidResponse }
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.cachePolicy = .reloadIgnoringLocalCacheData
        let (data, response) = try await session.data(for: request)
        try Task.checkCancellation()
        guard let response = response as? HTTPURLResponse else {
            throw CatalogError.invalidResponse
        }
        guard (200..<300).contains(response.statusCode) else {
            throw CatalogError.httpStatus(response.statusCode)
        }
        let page = try JSONDecoder().decode(ProductPageDTO.self, from: data)
        guard page.products.count == page.total,
            Set(page.products.map(\.id)).count == page.total
        else {
            throw CatalogError.incompleteCatalog
        }
        return page.products.map(\.domain)
    }
}
