import SwiftUI

/// Colors, fonts, sizes and text for every Syte view. Set it once near the root of the app:
///
///     var theme = SyteTheme()
///     theme.accent = .brown
///     theme.strings.searchPlaceholder = "Rechercher"
///     ContentView().syteTheme(theme)
public struct SyteTheme {

    public var accent: Color = .accentColor
    public var background: Color = Color(.systemBackground)
    public var imageBackground: Color = Color(.secondarySystemBackground)
    public var primaryText: Color = .primary
    public var secondaryText: Color = .secondary
    public var salePrice: Color = .red

    public var titleFont: Font = .subheadline
    public var brandFont: Font = .caption.weight(.semibold)
    public var priceFont: Font = .subheadline.weight(.semibold)
    public var headerFont: Font = .headline

    public var cornerRadius: CGFloat = 10
    public var spacing: CGFloat = 12
    
    /// Space between the screen edge and the content.
    public var edgeInset: CGFloat = 16

    /// Product image width divided by height. Fashion catalogs are usually 3:4.
    public var imageAspectRatio: CGFloat = 3.0 / 4.0

    /// Card width in carousels.
    public var carouselCardWidth: CGFloat = 148

    /// Smallest card width in grids. Grids fit as many columns as this allows.
    public var gridMinimumCardWidth: CGFloat = 150

    public var strings = SyteUIStrings()

    public init() {}

}

/// Every piece of text the kit shows, in English by default.
public struct SyteUIStrings {

    public var searchPlaceholder = "Search"
    public var popularSearches = "Popular searches"
    public var recentSearches = "Recent searches"
    /// `%@` is the query.
    public var noResults = "No results for “%@”"
    /// `%d` is the number of results.
    public var resultCount = "%d results"
    public var tryAgain = "Try again"
    public var somethingWentWrong = "Something went wrong."

    public var visualSearchTitle = "Search with a photo"
    public var visualSearchHint = "Take or choose a photo and we'll find products like the ones in it."
    public var takePhoto = "Take photo"
    public var choosePhoto = "Choose photo"
    public var newPhoto = "New photo"
    public var findingItems = "Finding items…"
    public var nothingFound = "We couldn't find any products in this photo."

    public init() {}

}

private struct SyteThemeKey: EnvironmentKey {
    static let defaultValue = SyteTheme()
}

extension EnvironmentValues {

    public var syteTheme: SyteTheme {
        get { self[SyteThemeKey.self] }
        set { self[SyteThemeKey.self] = newValue }
    }

}

extension View {

    /// Styles every Syte view inside this one.
    public func syteTheme(_ theme: SyteTheme) -> some View {
        environment(\.syteTheme, theme)
    }

}
