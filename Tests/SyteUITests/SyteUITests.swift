import XCTest
@testable import iOS_SDK
@testable import SyteUI

/// Offline checks for the UI kit's data mapping and the events each view sends. No network.
@MainActor
final class SyteUITests: XCTestCase {

    private var service: SytePreviewService!

    override func setUp() async throws {
        service = SytePreviewService(delay: 0)
    }

    private func body(_ event: BaseSyteEvent) throws -> [String: Any] {
        try XCTUnwrap(JSONSerialization.jsonObject(with: Data(event.getRequestBodyString().utf8)) as? [String: Any])
    }

    private var eventNames: [String] {
        service.events.map { $0.name }
    }

    // MARK: - Products

    func testRecommendationItemsMapToProducts() throws {
        let json = """
        {"sku": "AB-1", "description": "Long description", "brand": "Monoprix", "imageUrl": "https://example.com/a.jpg",
         "offer": "https://example.com/p/ab-1", "price": "€29.99", "originalPrice": "€39.99",
         "floatPrice": 29.99, "floatOriginalPrice": 39.99, "original_data": {"title": "Robe longue"}}
        """
        let item = try JSONDecoder().decode(Item.self, from: Data(json.utf8))
        let product = SyteUIProduct(item: item)
        XCTAssertEqual(product.sku, "AB-1")
        XCTAssertEqual(product.title, "Robe longue", "the catalog title beats the description")
        XCTAssertEqual(product.productURL?.absoluteString, "https://example.com/p/ab-1")
        XCTAssertTrue(product.isOnSale)
    }

    func testSearchHitsMapToProducts() throws {
        let json = """
        {"sku": "6849751", "title": "Peignoir en polaire", "price": "€45.99", "originalPrice": "€45.99",
         "floatPrice": "45.99", "floatOriginalPrice": "45.99", "imageUrl": "https://example.com/b.jpg"}
        """
        let product = SyteUIProduct(hit: try JSONDecoder().decode(HitsItem.self, from: Data(json.utf8)))
        XCTAssertEqual(product.title, "Peignoir en polaire")
        XCTAssertFalse(product.isOnSale, "same price before and after isn't a sale")
    }

    func testPriceAmountsAreReadFromFormattedPrices() {
        XCTAssertEqual(SyteUIProduct.amount("€45.99"), 45.99)
        XCTAssertEqual(SyteUIProduct.amount("45,99 €"), 45.99)
        XCTAssertEqual(SyteUIProduct.amount("$1,299.00"), 1299)
        XCTAssertNil(SyteUIProduct.amount("free"))
    }

    func testDetectedItemsKeepTheirPositionAndImage() throws {
        let json = """
        {"bounds": [{"label": "dresses", "center": [0.4, 0.6], "gender": "female", "catalog": "fashion",
                     "offers": "https://cdn-api.syteapi.com/v1.1/offers?x=1"}]}
        """
        let result = try JSONDecoder().decode(BoundsResult.self, from: Data(json.utf8))
        result.imageUrl = "https://uploads.example.com/photo"
        let detection = SyteLiveService.detection(from: result)
        XCTAssertEqual(detection.imageURL, "https://uploads.example.com/photo")
        XCTAssertEqual(detection.items.first?.label, "dresses")
        XCTAssertEqual(detection.items.first?.center, CGPoint(x: 0.4, y: 0.6))
        XCTAssertNotNil(detection.items.first?.bound)
    }

    // MARK: - Carousel

    func testSimilarCarouselReportsItsResultsOnceAndEachClick() async throws {
        let model = SyteCarouselModel()
        let request = SyteRecommendation.similar(sku: "AB-1", imageURL: "https://example.com/a.jpg")
        await model.load(request, limit: 4, pageName: "pdp", service: service)
        await model.load(request, limit: 4, pageName: "pdp", service: service)

        guard case .loaded(let products) = model.state else { return XCTFail("expected products, got \(model.state)") }
        XCTAssertEqual(products.count, 4)
        XCTAssertEqual(eventNames, ["fe_si_show_layout"], "loading the same row twice reports it once")

        model.select(products[1], at: 1, request: request, pageName: "pdp", service: service)
        let click = try XCTUnwrap(service.events.last)
        XCTAssertEqual(click.name, "fe_offer_click")
        XCTAssertEqual(click.eventsTags, ["similar_items"])
        XCTAssertEqual(try body(click)["position"] as? Int, 2, "positions start at 1")
    }

    func testRowsWithoutDocumentedEventsSendNone() async {
        let model = SyteCarouselModel()
        let request = SyteRecommendation.boughtTogether(skus: ["AB-1"])
        await model.load(request, limit: 4, pageName: "cart", service: service)
        if case .loaded(let products) = model.state {
            model.select(products[0], at: 0, request: request, pageName: "cart", service: service)
        }
        XCTAssertTrue(service.events.isEmpty)
    }

