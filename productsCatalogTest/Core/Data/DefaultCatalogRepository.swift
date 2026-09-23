//
//  DefaultCatalogRepository.swift
//  productsCatalogTest
//
//  Created by Carlos Ramos on 23/09/26.
//

import Foundation

struct DefaultCatalogRepository: CatalogRepository {
    let service: any ProductServing
    let cache: any CatalogCaching

    func cachedSnapshot() async throws -> CatalogSnapshot? {
        try await cache.load()
    }

    func fetchProducts() async throws -> [Product] {
        do {
            return try await service.fetchProducts()
        } catch {
            if Task.isCancelled || (error as? URLError)?.code == .cancelled {
                throw CancellationError()
            }
            throw error
        }
    }

    func save(_ snapshot: CatalogSnapshot) async throws {
        try await cache.save(snapshot)
    }
}
