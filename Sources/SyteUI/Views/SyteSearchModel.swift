import Foundation
import iOS_SDK

/// Drives `SyteSearchView`: suggestions while typing, then pages of results.
@MainActor
final class SyteSearchModel: ObservableObject {

    enum Phase: Equatable {
        /// Recent and popular searches, or suggestions for what's typed.
        case browsing
        case searching
        case results
        case empty
        case failed(String)
    }

    static let pageSize = 24

    /// Wait after the last keystroke before asking for suggestions.
    var typingPause: UInt64 = 300_000_000

    @Published var text = ""
    @Published private(set) var phase = Phase.browsing
    @Published private(set) var suggestions: [String] = []
    @Published private(set) var popular: [String] = []
    @Published private(set) var recent: [String] = []
    @Published private(set) var results: [SyteUIProduct] = []
    @Published private(set) var total = 0
    @Published private(set) var loadingMore = false

    /// The query the results are for.
    private(set) var query = ""
    private var queryType = TextSearchEventType.submit

    var service: SyteUIService?
    var pageName = "mobile_sdk"

    /// Bumped on every new search, so answers for an earlier one are dropped.
    private var searchID = 0

    private var typed: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func start() async {
        guard let service = service else { return }
        recent = service.recentSearches()
        if popular.isEmpty {
            popular = (try? await service.popularSearches()) ?? []
        }
    }

    /// Called on every change to `text`. Runs in a task that's cancelled by the next keystroke.
    func textChanged() async {
        let typed = typed
        if phase != .browsing {
            // Still showing the results for what's in the box.
            guard typed != query else { return }
            searchID += 1
            phase = .browsing
        }
        guard !typed.isEmpty, let service = service else { return suggestions = [] }
        try? await Task.sleep(nanoseconds: typingPause)
        guard !Task.isCancelled else { return }
        let found = (try? await service.suggestions(for: typed)) ?? []
        guard !Task.isCancelled, self.typed == typed, phase == .browsing else { return }
        suggestions = found
    }

    func submit(_ term: String, type: TextSearchEventType) async {
        let term = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty, let service = service else { return }
        searchID += 1
        let id = searchID
        query = term
        queryType = type
        phase = .searching
        results = []
        total = 0
        suggestions = []
        text = term
        do {
            let page = try await service.search(term, from: 0, size: Self.pageSize)
            guard id == searchID else { return }
            results = page.products
            total = page.total
            phase = page.products.isEmpty ? .empty : .results
            if !page.products.isEmpty {
                service.track(SyteUIEvents.searchResultsShown(query: term, type: type, total: page.total, pageName: pageName))
            }
            recent = service.recentSearches()
        } catch {
            guard id == searchID else { return }
            phase = .failed(error.localizedDescription)
        }
    }

    func loadMore() async {
        guard phase == .results, !loadingMore, results.count < total, let service = service else { return }
        let id = searchID
        loadingMore = true
        let page = try? await service.search(query, from: results.count, size: Self.pageSize)
        guard id == searchID else { return }
        loadingMore = false
        guard let page = page else { return }
        results += page.products
        // An empty page before the total is reached means the total was an estimate.
        if page.products.isEmpty { total = results.count }
    }

    func retry() async {
        await submit(query, type: queryType)
    }

    func clear() {
        searchID += 1
        text = ""
        query = ""
        phase = .browsing
        suggestions = []
        results = []
        total = 0
    }

}
