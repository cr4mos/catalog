import Foundation
import Testing
@testable import productsCatalogTest

@MainActor
struct FavoritesTests {
    @Test
    func togglesByIdentityEvenWhenProductDetailsChange() {
        let repository = InMemoryFavorites()
        let useCase = DefaultFavoritesUseCase(repository: repository)
        let product = makeProduct()
        #expect(useCase.toggle(product) == [product])
        #expect(useCase.load() == [product])
        #expect(useCase.toggle(makeProduct(title: "Nombre actualizado")).isEmpty)
        #expect(repository.products.isEmpty)
    }

    @Test
    func removingFavoritePreservesOtherFavorites() {
        let retained = makeProduct(id: 2)
        let repository = InMemoryFavorites([makeProduct(), retained])
        let useCase = DefaultFavoritesUseCase(repository: repository)
        #expect(useCase.toggle(makeProduct()) == [retained])
    }

    @Test
    func missingFavoriteRetainsDetailsAndBecomesOutOfStock() {
        let missing = makeProduct(id: 2)
        let updated = makeProduct(title: "Nombre nuevo", price: 42, stock: 3)
        let repository = InMemoryFavorites([makeProduct(), missing])
        let useCase = DefaultFavoritesUseCase(repository: repository)
        let result = useCase.reconcile(with: [updated, makeProduct(id: 3)])
        #expect(result == [updated, missing.withoutStock])
        #expect(repository.products == result)
        #expect(result[1].title == missing.title)
        #expect(result[1].stock == 0)
    }

    @Test
    func reappearingFavoriteRecoversStock() {
        let product = makeProduct()
        let useCase = DefaultFavoritesUseCase(repository: InMemoryFavorites([product]))
        #expect(useCase.reconcile(with: []) == [product.withoutStock])
        #expect(useCase.reconcile(with: [product]) == [product])
    }

    @Test
    func persistsProductsAcrossStoreInstancesAndCanClearThem() throws {
        let suite = "FavoritesTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let products = [makeProduct(), makeProduct(id: 2, brand: nil)]
        FavoritesStore(defaults: defaults).save(products)
        let reopenedDefaults = try #require(UserDefaults(suiteName: suite))
        let reopened = FavoritesStore(defaults: reopenedDefaults)
        #expect(reopened.load() == products)
        reopened.save([])
        #expect(FavoritesStore(defaults: defaults).load().isEmpty)
    }

    @Test
    func emptyAndCorruptStorageDoNotCrash() throws {
        let suite = "FavoritesTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = FavoritesStore(defaults: defaults)
        #expect(store.load().isEmpty)
        defaults.set(Data("invalid JSON".utf8), forKey: "catalog.favoriteProducts.v1")
        #expect(store.load().isEmpty)
        store.save([makeProduct()])
        #expect(store.load() == [makeProduct()])
    }

    @Test
    func migratesLegacyIDsAndRestoresDetailsFromCatalog() throws {
        let suite = "FavoritesTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set([1, 2], forKey: "catalog.favoriteIDs.v1")
        let store = FavoritesStore(defaults: defaults)
        #expect(store.load().map(\.id) == [1, 2])
        #expect(store.load().allSatisfy { $0.stock == 0 })
        let result = DefaultFavoritesUseCase(repository: store).reconcile(with: [makeProduct()])
        #expect(result.first == makeProduct())
        #expect(result.last?.stock == 0)
        #expect(defaults.object(forKey: "catalog.favoriteIDs.v1") == nil)
        #expect(FavoritesStore(defaults: defaults).load() == result)
    }
}
