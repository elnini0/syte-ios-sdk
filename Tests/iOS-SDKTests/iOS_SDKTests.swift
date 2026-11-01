import XCTest
@testable import iOS_SDK

/// Offline checks for request shapes and storage. No network.
final class OfflineTests: XCTestCase {

    private let suite = "com.syte.sdk.tests"

    override func tearDown() {
        SyteStorage(suiteName: suite).clear()
        super.tearDown()
    }

    private func rawData(of event: BaseSyteEvent) throws -> [String: Any] {
        let outer = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(event.getRequestBodyString().utf8)) as? [String: Any])
        XCTAssertEqual(outer.count, 1, "Ecommerce events send only rawData in the body")
        let inner = try XCTUnwrap(outer["rawData"] as? String, "rawData must be a JSON string")
        return try XCTUnwrap(JSONSerialization.jsonObject(with: Data(inner.utf8)) as? [String: Any])
    }

    func testCartEventSendsProductsInsideRawData() throws {
        let event = EventProductsAddedToCart(productList: [Product(sku: "ABC123", quantity: 1, price: 49.99)], pageName: "cart")
        let payload = try rawData(of: event)
        let product = try XCTUnwrap((payload["products"] as? [[String: Any]])?.first)
        XCTAssertEqual(product["sku"] as? String, "ABC123")
        XCTAssertEqual(product["quantity"] as? Int, 1)
        XCTAssertEqual(product["price"] as? Double, 49.99)
    }

    func testCheckoutStartSendsTotalsAsStrings() throws {
        let event = EventCheckoutStart(price: 62.94, currency: "EUR",
                                       productList: [Product(sku: "ABC123", quantity: 1, price: 59.99)], pageName: "checkout")
        let payload = try rawData(of: event)
        XCTAssertEqual(payload["value"] as? String, "62.94")
        XCTAssertEqual(payload["currency"] as? String, "EUR")
        XCTAssertEqual((payload["products"] as? [[String: Any]])?.first?["price"] as? String, "59.99")
    }

    func testPurchaseCarriesOrderIdInsideRawData() throws {
        let event = EventCheckoutComplete(id: "ORDER-1001", value: 23.79, currency: "EUR",
                                          productList: [Product(sku: "ABC123", quantity: 1, price: 19.99)], pageName: "thank-you")
        let payload = try rawData(of: event)
        XCTAssertEqual(payload["id"] as? String, "ORDER-1001")
        XCTAssertEqual(payload["value"] as? String, "23.79")
    }

    func testSearchFiltersAreValidJSON() {
        XCTAssertNil(Utils.generateFiltersString(filters: [:]))
        XCTAssertEqual(Utils.generateFiltersString(filters: ["size": ["L", "M"]]), "{\"size\":[\"L\",\"M\"]}")
        XCTAssertEqual(Utils.generateFiltersString(filters: ["size": ["L"], "color": ["red"]]),
                       "{\"color\":[\"red\"],\"size\":[\"L\"]}")
    }

    func testShopperIdSurvivesRestart() {
        let firstLaunch = SyteStorage(suiteName: suite)
        let id = firstLaunch.getUserId()
        let secondLaunch = SyteStorage(suiteName: suite)
        XCTAssertEqual(secondLaunch.getUserId(), id)
    }

    func testStartupLeavesHostAppStorageAlone() {
        UserDefaults.standard.set("keep me", forKey: "host.app.value")
        _ = SyteConfiguration(accountId: "1", signature: "key")
        XCTAssertEqual(UserDefaults.standard.string(forKey: "host.app.value"), "keep me")
        UserDefaults.standard.removeObject(forKey: "host.app.value")
    }

    func testRecommendationCallsUseCurrentHostAndKeyHeader() {
        let call = SyteProvider.getBounds(parameters: .init(accountId: "1", signature: "key", userId: nil, sessionId: nil,
                                                             syteAppRef: "sdk", locale: "en_US", sku: nil,
                                                             imageUrl: "https://example.com/a.jpg", sessionSkus: nil, options: [:]))
        XCTAssertEqual(call.baseURL.host, "cdn-api.syteapi.com")
        XCTAssertEqual(call.headers?["x-api-key"], "key")
    }

    func testPhotoUploadGoesStraightToDetection() throws {
        let call = SyteProvider.uploadImageForBounds(parameters: .init(accountId: "1", signature: "key", userId: nil, sessionId: nil,
                                                                       syteAppRef: "camera", locale: "en_US", sku: nil,
                                                                       imageUrl: "", sessionSkus: nil, options: [:]),
                                                     imageData: Data([0xFF, 0xD8]))
        XCTAssertEqual(call.path, "/v1.1/offers/bb")
        XCTAssertEqual(call.method.rawValue, "POST")
        XCTAssertEqual(call.headers?["Content-type"], "application/octet-stream")
        XCTAssertEqual(call.headers?["x-api-key"], "key")
        guard case let .requestCompositeData(body, query) = call.task else { return XCTFail("photo bytes must be the body") }
        XCTAssertEqual(body, Data([0xFF, 0xD8]))
        XCTAssertEqual(query["payload_type"] as? String, "image_bin")
        XCTAssertEqual(query["syte_product"] as? String, "camera")
        XCTAssertNil(query["imageUrl"])
    }

    func testBoughtTogetherNeedsAtLeastOneSku() throws {
        let syte = try XCTUnwrap(Syte(configuration: SyteConfiguration(accountId: "1", signature: "key")))
        let done = expectation(description: "response")
        syte.getBoughtTogether(boughtTogether: BoughtTogether(skus: [])) { result in
            XCTAssertFalse(result.isSuccessful)
            XCTAssertNotNil(result.errorMessage)
            done.fulfill()
        }
        wait(for: [done], timeout: 5)
    }

    func testTextSearchCallsDoNotSendKeyHeader() {
        // The text search endpoints reject x-api-key with a 403.
        let call = SyteProvider.getPopularSearch(parameters: .init(accountId: "1", signature: "key", lang: "en_US"))
        XCTAssertNil(call.headers?["x-api-key"])
    }

}

