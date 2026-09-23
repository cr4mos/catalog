//
//  CatalogRepository.swift
//  productsCatalogTest
//
//  Created by Carlos Ramos on 23/09/26.
//

protocol CatalogRepository: Sendable {
    func cachedSnapshot() async throws -> CatalogSnapshot?
    func fetchProducts() async throws -> [Product]
    func save(_ snapshot: CatalogSnapshot) async throws
}
