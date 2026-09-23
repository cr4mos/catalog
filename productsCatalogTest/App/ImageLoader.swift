//
//  ImageLoader.swift
//  productsCatalogTest
//
//  Created by Carlos Ramos on 23/09/26.
//

import Foundation
import ImageIO

actor ImageLoader: ImageLoading {
    static let shared = ImageLoader()

    private let cache = URLCache(
        memoryCapacity: 20 * 1_024 * 1_024, diskCapacity: 100 * 1_024 * 1_024,
        directory: URL.cachesDirectory.appendingPathComponent("product-images")
    )
    private let session: URLSession

    init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 12
        session = URLSession(configuration: configuration)
    }

    func image(at url: URL, maxPixels: Int) async throws -> CGImage {
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
        let data: Data
        if let cached = cache.cachedResponse(for: request) {
            data = cached.data
        } else {
            let (download, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse,
                (200..<300).contains(http.statusCode),
                response.mimeType?.hasPrefix("image/") == true
            else { throw CatalogError.invalidResponse }
            data = download
            cache.storeCachedResponse(CachedURLResponse(response: response, data: data), for: request)
        }
        try Task.checkCancellation()
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
            let image = CGImageSourceCreateThumbnailAtIndex(
                source, 0,
                [
                    kCGImageSourceCreateThumbnailFromImageAlways: true,
                    kCGImageSourceThumbnailMaxPixelSize: maxPixels,
                    kCGImageSourceCreateThumbnailWithTransform: true,
                    kCGImageSourceShouldCacheImmediately: true
                ] as CFDictionary
            )
        else { throw CatalogError.invalidResponse }
        return image
    }
}
