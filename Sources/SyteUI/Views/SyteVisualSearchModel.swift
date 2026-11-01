import UIKit

/// Drives `SyteVisualSearchView`: detect items in an image, preselect the first one, load results
/// for whichever item the shopper taps.
@MainActor
final class SyteVisualSearchModel: ObservableObject {

    enum Source: Equatable {
        case photo(UIImage)
        case url(URL)
    }

    enum Phase: Equatable {
        case idle
        case detecting
        case detected
        case failed(String)
    }

    @Published private(set) var source: Source?
    @Published private(set) var phase = Phase.idle
    @Published private(set) var detection: SyteDetection?
    @Published private(set) var selected: Int?
    @Published private(set) var results: [SyteUIProduct] = []
    @Published private(set) var loadingResults = false
    @Published private(set) var resultsError: String?

    var service: SyteUIService?
    var pageName = "mobile_sdk"

    /// The product whose image is being searched, when started from a product page.
    private(set) var sourceSku: String?

    /// Bumped on every new image, so answers for an earlier image are dropped.
    private var searchID = 0

    func search(photo: UIImage) async {
        source = .photo(photo)
        sourceSku = nil
        await detect { try await $0.detectItems(inPhoto: photo) }
    }

    func search(imageURL: URL, sku: String?) async {
        source = .url(imageURL)
        sourceSku = sku
        await detect { try await $0.detectItems(inImageAt: imageURL.absoluteString, sku: sku) }
    }

    func select(_ item: SyteDetectedItem) async {
        guard let service = service, let detection = detection, selected != item.id else { return }
        selected = item.id
        service.track(SyteUIEvents.itemTapped(item, in: detection, pageName: pageName))
        await loadResults(for: item, searchID: searchID)
    }

    func retry() async {
        switch (phase, source) {
        case (.failed, .photo(let photo)?):
            await search(photo: photo)
        case (.failed, .url(let url)?):
            await search(imageURL: url, sku: sourceSku)
        default:
            guard let item = detection?.items.first(where: { $0.id == selected }) else { return }
            await loadResults(for: item, searchID: searchID)
        }
    }

    func resultTapped(_ product: SyteUIProduct, at index: Int) {
        guard let event = SyteUIEvents.resultClicked(product, index: index, sourceSku: sourceSku, pageName: pageName) else { return }
        service?.track(event)
    }

    func reset() {
        searchID += 1
        source = nil
        phase = .idle
        detection = nil
        selected = nil
        results = []
        loadingResults = false
        resultsError = nil
    }

    private func detect(_ run: (SyteUIService) async throws -> SyteDetection) async {
        guard let service = service else {
            return phase = .failed("No Syte service. Add .syteService(_:) above this view.")
        }
        searchID += 1
        let id = searchID
        phase = .detecting
        detection = nil
        selected = nil
        results = []
        resultsError = nil
        do {
            let found = try await run(service)
            guard id == searchID else { return }
            detection = found
            phase = .detected
            guard let first = found.items.first else { return }
            service.track(SyteUIEvents.itemsShown(found, pageName: pageName))
            selected = first.id
            if let products = found.firstItemProducts {
                show(products, for: first)
            } else {
                await loadResults(for: first, searchID: id)
            }
        } catch {
            guard id == searchID else { return }
            phase = .failed(error.localizedDescription)
        }
    }

    private func loadResults(for item: SyteDetectedItem, searchID id: Int) async {
        guard let service = service else { return }
        loadingResults = true
        resultsError = nil
        results = []
        do {
            let products = try await service.products(for: item)
            guard id == searchID, selected == item.id else { return }
            show(products, for: item)
        } catch {
            guard id == searchID, selected == item.id else { return }
            loadingResults = false
            resultsError = error.localizedDescription
        }
    }

    private func show(_ products: [SyteUIProduct], for item: SyteDetectedItem) {
        results = products
        loadingResults = false
        guard let detection = detection, !products.isEmpty else { return }
        service?.track(SyteUIEvents.itemResultsShown(products, for: item, in: detection, sourceSku: sourceSku, pageName: pageName))
    }

}