    func testFailedCarouselTriesAgainNextTime() async {
        let model = SyteCarouselModel()
        service.failure = "offline"
        await model.load(.personalized(), limit: 4, pageName: "home", service: service)
        XCTAssertEqual(model.state, .failed("offline"))

        service.failure = nil
        await model.load(.personalized(), limit: 4, pageName: "home", service: service)
        guard case .loaded = model.state else { return XCTFail("expected products after retry") }
    }

    // MARK: - Visual search

    func testPhotoSearchPreselectsFirstItemAndReportsIt() async throws {
        let model = SyteVisualSearchModel()
        model.service = service
        await model.search(photo: UIImage())

        XCTAssertEqual(model.phase, .detected)
        XCTAssertEqual(model.selected, 0)
        XCTAssertEqual(model.results, SytePreviewService.sampleProducts)
        XCTAssertEqual(eventNames, ["fe_bb_show_layout", "fe_bb_show_results"])

        let shown = try body(service.events[1])
        XCTAssertEqual(shown["image_url"] as? String, "https://example.com/uploads/photo.jpg")
        XCTAssertEqual(shown["bound_index"] as? Int, 0)
        XCTAssertEqual(shown["skus"] as? String, SytePreviewService.sampleProducts.compactMap { $0.sku }.joined(separator: ","))
        XCTAssertNil(shown["sku"], "a photo has no source product")
    }

    func testTappingAnotherItemLoadsItsResults() async throws {
        let model = SyteVisualSearchModel()
        model.service = service
        await model.search(photo: UIImage())
        let second = try XCTUnwrap(model.detection?.items.last)
        await model.select(second)

        XCTAssertEqual(model.selected, 1)
        XCTAssertEqual(model.results.count, SytePreviewService.sampleProducts.count - 1)
        XCTAssertEqual(eventNames.suffix(2), ["fe_bb_bb_click", "fe_bb_show_results"])
        XCTAssertEqual(try body(service.events.last!)["bound_index"] as? Int, 1)
    }

    func testClickFromProductImageCarriesTheSourceProduct() async throws {
        let model = SyteVisualSearchModel()
        model.service = service
        await model.search(imageURL: URL(string: "https://example.com/pdp.jpg")!, sku: "AB-1")
        model.resultTapped(model.results[0], at: 0)

        XCTAssertEqual(try body(service.events[1])["sku"] as? String, "AB-1")
        let click = try body(try XCTUnwrap(service.events.last))
        XCTAssertEqual(click["source_sku"] as? String, "AB-1")
        XCTAssertEqual(click["target_url"] as? String, "https://example.com/p/1")
        XCTAssertEqual(click["position"] as? Int, 1)
    }

    func testNewPhotoDropsAnswersForTheOldOne() async {
        let model = SyteVisualSearchModel()
        service.delay = 0.2
        model.service = service
        let first = Task { await model.search(photo: UIImage()) }
        try? await Task.sleep(nanoseconds: 50_000_000)
        model.reset()
        await first.value
        XCTAssertEqual(model.phase, .idle)
        XCTAssertNil(model.detection)
    }

    // MARK: - Text search

    func testSearchReportsResultsWithHowTheQueryWasChosen() async throws {
        let model = SyteSearchModel()
        model.service = service
        await model.submit("coat", type: .popularSearch)

        XCTAssertEqual(model.phase, .results)
        XCTAssertEqual(model.results.first?.title, "Wool coat")
        let event = try XCTUnwrap(service.events.first)
        XCTAssertEqual(event.name, "fe_text_show_results")
        XCTAssertEqual(try body(event)["type"] as? String, "popular_search")
    }

    func testScrollingLoadsTheNextPage() async {
        let model = SyteSearchModel()
        model.service = PagedService()
        await model.submit("dress", type: .submit)
        XCTAssertEqual(model.results.count, SyteSearchModel.pageSize)
        await model.loadMore()
        XCTAssertEqual(model.results.count, 30)
        await model.loadMore()
        XCTAssertEqual(model.results.count, 30, "nothing left to load")
    }

    func testEditingTheQueryLeavesResultsForSuggestions() async {
        let model = SyteSearchModel()
        model.typingPause = 0
        model.service = service
        await model.submit("coat", type: .submit)

        await model.textChanged()
        XCTAssertEqual(model.phase, .results, "the box still holds the searched query")

        model.text = "shi"
        await model.textChanged()
        XCTAssertEqual(model.phase, .browsing)
        XCTAssertEqual(model.suggestions, ["linen shirt"])
    }

