import XCTest
@testable import iOS_SDK

/// Request shapes and response parsing for recently viewed, collections and galleries,
/// checked against Syte's API docs. No network.
final class DiscoveryOfflineTests: XCTestCase {

    private func query(_ call: DiscoveryProvider) throws -> [String: Any] {
        guard case let .requestParameters(parameters, _) = call.task else { throw XCTSkip("not a query call") }
        return parameters
    }

    private func json(_ text: String) throws -> [String: Any] {
        try XCTUnwrap(JSONSerialization.jsonObject(with: Data(text.utf8)) as? [String: Any])
    }

    func testRecentlyViewedCallShape() throws {
        let call = DiscoveryProvider.getRecentlyViewed(accountId: "123", apiKey: "key", userId: "shopper-1",
                                                       locale: "fr-FR", request: RecentlyViewed())
        XCTAssertEqual(call.baseURL.host, "cdn-api.syteapi.com")
        XCTAssertEqual(call.path, "/123/v2/recently-viewed")
        XCTAssertEqual(call.method.rawValue, "GET")
        XCTAssertEqual(call.headers?["syte-api-key"], "key")
        let parameters = try query(call)
        XCTAssertEqual(parameters["user_uuid"] as? String, "shopper-1")
        XCTAssertEqual(parameters["locale"] as? String, "fr-FR")
        XCTAssertNil(parameters["sig"], "these endpoints take the key only as a header")
        XCTAssertEqual(parameters["fields"] as? String, defaultDiscoveryFields.joined(separator: ","))
    }

    func testRemoveAndMergeCallShapes() throws {
        let remove = DiscoveryProvider.removeRecentlyViewed(accountId: "123", apiKey: "key", userId: "shopper-1", sku: "AB-12")
        XCTAssertEqual(remove.method.rawValue, "DELETE")
        XCTAssertEqual(try query(remove)["sku"] as? String, "AB-12")

        let merge = DiscoveryProvider.mergeRecentlyViewed(accountId: "123", apiKey: "key", sourceUserId: "old", targetUserId: "new")
        XCTAssertEqual(merge.path, "/123/v2/recently-viewed/sync")
        XCTAssertEqual(merge.method.rawValue, "PATCH")
        let body = try query(merge)
        XCTAssertEqual(body["source_uuid"] as? String, "old")
        XCTAssertEqual(body["target_uuid"] as? String, "new")
    }

    func testCollectionAndGalleryCallShapes() throws {
        let collection = MerchandisingCollection(id: "summer")
        collection.filters = "color:blue"
        let call = DiscoveryProvider.getCollection(accountId: "123", apiKey: "key", userId: "shopper-1", locale: "en-US",
                                                   sessionSkus: "A,B", request: collection)
        XCTAssertEqual(call.path, "/123/v2/collections")
        let parameters = try query(call)
        XCTAssertEqual(parameters["collection_id"] as? String, "summer")
        XCTAssertEqual(parameters["filters"] as? String, "color:blue")
        XCTAssertEqual(parameters["size"] as? Int, 20)

        let gallery = DiscoveryProvider.getShoppableGallery(accountId: "123", apiKey: "key", locale: "en-US",
                                                            request: ShoppableGallery(id: "64f1c2a9e7b3d4f10a2b5c3d"))
        XCTAssertEqual(gallery.path, "/123/v2/galleries/shoppable/64f1c2a9e7b3d4f10a2b5c3d")
        XCTAssertEqual(gallery.headers?["syte-api-key"], "key")
    }

    func testRecentlyViewedParsing() throws {
        let result = RecentlyViewedResult(json: try json("""
        {"results":[{"sku":"AB-12","title":"Coat","price":49.99,"imageUrl":"https://x/a.jpg","offer":"https://x/p/ab-12"}],
         "currency":{"currency":"EUR","symbol":"€","rate":1},"requestId":"r1","feed":null}
        """))
        XCTAssertEqual(result.products.first?.sku, "AB-12")
        XCTAssertEqual(result.products.first?.price, "49.99", "numeric prices come back as text")
        XCTAssertEqual(result.products.first?.url, "https://x/p/ab-12")
        XCTAssertEqual(result.currencySymbol, "€")
    }

