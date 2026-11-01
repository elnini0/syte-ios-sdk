# Syte iOS SDK

Client for Syte's product discovery API: visual search, similar items, Shop the Look, personalized recommendations, text search and event tracking. The `iOS-SDK` library returns data for your own screens. The optional `SyteUI` library adds ready-made SwiftUI screens on top of it, see [UI kit](#ui-kit).

See [CHANGELOG.md](CHANGELOG.md) for what changed in 3.0.

## Requirements

- iOS 15 or later
- Xcode 15 or later (tested on Xcode 27.2)

## Installation

### Swift Package Manager

In Xcode, File > Add Package Dependencies, then enter:

```
https://github.com/elnini0/syte-ios-sdk.git
```

and pick "Up to Next Major Version" from 3.0.0. In a `Package.swift`:

```swift
.package(url: "https://github.com/elnini0/syte-ios-sdk.git", from: "3.0.0")
```

### CocoaPods

```ruby
pod 'Syte', :git => 'https://github.com/elnini0/syte-ios-sdk.git', :tag => '3.0.0'
```

## UI kit

`SyteUI` is a second library in the same package: SwiftUI views that call Syte, show the results, and send Syte's events on their own. Add it to your target next to `iOS-SDK`. iOS 15 or later, Swift Package Manager only.

- `SyteProductCarousel` is a titled row of similar items, Shop the Look, personalized picks, frequently bought together, recently viewed or a merchandising collection. It shows placeholder cards while loading and hides itself when there's nothing to show.
- `SyteVisualSearchView` asks for a photo (camera or library), marks the items Syte finds, and shows results for the one the shopper taps. Started with an image URL, it searches that image right away, for a "find similar" button on a product page.
- `SyteSearchView` has a search box with recent and popular searches, suggestions while typing, and a results grid that loads more as the shopper scrolls.
- The pieces they're built from are public too: `SyteProductCard`, `SyteProductGrid`, `SyteProductImage`, `SytePriceView`.

Create the service once and hand it to the views through the environment:

```swift
import SwiftUI
import SyteUI
import iOS_SDK

@main
struct ShopApp: App {
    let syte = SyteLiveService(syte: Syte(configuration: SyteConfiguration(accountId: "<account id>", signature: "<api key>"))!)

    var body: some Scene {
        WindowGroup {
            ContentView().syteService(syte)
        }
    }
}
```

Then drop the views where they belong. Each takes a closure for when the shopper picks a product:

```swift
SyteProductCarousel(.similar(sku: product.sku, imageURL: product.imageURL), title: "You may also like") { picked in
    router.openProduct(picked.sku)
}

SyteVisualSearchView { picked in router.openProduct(picked.sku) }

SyteSearchView { picked in router.openProduct(picked.sku) }
```

Pass your own card to any carousel or grid to match your product tiles:

```swift
SyteProductCarousel(.boughtTogether(skus: cart.skus), title: "Complete your order") { picked in
    cart.add(picked.sku)
} card: { product in
    MyProductTile(product)
}
```

Colors, fonts, sizes and every piece of text come from a theme:

```swift
var theme = SyteTheme()
theme.accent = .brown
theme.cornerRadius = 4
theme.strings.searchPlaceholder = "Rechercher"
ContentView().syteTheme(theme)
```

Taking photos needs `NSCameraUsageDescription` in your Info.plist. Choosing from the library needs no permission.

### Events the views send

- Similar items and Shop the Look rows: when the row is shown, and each product click.
- Photo search: camera button shown and tapped, items found, item tapped, results shown, result clicked. Clicks carry the product the search started from and the link clicked, when known.
- Search: when results are shown, with whether the query was typed, a recent search or a popular one.

Personalized, bought together, recently viewed and collection rows send nothing, and neither do clicks on search results: Syte documents no events for them. Page views, add to cart and purchases stay your app's job, as in the [events section](#data-collection).

### Previews and tests

`SytePreviewService` returns made-up products with no network calls and keeps every event it's sent, for SwiftUI previews and unit tests. Products, search box and item markers carry the accessibility identifiers `syte.product`, `syte.carousel.product`, `syte.search.field` and `syte.marker` for UI tests.

### Demo app

