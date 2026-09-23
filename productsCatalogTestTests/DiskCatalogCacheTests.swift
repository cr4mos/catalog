import Foundation
import Testing
@testable import productsCatalogTest

struct DiskCatalogCacheTests {
    @Test
    func missingFileReturnsNoSnapshot() async throws {
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        #expect(try await DiskCatalogCache(fileURL: file).load() == nil)
    }

    @Test
    func createsDirectoryAndPersistsSnapshotAcrossInstances() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("nested/catalog.json")
        let snapshot = CatalogSnapshot(
            products: [makeProduct(), makeProduct(id: 2, brand: nil)],
            savedAt: Date(timeIntervalSince1970: 1_234)
        )
        try await DiskCatalogCache(fileURL: file).save(snapshot)
        #expect(try await DiskCatalogCache(fileURL: file).load() == snapshot)
        let empty = CatalogSnapshot(products: [], savedAt: snapshot.savedAt)
        try await DiskCatalogCache(fileURL: file).save(empty)
        #expect(try await DiskCatalogCache(fileURL: file).load() == empty)
    }

    @Test
    func corruptFileReportsAnErrorAndCanBeReplaced() async throws {
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: file) }
        try Data("broken JSON".utf8).write(to: file)
        let cache = DiskCatalogCache(fileURL: file)
        await #expect(throws: DecodingError.self) { try await cache.load() }
        let snapshot = CatalogSnapshot(products: [makeProduct()], savedAt: .distantPast)
        try await cache.save(snapshot)
        #expect(try await cache.load() == snapshot)
    }

    @Test
    func unwritableDestinationPropagatesSaveError() async throws {
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: file) }
        try Data().write(to: file)
        let cache = DiskCatalogCache(fileURL: file.appendingPathComponent("catalog.json"))
        await #expect(throws: (any Error).self) {
            try await cache.save(CatalogSnapshot(products: [], savedAt: .distantPast))
        }
    }
}
