import Foundation
import Testing
@testable import productsCatalogTest

/// No shared handler: each session routes to a fixture encoded in its own URL path.
private class StubURLProtocol: URLProtocol, @unchecked Sendable {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url else { return }
        let fixture = url.lastPathComponent
        if fixture == "timeout" || fixture == "cancelled" {
            let code: URLError.Code = fixture == "timeout" ? .timedOut : .cancelled
            client?.urlProtocol(self, didFailWithError: URLError(code))
            return
        }
        if fixture == "request" {
            let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
            let fields = items.first { $0.name == "select" }?.value?.split(separator: ",").map(String.init)
            guard items.contains(URLQueryItem(name: "limit", value: "0")),
                  Set(fields ?? []) == Set([
                    "id", "title", "description", "category", "price", "rating", "stock", "brand", "thumbnail", "images"
                  ]),
                  request.timeoutInterval == 15,
                  request.cachePolicy == .reloadIgnoringLocalCacheData else {
                client?.urlProtocol(self, didFailWithError: TestFailure.expected)
                return
            }
        }
        let response: URLResponse
        if fixture == "non-http" {
            response = URLResponse(url: url, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
        } else {
            response = HTTPURLResponse(
                url: url, statusCode: Int(fixture) ?? 200, httpVersion: nil, headerFields: nil
            )!
        }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(Self.payload(for: fixture).utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    private static func payload(for fixture: String) -> String {
        let product = """
        {"id":1,"title":"Café","description":"Descripción","category":"groceries",
        "price":12.34,"rating":4.5,"stock":3,"images":["https://example.com/image.png"]}
        """
        switch fixture {
        case "malformed": return "not JSON"
        case "incomplete": return "{\"products\":[\(product)],\"total\":2}"
        case "duplicate": return "{\"products\":[\(product),\(product)],\"total\":2}"
        case "empty": return "{\"products\":[],\"total\":0}"
        default: return "{\"products\":[\(product)],\"total\":1}"
        }
    }
}

struct ProductServiceTests {
    @Test
    func requestsCompleteCatalogWithBoundedTimeoutAndMapsOptionalFields() async throws {
        let session = makeSession()
        defer { session.invalidateAndCancel() }
        let products = try await makeService("request", session: session).fetchProducts()
        let product = try #require(products.first)
        #expect(products.count == 1)
        #expect(product.id == 1)
        #expect(product.title == "Café")
        #expect(product.description == "Descripción")
        #expect(product.category == "groceries")
        #expect(product.price == Decimal(string: "12.34"))
        #expect(product.rating == 4.5)
        #expect(product.stock == 3)
        #expect(product.brand == nil)
        #expect(product.thumbnail == nil)
        #expect(product.images == [URL(string: "https://example.com/image.png")!])
    }

    @Test(arguments: [404, 429, 500, 503])
    func rejectsHTTPFailuresBeforeDecoding(status: Int) async {
        let session = makeSession()
        defer { session.invalidateAndCancel() }
        await #expect(throws: CatalogError.httpStatus(status)) {
            try await makeService(String(status), session: session).fetchProducts()
        }
    }

    @Test(arguments: ["incomplete", "duplicate"])
    func rejectsCatalogThatCouldIncorrectlyMarkFavoritesAsMissing(fixture: String) async {
        let session = makeSession()
        defer { session.invalidateAndCancel() }
        await #expect(throws: CatalogError.incompleteCatalog) {
            try await makeService(fixture, session: session).fetchProducts()
        }
    }

    @Test
    func acceptsAnAuthoritativeEmptyCatalog() async throws {
        let session = makeSession()
        defer { session.invalidateAndCancel() }
        #expect(try await makeService("empty", session: session).fetchProducts().isEmpty)
    }

    @Test
    func rejectsNonHTTPResponseAndMalformedJSON() async {
        let session = makeSession()
        defer { session.invalidateAndCancel() }
        await #expect(throws: CatalogError.invalidResponse) {
            try await makeService("non-http", session: session).fetchProducts()
        }
        await #expect(throws: DecodingError.self) {
            try await makeService("malformed", session: session).fetchProducts()
        }
    }

    @Test
    func propagatesTimeout() async {
        let session = makeSession()
        defer { session.invalidateAndCancel() }
        do {
            _ = try await makeService("timeout", session: session).fetchProducts()
            Issue.record("Expected the transport timeout to propagate")
        } catch {
            // URLSession adds request metadata to userInfo; the stable contract is its code.
            #expect((error as? URLError)?.code == .timedOut)
        }
    }

    @Test
    func repositoryNormalizesURLCancellation() async {
        let session = makeSession()
        defer { session.invalidateAndCancel() }
        let repository = DefaultCatalogRepository(
            service: makeService("cancelled", session: session),
            cache: DiskCatalogCache(
                fileURL: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            )
        )
        await #expect(throws: CancellationError.self) { try await repository.fetchProducts() }
    }

    private func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    private func makeService(_ fixture: String, session: URLSession) -> ProductService {
        ProductService(session: session, endpoint: URL(string: "https://catalog.test/\(fixture)")!)
    }
}