/// Calls the live API. Skipped unless SYTE_ACCOUNT_ID and SYTE_API_KEY are set
/// (for xcodebuild, pass them as TEST_RUNNER_SYTE_ACCOUNT_ID and TEST_RUNNER_SYTE_API_KEY).
final class LiveAPITests: XCTestCase {

    private var syte: Syte!
    private var query = "robe"
    private var lang = "fr_FR"

    override func setUpWithError() throws {
        let env = ProcessInfo.processInfo.environment
        guard let account = env["SYTE_ACCOUNT_ID"], let key = env["SYTE_API_KEY"], !account.isEmpty, !key.isEmpty else {
            throw XCTSkip("Set SYTE_ACCOUNT_ID and SYTE_API_KEY to run live tests")
        }
        query = env["SYTE_TEST_QUERY"] ?? query
        lang = env["SYTE_TEST_LANG"] ?? lang
        let configuration = SyteConfiguration(accountId: account, signature: key)
        configuration.locale = lang
        syte = try XCTUnwrap(Syte(configuration: configuration))
    }

    private func wait<T>(_ call: (@escaping (SyteResult<T>) -> Void) -> Void, file: StaticString = #filePath, line: UInt = #line) -> SyteResult<T> {
        let done = expectation(description: "response")
        var result: SyteResult<T>!
        call { result = $0; done.fulfill() }
        wait(for: [done], timeout: 60)
        XCTAssertTrue(result.isSuccessful, "HTTP \(result.resultCode): \(result.errorMessage ?? "")", file: file, line: line)
        return result
    }

