import Foundation
import Testing
@testable import productsCatalogTest

@MainActor
struct LoadCatalogTests {
    private let date = Date(timeIntervalSince1970: 1_000)

    @Test
    func publishesCacheBeforeRemoteAndPersistsFreshSnapshot() async throws {
        let cached = CatalogSnapshot(products: [makeProduct()], savedAt: .distantPast)
        let fresh = CatalogSnapshot(products: [makeProduct(id: 2)], savedAt: date)
        let repository = CatalogRepositoryStub(cached: cached, remote: fresh.products)
        let useCase = DefaultLoadCatalogUseCase(repository: repository, now: { date })
        var updates: [CatalogLoadUpdate] = []
        try await useCase.execute(hasSnapshot: false) { updates.append($0) }
        #expect(updates == [.cachedSnapshot(cached), .snapshot(fresh)])
        #expect(await repository.events == ["cache", "network", "save"])
        #expect(await repository.saved == [fresh])
    }

    @Test
    func refreshDoesNotReplaceVisibleSnapshotWithOlderCache() async throws {
        let repository = CatalogRepositoryStub(fetchError: URLError(.timedOut))
        var updates: [CatalogLoadUpdate] = []
        try await DefaultLoadCatalogUseCase(repository: repository).execute(hasSnapshot: true) {
            updates.append($0)
        }
        #expect(updates == [.offline])
        #expect(await repository.events == ["network"])
    }

    @Test(arguments: [URLError.Code.timedOut, .notConnectedToInternet, .networkConnectionLost])
    func failedNetworkPreservesCachedCatalog(code: URLError.Code) async throws {
        let cached = CatalogSnapshot(products: [makeProduct()], savedAt: date)
        let repository = CatalogRepositoryStub(cached: cached, fetchError: URLError(code))
        var updates: [CatalogLoadUpdate] = []
        try await DefaultLoadCatalogUseCase(repository: repository).execute(hasSnapshot: false) {
            updates.append($0)
        }
        #expect(updates == [.cachedSnapshot(cached), .offline])
        #expect(await repository.saved.isEmpty)
    }

    @Test
    func firstLaunchWithoutConnectivityReportsUnavailable() async throws {
        let repository = CatalogRepositoryStub(fetchError: URLError(.notConnectedToInternet))
        var updates: [CatalogLoadUpdate] = []
        try await DefaultLoadCatalogUseCase(repository: repository).execute(hasSnapshot: false) {
            updates.append($0)
        }
        #expect(updates == [.unavailable])
    }

    @Test
    func corruptCacheStillAttemptsNetwork() async throws {
        let repository = CatalogRepositoryStub(remote: [makeProduct()], cacheError: TestFailure.expected)
        var updates: [CatalogLoadUpdate] = []
        try await DefaultLoadCatalogUseCase(repository: repository, now: { date }).execute(hasSnapshot: false) {
            updates.append($0)
        }
        #expect(updates == [.cacheUnavailable, .snapshot(CatalogSnapshot(products: [makeProduct()], savedAt: date))])
        #expect(await repository.events == ["cache", "network", "save"])
    }

    @Test
    func saveFailureDoesNotDiscardSuccessfulDownload() async throws {
        let repository = CatalogRepositoryStub(remote: [makeProduct()], saveError: TestFailure.expected)
        var updates: [CatalogLoadUpdate] = []
        try await DefaultLoadCatalogUseCase(repository: repository, now: { date }).execute(hasSnapshot: false) {
            updates.append($0)
        }
        #expect(updates == [.snapshot(CatalogSnapshot(products: [makeProduct()], savedAt: date)), .cacheWriteFailed])
    }

    @Test(arguments: ["cache", "network", "save"])
    func cancellationIsPropagatedWithoutMisleadingFailureMessages(stage: String) async {
        let repository = CatalogRepositoryStub(
            cacheError: stage == "cache" ? CancellationError() : nil,
            fetchError: stage == "network" ? CancellationError() : nil,
            saveError: stage == "save" ? CancellationError() : nil
        )
        var updates: [CatalogLoadUpdate] = []
        await #expect(throws: CancellationError.self) {
            try await DefaultLoadCatalogUseCase(repository: repository).execute(hasSnapshot: false) {
                updates.append($0)
            }
        }
        #expect(!updates.contains(.offline))
        #expect(!updates.contains(.unavailable))
        #expect(!updates.contains(.cacheUnavailable))
        #expect(!updates.contains(.cacheWriteFailed))
        #expect(await repository.events == Array(["cache", "network", "save"].prefix(
            stage == "cache" ? 1 : (stage == "network" ? 2 : 3)
        )))
    }
}
