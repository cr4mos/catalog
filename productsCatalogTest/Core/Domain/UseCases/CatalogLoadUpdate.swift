//
//  CatalogLoadUpdate.swift
//  productsCatalogTest
//
//  Created by Carlos Ramos on 23/09/26.
//

import Foundation

enum CatalogLoadUpdate: Equatable {
    case cachedSnapshot(CatalogSnapshot)
    case snapshot(CatalogSnapshot)
    case cacheUnavailable
    case cacheWriteFailed
    case offline
    case unavailable
}

@MainActor
protocol LoadCatalogUseCase {
    func execute(
        hasSnapshot: Bool,
        onUpdate: (CatalogLoadUpdate) -> Void
    ) async throws
}

struct DefaultLoadCatalogUseCase: LoadCatalogUseCase {
    let repository: any CatalogRepository
    var now: () -> Date = Date.init

    func execute(hasSnapshot: Bool, onUpdate: (CatalogLoadUpdate) -> Void) async throws {
        var hasSnapshot = hasSnapshot
        try Task.checkCancellation()
        if !hasSnapshot {
            do {
                if let snapshot = try await repository.cachedSnapshot() {
                    try Task.checkCancellation()
                    onUpdate(.cachedSnapshot(snapshot))
                    hasSnapshot = true
                }
            } catch {
                try rethrowCancellation(error)
                onUpdate(.cacheUnavailable)
            }
        }
        try Task.checkCancellation()
        let products: [Product]
        do {
            products = try await repository.fetchProducts()
            try Task.checkCancellation()
        } catch {
            try rethrowCancellation(error)
            onUpdate(hasSnapshot ? .offline : .unavailable)
            return
        }
        let snapshot = CatalogSnapshot(products: products, savedAt: now())
        onUpdate(.snapshot(snapshot))
        do {
            try await repository.save(snapshot)
            try Task.checkCancellation()
        } catch {
            try rethrowCancellation(error)
            onUpdate(.cacheWriteFailed)
        }
    }

    private func rethrowCancellation(_ error: Error) throws {
        if error is CancellationError || Task.isCancelled { throw CancellationError() }
    }
}
