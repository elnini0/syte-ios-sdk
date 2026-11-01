import SwiftUI
import iOS_SDK

/// Text search with recent and popular searches, suggestions while typing, and a results grid
/// that loads more as the shopper scrolls.
public struct SyteSearchView<Card: View>: View {

    let pageName: String
    let onSelect: (SyteUIProduct) -> Void
    let card: (SyteUIProduct) -> Card

    @Environment(\.syteService) private var service
    @Environment(\.syteTheme) private var theme
    @StateObject private var model = SyteSearchModel()
    @FocusState private var isTyping: Bool

    public init(pageName: String = "mobile_sdk",
                onSelect: @escaping (SyteUIProduct) -> Void = { _ in },
                @ViewBuilder card: @escaping (SyteUIProduct) -> Card) {
        self.pageName = pageName
        self.onSelect = onSelect
        self.card = card
    }

    public var body: some View {
        VStack(spacing: 0) {
            searchBar
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .background(theme.background.ignoresSafeArea())
        .task {
            model.service = service
            model.pageName = pageName
            await model.start()
        }
        .task(id: model.text) {
            await model.textChanged()
        }
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(theme.secondaryText)
            TextField(theme.strings.searchPlaceholder, text: $model.text)
                .focused($isTyping)
                .accessibilityIdentifier("syte.search.field")
                .submitLabel(.search)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .foregroundColor(theme.primaryText)
                .onSubmit { search(model.text, type: .submit) }
            if !model.text.isEmpty {
                Button {
                    model.clear()
                    isTyping = true
                } label: {
                    Image(systemName: "xmark.circle.fill").foregroundColor(theme.secondaryText)
                }
                .accessibilityLabel("Clear")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous).fill(theme.imageBackground))
        .padding(.horizontal, theme.edgeInset)
        .padding(.vertical, 8)
    }

    @ViewBuilder private var content: some View {
        switch model.phase {
        case .browsing:
            ScrollView {
                if model.text.trimmingCharacters(in: .whitespaces).isEmpty {
                    termSection(theme.strings.recentSearches, terms: Array(model.recent.prefix(5)), icon: "clock", type: .recentSearch)
                    termSection(theme.strings.popularSearches, terms: model.popular, icon: "chart.line.uptrend.xyaxis", type: .popularSearch)
                } else {
                    termSection(nil, terms: model.suggestions, icon: "magnifyingglass", type: .submit)
                }
            }
        case .searching:
            ProgressView().padding(.top, 48)
        case .results:
            ScrollView {
                VStack(alignment: .leading, spacing: theme.spacing) {
                    Text(String(format: theme.strings.resultCount, model.total))
                        .font(theme.titleFont)
                        .foregroundColor(theme.secondaryText)
                    SyteProductGrid(products: model.results, onSelect: { _, product in
                        onSelect(product)
                    }, onReachEnd: {
                        Task { await model.loadMore() }
                    }, card: card)
                    if model.loadingMore {
                        ProgressView().frame(maxWidth: .infinity).padding()
                    }
                }
                .padding(theme.edgeInset)
            }
        case .empty:
            Text(String(format: theme.strings.noResults, model.query))
                .font(theme.titleFont)
                .foregroundColor(theme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(48)
        case .failed(let message):
            SyteErrorView(message: message) { Task { await model.retry() } }
        }
    }

    @ViewBuilder private func termSection(_ title: String?, terms: [String], icon: String, type: TextSearchEventType) -> some View {
        if !terms.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                if let title = title {
                    Text(title)
                        .font(theme.headerFont)
                        .foregroundColor(theme.primaryText)
                        .padding(.top, 16)
                        .padding(.bottom, 4)
                        .accessibilityAddTraits(.isHeader)
                }
                ForEach(terms, id: \.self) { term in
                    Button {
                        search(term, type: type)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: icon)
                                .foregroundColor(theme.secondaryText)
                                .frame(width: 20)
                            Text(term)
                                .font(theme.titleFont)
                                .foregroundColor(theme.primaryText)
                            Spacer()
                        }
                        .padding(.vertical, 11)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, theme.edgeInset)
        }
    }

    private func search(_ term: String, type: TextSearchEventType) {
        isTyping = false
        Task { await model.submit(term, type: type) }
    }

}

extension SyteSearchView where Card == SyteProductCard {

    public init(pageName: String = "mobile_sdk", onSelect: @escaping (SyteUIProduct) -> Void = { _ in }) {
        self.init(pageName: pageName, onSelect: onSelect) { SyteProductCard(product: $0) }
    }

}
