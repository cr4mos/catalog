//
//  CatalogViewModel.swift
//  productsCatalogTest
//
//  Created by Carlos Ramos on 23/09/26.
//

import Foundation
import Observation

@MainActor @Observable
final class CatalogViewModel {
    private(set) var products: [Product] = []
    private(set) var favoriteProducts: [Product]
    private(set) var isLoading = false
    private(set) var hasSnapshot = false
    private(set) var savedAt: Date?
    private(set) var notice: String?
    private(set) var errorMessage: String?
    var query = ""
    var favoritesOnly = false

    @ObservationIgnored private let loadCatalog: any LoadCatalogUseCase
    @ObservationIgnored private let favorites: any FavoritesUseCase
    @ObservationIgnored private let filterProducts = FilterProductsUseCase()

    init(loadCatalog: any LoadCatalogUseCase, favorites: any FavoritesUseCase) {
        self.loadCatalog = loadCatalog
        self.favorites = favorites
        favoriteProducts = favorites.load()
    }

    var favoriteIDs: Set<Int> { Set(favoriteProducts.map(\.id)) }

    var showsInitialLoading: Bool { !favoritesOnly && !hasSnapshot && isLoading }
    var blockingErrorMessage: String? { favoritesOnly ? nil : errorMessage }
    var listNotice: String? { favoritesOnly ? (notice ?? errorMessage) : notice }

    func product(withID id: Product.ID?) -> Product? {
        favoriteProducts.first { $0.id == id } ?? products.first { $0.id == id }
    }

    var visibleProducts: [Product] {
        filterProducts.execute(
            products: favoritesOnly ? favoriteProducts : products, query: query, favoritesOnly: favoritesOnly,
            favoriteIDs: favoriteIDs
        )
    }

    func toggleFavorite(_ product: Product) {
        favoriteProducts = favorites.toggle(product)
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        notice = nil
        defer { isLoading = false }
        do {
            try await loadCatalog.execute(hasSnapshot: hasSnapshot) { update in
                apply(update)
            }
        } catch {
            if error is CancellationError || Task.isCancelled { return }
            apply(hasSnapshot ? .offline : .unavailable)
        }
    }

    private func apply(_ update: CatalogLoadUpdate) {
        switch update {
        case .cachedSnapshot(let snapshot):
            products = snapshot.products.map { cached in
                favoriteProducts.first { $0.id == cached.id } ?? cached
            }
            savedAt = snapshot.savedAt
            hasSnapshot = true
        case .snapshot(let snapshot):
            products = snapshot.products
            favoriteProducts = favorites.reconcile(with: snapshot.products)
            savedAt = snapshot.savedAt
            hasSnapshot = true
            notice = nil
            errorMessage = nil
        case .cacheUnavailable:
            notice = "No se pudo leer la copia local. Intentaremos descargar el catálogo."
        case .cacheWriteFailed:
            notice = "Catálogo actualizado. No se pudo guardar para usarlo sin conexión."
        case .offline:
            notice = "No pudimos actualizar. Estás viendo la última copia guardada."
        case .unavailable:
            errorMessage = "No pudimos cargar el catálogo. Revisa tu conexión e inténtalo de nuevo."
        }
    }
}
