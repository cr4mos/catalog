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
    private(set) var isLoading = false
    private(set) var hasSnapshot = false
    private(set) var savedAt: Date?
    private(set) var notice: String?
    private(set) var errorMessage: String?
    var query = ""
    var favoritesOnly = false

    @ObservationIgnored private let loadCatalog: any LoadCatalogUseCase

    init(loadCatalog: any LoadCatalogUseCase) {
        self.loadCatalog = loadCatalog
    }

    func product(withID id: Product.ID?) -> Product? {
        products.first { $0.id == id }
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
        case .snapshot(let snapshot):
            products = snapshot.products
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
