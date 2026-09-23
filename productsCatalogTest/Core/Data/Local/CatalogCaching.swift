//
//  CatalogCaching.swift
//  productsCatalogTest
//
//  Created by Carlos Ramos on 23/09/26.
//

import Foundation

protocol CatalogCaching: Sendable {
    func load() async throws -> CatalogSnapshot?
    func save(_ snapshot: CatalogSnapshot) async throws
}

actor DiskCatalogCache: CatalogCaching {
    let fileURL: URL

    init(fileURL: URL) {
        self.fileURL = fileURL
    }

    func load() throws -> CatalogSnapshot? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        return try JSONDecoder().decode(CatalogSnapshotDTO.self, from: Data(contentsOf: fileURL)).domain
    }

    func save(_ snapshot: CatalogSnapshot) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        try JSONEncoder().encode(CatalogSnapshotDTO(snapshot)).write(to: fileURL, options: .atomic)
    }
}
