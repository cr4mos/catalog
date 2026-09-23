import Foundation
import Testing
@testable import productsCatalogTest

struct FilterProductsTests {
    private let filter = FilterProductsUseCase()

    @Test(arguments: ["café", "CAFE", "  cafe\n", "águila", "AGUILA", "groceries", "GROCER"])
    func searchesNameBrandAndCategoryIgnoringCaseAndAccents(query: String) {
        let match = makeProduct()
        let other = makeProduct(id: 2, title: "Teléfono", category: "smartphones", brand: nil)
        #expect(filter.execute(
            products: [match, other], query: query, favoritesOnly: false, favoriteIDs: []
        ) == [match])
    }

    @Test(arguments: ["", "   \n\t"])
    func emptySearchPreservesCatalogOrder(query: String) {
        let products = [makeProduct(id: 2), makeProduct(id: 1)]
        #expect(filter.execute(
            products: products, query: query, favoritesOnly: false, favoriteIDs: []
        ) == products)
    }

    @Test
    func combinesSearchAndFavorites() {
        let favorite = makeProduct(id: 2)
        #expect(filter.execute(
            products: [makeProduct(), favorite], query: "cafe", favoritesOnly: true, favoriteIDs: [2]
        ) == [favorite])
        #expect(filter.execute(
            products: [favorite], query: "inexistente", favoritesOnly: true, favoriteIDs: [2]
        ).isEmpty)
        #expect(filter.execute(
            products: [favorite], query: "", favoritesOnly: true, favoriteIDs: []
        ).isEmpty)
    }

    @Test
    func missingBrandAndEmptyCatalogAreSupported() {
        #expect(filter.execute(
            products: [makeProduct(brand: nil)], query: "aguila", favoritesOnly: false, favoriteIDs: []
        ).isEmpty)
        #expect(filter.execute(
            products: [], query: "cafe", favoritesOnly: false, favoriteIDs: []
        ).isEmpty)
    }

    @Test
    func formatsPriceInMexicanPesos() {
        #expect(makeProduct().formattedPrice == "$1,234.50")
        #expect(makeProduct(price: 0).formattedPrice == "$0.00")
    }

    @Test(arguments: [
        "decoracion", "DECORACIÓN DEL HOGAR", "home decoration", "home-decoration", "  home   decoration "
    ])
    func searchesVisibleCategoryAndOriginalSlug(query: String) {
        let product = makeProduct(category: "home-decoration")
        #expect(filter.execute(
            products: [product], query: query, favoritesOnly: false, favoriteIDs: []
        ) == [product])
    }

    @Test(arguments: ["aguila cafe", "CAFE aguila", "aguila alimentos"])
    func matchesWordsAcrossNameBrandAndCategory(query: String) {
        #expect(filter.execute(
            products: [makeProduct()], query: query, favoritesOnly: false, favoriteIDs: []
        ) == [makeProduct()])
    }

    @Test
    func requiresAllSearchWords() {
        #expect(filter.execute(
            products: [makeProduct()], query: "aguila zapatos", favoritesOnly: false, favoriteIDs: []
        ).isEmpty)
    }

    @Test
    func categoriesHaveSpanishNamesAndSafeFallback() {
        #expect(makeProduct(category: "beauty").categoryName == "Belleza")
        #expect(makeProduct(category: "home-decoration").categoryName == "Decoración del hogar")
        #expect(makeProduct(category: "unknown-new-category").categoryName == "Otros productos")
        #expect(ProductCategory.spanishNames.count == 24)
    }
}