    func testCollectionParsingInBothLayouts() throws {
        let items = CollectionResult(json: try json(#"{"result":{"hits":[{"sku":"A"},{"sku":"B"}],"total":"42"},"message":null}"#))
        XCTAssertEqual(items.products.map { $0.sku }, ["A", "B"])
        XCTAssertEqual(items.total, 42)

        let carousel = CollectionResult(json: try json(#"{"results":{"products":[{"sku":"C"}],"total":7,"displayTitle":"Summer"}}"#))
        XCTAssertEqual(carousel.products.first?.sku, "C")
        XCTAssertEqual(carousel.total, 7)
        XCTAssertEqual(carousel.displayTitle, "Summer")
    }

    func testGalleryParsing() throws {
        let gallery = ShoppableGalleryResult(json: try json("""
        {"id":"g1","displayTitle":"Street style","layout":{"type":"grid","gridImagesPerRow":3},
         "images":[{"id":"i1","imageUrl":"https://x/1.jpg","tags":[{"sku":"AB-12","isAIDetected":true,"coordinates":{"x":0.4,"y":0.6}}]}]}
        """))
        XCTAssertEqual(gallery.layoutType, "grid")
        let tag = try XCTUnwrap(gallery.images.first?.tags.first)
        XCTAssertEqual(tag.sku, "AB-12")
        XCTAssertEqual(tag.x, 0.4)
        XCTAssertTrue(tag.isAIDetected)
    }

}

/// Live calls for recently viewed, collections and galleries. Skipped unless SYTE_TEST_DISCOVERY=1 is set
/// alongside the account, because these endpoints are enabled per account.
/// Collection and gallery checks also need SYTE_TEST_COLLECTION_ID and SYTE_TEST_GALLERY_ID.
/// (For xcodebuild, prefix each with TEST_RUNNER_.)
final class DiscoveryLiveTests: XCTestCase {

    private var syte: Syte!
    private var env: [String: String] { ProcessInfo.processInfo.environment }

    override func setUpWithError() throws {
        guard env["SYTE_TEST_DISCOVERY"] == "1", let account = env["SYTE_ACCOUNT_ID"], let key = env["SYTE_API_KEY"] else {
            throw XCTSkip("Set SYTE_TEST_DISCOVERY=1 with an account that has recently viewed, collections and galleries enabled")
        }
        syte = try XCTUnwrap(Syte(configuration: SyteConfiguration(accountId: account, signature: key)))
    }

    private func wait<T>(_ call: (@escaping (SyteResult<T>) -> Void) -> Void) -> SyteResult<T> {
        let done = expectation(description: "response")
        var result: SyteResult<T>!
        call { result = $0; done.fulfill() }
        wait(for: [done], timeout: 60)
        XCTAssertTrue(result.isSuccessful, "HTTP \(result.resultCode): \(result.errorMessage ?? "")")
        return result
    }

    func testRecentlyViewed() {
        XCTAssertNotNil(wait { self.syte.getRecentlyViewed(completion: $0) }.data)
    }

    func testCollection() throws {
        let id = try XCTUnwrap(env["SYTE_TEST_COLLECTION_ID"], "set SYTE_TEST_COLLECTION_ID")
        XCTAssertNotNil(wait { self.syte.getCollection(collection: MerchandisingCollection(id: id), completion: $0) }.data)
    }

    func testShoppableGallery() throws {
        let id = try XCTUnwrap(env["SYTE_TEST_GALLERY_ID"], "set SYTE_TEST_GALLERY_ID")
        XCTAssertNotNil(wait { self.syte.getShoppableGallery(gallery: ShoppableGallery(id: id), completion: $0) }.data)
    }

}
