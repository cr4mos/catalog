//
//  ImageLoading.swift
//  productsCatalogTest
//
//  Created by Carlos Ramos on 23/09/26.
//

import CoreGraphics
import Foundation
import Observation
import SwiftUI

protocol ImageLoading: Sendable {
    func image(at url: URL, maxPixels: Int) async throws -> CGImage
}

private struct ImageLoaderKey: EnvironmentKey {
    static let defaultValue: (any ImageLoading)? = nil
}

extension EnvironmentValues {
    var imageLoader: (any ImageLoading)? {
        get { self[ImageLoaderKey.self] }
        set { self[ImageLoaderKey.self] = newValue }
    }
}

@MainActor @Observable
final class ProductImageViewModel {
    private(set) var image: CGImage?
    private(set) var failed = false

    func load(url: URL?, maxPixels: Int, loader: (any ImageLoading)?) async {
        image = nil
        failed = false
        guard let url else { return }
        guard let loader else { failed = true; return }
        do {
            let result = try await loader.image(at: url, maxPixels: maxPixels)
            try Task.checkCancellation()
            image = result
        } catch {
            if !Task.isCancelled && !(error is CancellationError) { failed = true }
        }
    }
}
