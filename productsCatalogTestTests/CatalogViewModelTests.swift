import Foundation
import Testing
@testable import productsCatalogTest

@MainActor
struct CatalogViewModelTests {
    @Test
    func loadsFavoritesImmediatelyAndResolvesMissingProductDetails() {
        let favorite = makeProduct()
        let viewModel = CatalogViewModel(
            loadCatalog: LoadCatalogStub(),
            favorites: DefaultFavoritesUseCase(repository: InMemoryFavorites([favorite]))
        )
        viewModel.favoritesOnly = true
        #expect(viewModel.visibleProducts == [favorite])
        #expect(viewModel.favoriteIDs == [favorite.id])
        #expect(viewModel.product(withID: favorite.id) == favorite)
        #expect(viewModel.product(withID: nil) == nil)
        #expect(viewModel.product(withID: 999) == nil)
        #expect(!viewModel.isLoading)
        #expect(!viewModel.hasSnapshot)
    }

    @Test
    func successfulLoadUpdatesDetailsAndReconcilesMissingFavorites() async {
        let loader = LoadCatalogStub()
        let fresh = makeProduct(title: "Actualizado")
        let missing = makeProduct(id: 2)
        let snapshot = CatalogSnapshot(products: [fresh], savedAt: .distantPast)
        loader.updates = [.snapshot(snapshot)]
        let viewModel = CatalogViewModel(
            loadCatalog: loader,
            favorites: DefaultFavoritesUseCase(repository: InMemoryFavorites([makeProduct(), missing]))
        )
        await viewModel.load()
        #expect(viewModel.products == [fresh])
        #expect(viewModel.product(withID: 1) == fresh)
        #expect(viewModel.product(withID: 2) == missing.withoutStock)
        #expect(viewModel.hasSnapshot)
        #expect(viewModel.savedAt == snapshot.savedAt)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.notice == nil)
        #expect(!viewModel.isLoading)
        viewModel.favoritesOnly = true
        viewModel.query = "actualizado"
        #expect(viewModel.visibleProducts == [fresh])
        viewModel.toggleFavorite(fresh)
        #expect(viewModel.visibleProducts.isEmpty)
        #expect(viewModel.favoriteIDs == [2])
    }

    @Test
    func retryClearsErrorAndRefreshPassesSnapshotState() async {
        let loader = LoadCatalogStub()
        loader.updates = [.unavailable]
        let viewModel = makeViewModel(loader)
        await viewModel.load()
        #expect(viewModel.errorMessage != nil)
        #expect(!viewModel.isLoading)
        loader.updates = [.snapshot(CatalogSnapshot(products: [makeProduct()], savedAt: .distantPast))]
        await viewModel.load()
        #expect(viewModel.errorMessage == nil)
        loader.updates = [.offline]
        await viewModel.load()
        #expect(loader.inputs == [false, false, true])
        #expect(viewModel.notice != nil)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.products == [makeProduct()])
    }

    @Test(arguments: [CatalogLoadUpdate.cacheUnavailable, .cacheWriteFailed])
    func exposesNonBlockingCacheWarnings(update: CatalogLoadUpdate) async {
        let loader = LoadCatalogStub()
        loader.updates = [update]
        let viewModel = makeViewModel(loader)
        await viewModel.load()
        #expect(viewModel.notice != nil)
        #expect(viewModel.errorMessage == nil)
        #expect(!viewModel.isLoading)
    }

    @Test
    func emptySnapshotIsAValidLoadedCatalog() async {
        let loader = LoadCatalogStub()
        loader.updates = [.snapshot(CatalogSnapshot(products: [], savedAt: .distantPast))]
        let viewModel = makeViewModel(loader)
        await viewModel.load()
        #expect(viewModel.hasSnapshot)
        #expect(viewModel.products.isEmpty)
        #expect(viewModel.errorMessage == nil)
    }

    @Test
    func ignoresOverlappingLoadRequestsWhileFirstLoadIsSuspended() async {
        let loader = LoadCatalogStub()
        let viewModel = makeViewModel(loader)
        loader.onExecute = {
            #expect(viewModel.isLoading)
            await viewModel.load()
        }
        await viewModel.load()
        #expect(loader.inputs == [false])
        #expect(!viewModel.isLoading)
    }

    @Test
    func cancellationResetsLoadingWithoutPresentingAnError() async {
        let loader = LoadCatalogStub()
        loader.error = CancellationError()
        let viewModel = makeViewModel(loader)
        await viewModel.load()
        #expect(!viewModel.isLoading)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.notice == nil)
    }

    @Test
    func unexpectedErrorsUseBlockingOrNonBlockingPresentationBasedOnExistingData() async {
        let loader = LoadCatalogStub()
        loader.error = TestFailure.expected
        let viewModel = makeViewModel(loader)
        await viewModel.load()
        #expect(viewModel.errorMessage != nil)
        loader.updates = [.snapshot(CatalogSnapshot(products: [makeProduct()], savedAt: .distantPast))]
        await viewModel.load()
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.notice != nil)
        #expect(viewModel.products == [makeProduct()])
    }

    @Test
    func favoritesRemainAccessibleDuringLoadingAndWithoutCatalogConnectivity() async {
        let loader = LoadCatalogStub()
        let favorite = makeProduct()
        let viewModel = CatalogViewModel(
            loadCatalog: loader,
            favorites: DefaultFavoritesUseCase(repository: InMemoryFavorites([favorite]))
        )
        viewModel.favoritesOnly = true
        loader.onExecute = {
            #expect(viewModel.isLoading)
            #expect(!viewModel.showsInitialLoading)
            #expect(viewModel.visibleProducts == [favorite])
        }
        loader.updates = [.unavailable]
        await viewModel.load()
        #expect(viewModel.blockingErrorMessage == nil)
        #expect(viewModel.listNotice != nil)
        #expect(viewModel.visibleProducts == [favorite])
        viewModel.favoritesOnly = false
        #expect(viewModel.blockingErrorMessage != nil)
    }

    @Test
    func staleCacheDoesNotOverwriteNewerFavoriteDetailsOrStock() async {
        let loader = LoadCatalogStub()
        let favorite = makeProduct(title: "Actualizado", stock: 20)
        let missing = makeProduct(id: 2)
        let repository = InMemoryFavorites([favorite, missing])
        loader.updates = [
            .cachedSnapshot(CatalogSnapshot(products: [makeProduct(stock: 0)], savedAt: .distantPast)),
            .offline
        ]
        let viewModel = CatalogViewModel(
            loadCatalog: loader, favorites: DefaultFavoritesUseCase(repository: repository)
        )
        await viewModel.load()
        #expect(repository.products == [favorite, missing])
        #expect(viewModel.products == [favorite])
        #expect(viewModel.product(withID: favorite.id) == favorite)
        #expect(viewModel.product(withID: missing.id) == missing)
        #expect(viewModel.hasSnapshot)
        #expect(viewModel.notice != nil)

        loader.updates = [.snapshot(CatalogSnapshot(products: [favorite], savedAt: Date()))]
        await viewModel.load()
        #expect(repository.products == [favorite, missing.withoutStock])
    }

    private func makeViewModel(_ loader: LoadCatalogStub) -> CatalogViewModel {
        CatalogViewModel(loadCatalog: loader, favorites: DefaultFavoritesUseCase(repository: InMemoryFavorites()))
    }
}