`Demo/SyteDemo.xcodeproj` is a small shop built from the kit: search, product pages with all three recommendation rows, photo search and a "For you" tab. It runs on made-up products. To use your catalog, add `SYTE_ACCOUNT_ID`, `SYTE_API_KEY` and optionally `SYTE_LOCALE` under Edit Scheme > Run > Arguments > Environment Variables. Don't commit the scheme with them.

The demo's UI test walks through every screen and keeps a screenshot of each step in the test results. Pass the same variables with a `TEST_RUNNER_` prefix to run it on your account.

## Running the tests

Offline tests run as is. Live tests call the real API and are skipped unless you pass an account:

```
TEST_RUNNER_SYTE_ACCOUNT_ID=<account id> TEST_RUNNER_SYTE_API_KEY=<api key> \
  xcodebuild test -scheme iOS-SDK-Package -destination 'platform=iOS Simulator,name=iPhone 18 Pro'
```

Recently viewed, collection and gallery live tests also need `TEST_RUNNER_SYTE_TEST_DISCOVERY=1`, and `TEST_RUNNER_SYTE_TEST_COLLECTION_ID` / `TEST_RUNNER_SYTE_TEST_GALLERY_ID` for the last two.

Optional: `TEST_RUNNER_SYTE_TEST_QUERY` and `TEST_RUNNER_SYTE_TEST_LANG` (defaults `robe` and `fr_FR`) pick a search term that returns products for your account.

## Account Credentials

In order to use this SDK, please contact Syte for your account ID and API key. The `signature` parameter below is your API key.     

## Use the SDK

# Initialization

To start using the Syte SDK, instantiate the SyteConfiguration object and pass your API credentials to its constructor. 
Your credentials can be found in Syte’s Platform - Settings - API Keys.
Then use the created instance to set the locale.
```swift  
let configuration = SyteConfiguration(accountId: <account_id>, signature: <api_signature>)
configuration.locale = <locale>
```

Then you'll need to initialize Syte class passing the configuration instance :

```swift  
var syte: Syte? = Syte(configuration: configuration)
```

API used: https://cdn.syteapi.com/accounts/[account_id]

To retrieve the instance of SytePlatformSettings use the syte.getSytePlatformSettings() method.

For get recent searches:
```swift
syte.getRecentTextSearches()
```

For set viewed product:
```swift
syte.addViewedProduct(sku: <String>)
```

Get all viewed items:
```swift
syte.getViewedProducts()
```

## Image Search

Object detection ("bounds") and a similarity search ("Items") per object detected in the image. 
Search can be performed with an image or image URL.

To use the image Search functionality do the following:

1. Create dedicated class instance and pass the required data.

For Url image search:
```swift  
let imageSearchRequestData = UrlImageSearch(imageUrl: <image url>, productType: <SyteProductType>)
```
For image search:
```swift  
let imageSearchRequestData = ImageSearch(image: <UIImage>)
```
2. Retrieve bounds:

For Url image search:
```swift  
syte.getBoundsForImageUrl(requestData: <UrlImageSearch>) { [weak self] result in
// Handle response, result type is SyteResult<BoundsResult> 
}
```
For image search:
```swift  
syte.getBoundsForImage(requestData: <ImageSearch>) { [weak self] result in
// Handle response, result type is SyteResult<BoundsResult> 
}
```
3. Retrieve Items for a bound:
```swift  
syte.getItemsForBound(bound: Bound, cropCoordinates: CropCoordinates) { result in
// Handle response
}
```

You can pass CropCoordinates instance instead of *nil* here to enable the crop functionality. Example:
```swift  
let coordinates = CropCoordinates(x1: 0.2, y1: 0.2, x2: 0.8, y2: 0.8) // The coordinates should be relative ranging from 0.0 to 1.0
syte.getItemsForBound(bound: <Bound>, cropCoordinates: coordinates) { result in
// Handle response, result type is SyteResult<ItemsResult> 
}
```

**NOTE**
Items for the first bound will be retrieved by default.
Use 
```swift
urlImageSearch.retrieveOffersForTheFirstBound = false
```
or
```swift
imageSearch.retrieveOffersForTheFirstBound = false
```
to disable this behaviour.
To get the items for the first bound use the 
```swift 
BoundsResult.firstBoundItemsResult
``` 
variable.

