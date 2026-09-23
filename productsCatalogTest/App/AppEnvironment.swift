//
//  AppEnvironment.swift
//  productsCatalogTest
//
//  Created by Carlos Ramos on 23/09/26.
//

import Foundation

@MainActor
enum AppEnvironment {
    static func makeViewModel() -> CatalogViewModel {
        let directory = URL.applicationSupportDirectory
            .appendingPathComponent("Catalogo", isDirectory: true)
        return CatalogViewModel(
            loadCatalog: DefaultLoadCatalogUseCase(
                repository: DefaultCatalogRepository(
                    service: ProductService(),
                    cache: DiskCatalogCache(fileURL: directory.appendingPathComponent("catalog-v1.json"))
                )),
            favorites: DefaultFavoritesUseCase(repository: FavoritesStore())
        )
    }
}
