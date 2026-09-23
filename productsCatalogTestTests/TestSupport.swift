import Foundation
@testable import productsCatalogTest

enum TestFailure: Error {
    case expected
}

func makeProduct(
    id: Int = 1,
    title: String = "Café de prueba",
    category: String = "groceries",
    price: Decimal = Decimal(string: "1234.50")!,
    stock: Int = 8,
    brand: String? = "Marca Águila"
) -> Product {
    Product(
        id: id, title: title, description: "Descripción del producto", category: category,
        price: price, rating: 4.5, stock: stock, brand: brand,
        thumbnail: URL(string: "https://example.com/thumbnail.png"),
        images: [URL(string: "https://example.com/image.png")!]
    )
}

@MainActor
final class InMemoryFavorites: FavoritesRepository {
    var products: [Product]

    init(_ products: [Product] = []) { self.products = products }
    func load() -> [Product] { products }
    func save(_ products: [Product]) { self.products = products }
}

actor CatalogRepositoryStub: CatalogRepository {
    var cached: CatalogSnapshot?
    var remote: [Product]
    var cacheError: (any Error)?
    var fetchError: (any Error)?
    var saveError: (any Error)?
    private(set) var events: [String] = []
    private(set) var saved: [CatalogSnapshot] = []

    init(
        cached: CatalogSnapshot? = nil, remote: [Product] = [],
        cacheError: (any Error)? = nil, fetchError: (any Error)? = nil,
        saveError: (any Error)? = nil
    ) {
        self.cached = cached
        self.remote = remote
        self.cacheError = cacheError
        self.fetchError = fetchError
        self.saveError = saveError
    }

    func cachedSnapshot() throws -> CatalogSnapshot? {
        events.append("cache")
        if let cacheError { throw cacheError }
        return cached
    }

    func fetchProducts() throws -> [Product] {
        events.append("network")
        if let fetchError { throw fetchError }
        return remote
    }

    func save(_ snapshot: CatalogSnapshot) throws {
        events.append("save")
        if let saveError { throw saveError }
        saved.append(snapshot)
    }
}

@MainActor
final class LoadCatalogStub: LoadCatalogUseCase {
    var updates: [CatalogLoadUpdate] = []
    var error: (any Error)?
    var onExecute: (() async -> Void)?
    private(set) var inputs: [Bool] = []

    func execute(hasSnapshot: Bool, onUpdate: (CatalogLoadUpdate) -> Void) async throws {
        inputs.append(hasSnapshot)
        await onExecute?()
        for update in updates { onUpdate(update) }
        if let error { throw error }
    }
}
