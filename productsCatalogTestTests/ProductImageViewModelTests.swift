import CoreGraphics
import Foundation
import Testing
@testable import productsCatalogTest

private actor ImageLoaderStub: ImageLoading {
    let result: Result<CGImage, any Error>
    private(set) var requestedURL: URL?
    private(set) var requestedPixels: Int?

    init(result: Result<CGImage, any Error>) { self.result = result }

    func image(at url: URL, maxPixels: Int) throws -> CGImage {
        requestedURL = url
        requestedPixels = maxPixels
        return try result.get()
    }
}

@MainActor
struct ProductImageViewModelTests {
    private let url = URL(string: "https://example.com/product.png")!

    @Test
    func successfulLoadUsesRequestedResolutionAndPublishesImage() async throws {
        let image = try makeImage()
        let loader = ImageLoaderStub(result: .success(image))
        let viewModel = ProductImageViewModel()
        await viewModel.load(url: url, maxPixels: 240, loader: loader)
        #expect(viewModel.image === image)
        #expect(!viewModel.failed)
        #expect(await loader.requestedURL == url)
        #expect(await loader.requestedPixels == 240)
    }

    @Test
    func failedImageCanBeRetriedSuccessfully() async throws {
        let viewModel = ProductImageViewModel()
        await viewModel.load(url: url, maxPixels: 80, loader: ImageLoaderStub(result: .failure(URLError(.timedOut))))
        #expect(viewModel.failed)
        #expect(viewModel.image == nil)
        await viewModel.load(url: url, maxPixels: 80, loader: ImageLoaderStub(result: .success(try makeImage())))
        #expect(!viewModel.failed)
        #expect(viewModel.image != nil)
    }

    @Test
    func changingToMissingURLClearsPreviousImageWithoutFailure() async throws {
        let viewModel = ProductImageViewModel()
        await viewModel.load(url: url, maxPixels: 80, loader: ImageLoaderStub(result: .success(try makeImage())))
        await viewModel.load(url: nil, maxPixels: 80, loader: nil)
        #expect(viewModel.image == nil)
        #expect(!viewModel.failed)
    }

    @Test
    func missingLoaderShowsRetryState() async {
        let viewModel = ProductImageViewModel()
        await viewModel.load(url: url, maxPixels: 80, loader: nil)
        #expect(viewModel.failed)
        #expect(viewModel.image == nil)
    }

    @Test
    func cancelledLoadDoesNotShowImageFailure() async {
        let viewModel = ProductImageViewModel()
        await viewModel.load(url: url, maxPixels: 80, loader: ImageLoaderStub(result: .failure(CancellationError())))
        #expect(!viewModel.failed)
        #expect(viewModel.image == nil)
    }

    private func makeImage() throws -> CGImage {
        let context = try #require(CGContext(
            data: nil, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        return try #require(context.makeImage())
    }
}