    /// Text search hit, used as the starting product for the other calls.
    private func firstHit() throws -> HitsItem {
        let search = wait { self.syte.getTextSearch(textSearch: TextSearch(query: self.query, lang: self.lang), completion: $0) }
        return try XCTUnwrap(search.data?.result?.hits?.first, "no search hits for '\(query)'")
    }

    func testPlatformSettings() {
        let settings = wait { self.syte.getPlatformSettings(completion: $0) }
        XCTAssertNotNil(settings.data?.data)
    }

    func testTextSearchWithFilters() throws {
        let plain = wait { self.syte.getTextSearch(textSearch: TextSearch(query: self.query, lang: self.lang), completion: $0) }
        let total = try XCTUnwrap(plain.data?.result?.total)
        let hit = try XCTUnwrap(plain.data?.result?.hits?.first)
        XCTAssertNotNil(hit.sku)

        let filtered = TextSearch(query: query, lang: lang)
        filtered.filters = ["size": ["L"]]
        let narrowed = wait { self.syte.getTextSearch(textSearch: filtered, completion: $0) }
        XCTAssertLessThanOrEqual(try XCTUnwrap(narrowed.data?.result?.total), total)
    }

    func testAutocompleteAndPopularSearches() {
        let suggestions = wait { self.syte.getAutoCompleteForTextSearch(query: self.query, lang: self.lang, completion: $0) }
        XCTAssertNotNil(suggestions.data)
        let none = wait { self.syte.getAutoCompleteForTextSearch(query: "zqxjv", lang: self.lang, completion: $0) }
        XCTAssertNotNil(none.data, "no suggestions should come back empty, not as an error")
        let popular = wait { self.syte.getPopularSearches(lang: self.lang, completion: $0) }
        XCTAssertNotNil(popular.data)
    }

    func testVisualSearchFromImageUrl() throws {
        let hit = try firstHit()
        let request = UrlImageSearch(imageUrl: try XCTUnwrap(hit.imageUrl), productType: .discoveryButton)
        request.sku = hit.sku
        let bounds = wait { self.syte.getBoundsForImageUrl(imageSearch: request, completion: $0) }
        XCTAssertFalse(try XCTUnwrap(bounds.data?.bounds).isEmpty)
        XCTAssertFalse(try XCTUnwrap(bounds.data?.firstBoundItemsResult?.items).isEmpty)
    }

    func testVisualSearchFromPhoto() throws {
        let hit = try firstHit()
        let data = try Data(contentsOf: try XCTUnwrap(URL(string: try XCTUnwrap(hit.imageUrl))))
        let request = ImageSearch(image: try XCTUnwrap(UIImage(data: data)))
        let bounds = wait { self.syte.getBoundsForImage(imageSearch: request, completion: $0) }
        XCTAssertFalse(try XCTUnwrap(bounds.data?.bounds).isEmpty)
        XCTAssertFalse(try XCTUnwrap(bounds.data?.firstBoundItemsResult?.items).isEmpty)
    }

    func testRecommendations() throws {
        let hit = try firstHit()
        let sku = try XCTUnwrap(hit.sku)
        let imageUrl = try XCTUnwrap(hit.imageUrl)

        let similars = wait { self.syte.getSimilarProducts(similarProducts: SimilarProducts(sku: sku, imageUrl: imageUrl), completion: $0) }
        XCTAssertFalse(try XCTUnwrap(similars.data?.data).isEmpty)

        let look = wait { self.syte.getShopTheLook(shopTheLook: ShopTheLook(sku: sku, imageUrl: imageUrl), completion: $0) }
        XCTAssertNotNil(look.data?.items)

        let together = wait { self.syte.getBoughtTogether(boughtTogether: BoughtTogether(skus: [sku]), completion: $0) }
        XCTAssertFalse(try XCTUnwrap(together.data?.data).isEmpty)

        try syte.addViewedProduct(sku: sku)
        let personal = wait { self.syte.getPersonalization(personalization: Personalization(), completion: $0) }
        XCTAssertFalse(try XCTUnwrap(personal.data?.data).isEmpty)
    }

}