    func testReplacedSuggestionRequestStillAnswers() async throws {
        final class Callback { var answer: ((Result<[String], Error>) -> Void)? }
        let first = OneShot<[String]>()
        let sdk = Callback()
        let waiting = Task { try await first.wait { sdk.answer = $0 } }
        await Task.yield()
        first.resolve(.success([]))
        sdk.answer?(.success(["too late"]))
        let answer = try await waiting.value
        XCTAssertEqual(answer, [])
    }

}

/// 30 results, served a page at a time.
@MainActor
private final class PagedService: SyteUIService {

    func search(_ query: String, from: Int, size: Int) async throws -> SyteSearchPage {
        let all = (0..<30).map { SyteUIProduct(sku: "P\($0)") }
        return SyteSearchPage(products: Array(all.dropFirst(from).prefix(size)), total: all.count)
    }

    func recommendations(_ request: SyteRecommendation, limit: Int) async throws -> [SyteUIProduct] { [] }
    func detectItems(inPhoto photo: UIImage) async throws -> SyteDetection { SyteDetection(imageURL: nil, items: [], firstItemProducts: nil) }
    func detectItems(inImageAt url: String, sku: String?) async throws -> SyteDetection { try await detectItems(inPhoto: UIImage()) }
    func products(for item: SyteDetectedItem) async throws -> [SyteUIProduct] { [] }
    func suggestions(for query: String) async throws -> [String] { [] }
    func popularSearches() async throws -> [String] { [] }
    func recentSearches() -> [String] { [] }
    func track(_ event: BaseSyteEvent) {}

}

/// Runs the live service against a real account. Skipped unless SYTE_ACCOUNT_ID and SYTE_API_KEY are set
/// (for xcodebuild, pass them as TEST_RUNNER_SYTE_ACCOUNT_ID and TEST_RUNNER_SYTE_API_KEY).
@MainActor
final class SyteLiveServiceTests: XCTestCase {
    
    private var service: SyteLiveService!
    private var query = "robe"
    
    override func setUp() async throws {
        let env = ProcessInfo.processInfo.environment
        guard let account = env["SYTE_ACCOUNT_ID"], let key = env["SYTE_API_KEY"], !account.isEmpty, !key.isEmpty else {
            throw XCTSkip("Set SYTE_ACCOUNT_ID and SYTE_API_KEY to run live tests")
        }
        query = env["SYTE_TEST_QUERY"] ?? query
        let configuration = SyteConfiguration(accountId: account, signature: key)
        configuration.locale = env["SYTE_TEST_LANG"] ?? "fr_FR"
        service = SyteLiveService(syte: try XCTUnwrap(Syte(configuration: configuration)))
    }
    
    func testSearchThenRecommendationsForTheFirstResult() async throws {
        let page = try await service.search(query, from: 0, size: 4)
        let product = try XCTUnwrap(page.products.first)
        XCTAssertNotNil(product.title)
        XCTAssertNotNil(product.price)
        let sku = try XCTUnwrap(product.sku)
        let image = try XCTUnwrap(product.imageURL?.absoluteString)
        
        let similar = try await service.recommendations(.similar(sku: sku, imageURL: image), limit: 6)
        XCTAssertFalse(similar.isEmpty)
        XCTAssertTrue(similar.allSatisfy { $0.imageURL != nil && $0.sku != nil })
        let look = try await service.recommendations(.shopTheLook(sku: sku, imageURL: image), limit: 6)
        XCTAssertLessThanOrEqual(look.count, 6)
        let together = try await service.recommendations(.boughtTogether(skus: [sku]), limit: 6)
        XCTAssertFalse(together.isEmpty)
    }
    
    func testPhotoDetectionReturnsStoredImageAndResults() async throws {
        let page = try await service.search(query, from: 0, size: 1)
        let url = try XCTUnwrap(page.products.first?.imageURL)
        let (data, _) = try await URLSession.shared.data(from: url)
        let detection = try await service.detectItems(inPhoto: try XCTUnwrap(UIImage(data: data)))
        XCTAssertFalse(detection.items.isEmpty)
        XCTAssertTrue(detection.imageURL?.hasPrefix("https://") == true, "photo searches report where Syte stored the photo")
        XCTAssertFalse(try XCTUnwrap(detection.firstItemProducts).isEmpty)
        let again = try await service.products(for: detection.items[0])
        XCTAssertFalse(again.isEmpty)
    }
    
    func testSuggestionsAndPopularSearches() async throws {
        let suggestions = try await service.suggestions(for: String(query.prefix(3)))
        XCTAssertNotNil(suggestions)
        let popular = try await service.popularSearches()
        XCTAssertNotNil(popular)
    }
    
}