# Product Recommendations
To use the "Recommendations" functionality, do the following:

1. Use Syte class instance to get results for different features:

*   `getSimilarProducts(similarProducts: SimilarProducts, completion: @escaping (SyteResult<SimilarProductsResult>) -> Void)`
*   `getShopTheLook(shopTheLook: ShopTheLook, completion: @escaping (SyteResult<ShopTheLookResult>) -> Void)`
*   `getPersonalization(personalization: Personalization, completion: @escaping (SyteResult<PersonalizationResult>) -> Void)`
*   `getBoughtTogether(boughtTogether: BoughtTogether, completion: @escaping (SyteResult<PersonalizationResult>) -> Void)`

"Frequently bought together" takes the SKUs in the shopper's cart, or the product they're looking at:
```swift
syte.getBoughtTogether(boughtTogether: BoughtTogether(skus: ["ABC123"])) { result in
// Handle response, result type is SyteResult<PersonalizationResult>
}
```

**NOTE:** You must add at least one product ID to use the "Personalization" functionality. To do this use the 
```swift
Syte.addViewedProduct(String)
``` 
method.

# Recently viewed, collections and galleries

These calls read data Syte keeps on its side, and need the features enabled on your account. They have not been tested against a live account yet: the test account available while building them answers 403.

Recently viewed products for this SDK's shopper ID, most recent first:
```swift
syte.getRecentlyViewed { result in
// Handle response, result type is SyteResult<RecentlyViewedResult>
}
syte.removeRecentlyViewed(sku: "ABC123") { result in }
syte.mergeRecentlyViewed(fromUserId: "<another shopper ID>") { result in }
```
Syte builds this list from the shopper's activity; check with Syte which events feed it in an app.

A merchandising collection's products, a page at a time:
```swift
let collection = MerchandisingCollection(id: "<collection id>")
collection.size = 12
syte.getCollection(collection: collection) { result in
// Handle response, result type is SyteResult<CollectionResult>
}
```

A shoppable gallery, with the products tagged on each image:
```swift
syte.getShoppableGallery(gallery: ShoppableGallery(id: "<gallery id>")) { result in
// Handle response, result type is SyteResult<ShoppableGalleryResult>
}
```

Products from these calls come back as `SyteProduct`, with common fields typed and everything else in `fields`. Ask for other product fields with the request's `fields` property.

# Personalized ranking

Enabling the personalized ranking will attach the list of viewed products to the requests. 
To add a product to the list of viewed ones use the
```swift
Syte.addViewedProduct(String)
```
method.
To enable this functionality use the 
```swift
personalizedRanking = true
```
variable. 
It is supported in the following classes: 
```swift
UrlImageSearch, ImageSearch, ShopTheLook, SimilarProducts
```
Personalized ranking is disabled by default.

# Data Collection

The SDK can be used to fire various events to Syte. Example:
```swift  
syte.fire(event: EventCheckoutStart(price: 62.94, currency: "EUR", productList: products, pageName: "checkout"))
```
# Text Search

The SDK can be used for the Text Search functionality.

There are 3 main features:

1. Popular Searches. Will retrieve the list of the most popular searches.
```swift  
syte.getPopularSearches(lang: String, completion: @escaping (SyteResult<[String]>) -> Void)
```
2. Text search. Will retrieve the results for the specified query.
```swift  
syte.getTextSearch(textSearch: TextSearch, completion: @escaping (SyteResult<TextSearchResult>) -> Void)
```
To retrieve a list of recent text searches use syte.getRecentTextSearches() method.

3. Auto-complete. Text auto-completion functionality.
```swift  
syte.getAutoCompleteForTextSearch("query", "en_US") { [weak self] result in
// Handle response, result type is SyteResult<AutoCompleteResult>
}
```

# Platform settings
To retrieve the Syte Platform Settings use:
```swift  
syte.getPlatformSettings(completion: @escaping (SyteResult<SytePlatformSettings>) -> Void)
```     

## Author

Originally written by Artur Tarasenko (Clover Dynamics) for Syte. Maintained in this fork since 2026.

## License

Syte is available under the MIT license. See the LICENSE file for more info.
