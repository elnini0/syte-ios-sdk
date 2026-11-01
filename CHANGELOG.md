# Changelog

## 3.0.0

Refresh of the 2021 SDK for current Xcode and the current Syte API.

### Added

- Frequently bought together recommendations.
- Recently viewed products (get, remove, merge histories), merchandising collections and shoppable galleries. Built from Syte's API docs and not yet tested against a live account.
- Photo search uploads the photo straight to item detection in one call, as Syte's current docs describe, replacing the separate image upload service. Photo searches are reported as camera searches.
- `SyteUI`, an optional SwiftUI library in the same package: product carousels, photo search and text search screens that send Syte's events on their own, with a theme and replaceable product cards. See the README.
- A demo app built from `SyteUI`, with a UI test that walks through every screen.
- Visual search results and click events can carry the result SKUs, the product the search started from, the detected item's index and the link clicked, as Syte's event docs describe.
- Detection results include the link to the searched image. For photos that's Syte's stored copy, so visual search events from photos have an image link too.

### Breaking

- Minimum iOS is now 15.
- Shopper and session IDs are stored in a dedicated `com.syte.sdk` defaults suite instead of the keychain. Apps upgrading from 2.x get a new shopper ID once.

### Fixed

- Adding the package by version in Xcode failed because one dependency was pinned to a branch. That dependency is gone.
- The shopper ID was wiped on every app launch, which reset personalization and broke purchase attribution. Startup also deleted every keychain password the host app had stored under its own bundle ID, which is the default for that keychain library and many others. Startup no longer clears anything.
- Purchase, checkout and add-to-cart events now send their data inside `rawData`, as Syte's event API requires. Before, purchases were not counted.
- Text search filters were sent as malformed JSON, which made the API fail with a 500.
- Photos were stretched to a fixed size before upload (a portrait photo became a square), which distorted what Syte saw and enlarged small photos. They're now shrunk with their proportions kept and never enlarged.
- Autocomplete and popular searches returned an error when there were simply no results. They now return an empty result.
- Platform settings failed to load because one settings field changed shape on the server.
- Search hits now include their `sku`.
- Personalization sent SKUs as unquoted JSON, so any SKU with letters (most retailers' SKUs) got a 400 from the API.

### Changed

- Calls go to `cdn-api.syteapi.com`, the host in Syte's current API docs.
- Visual search, recommendation and event calls also send the API key in the `x-api-key` header, as the docs describe. Text search keeps the `sig` parameter, since those endpoints reject the header.
- Dropped the SwiftKeychainWrapper and SwiftLint dependencies, and the ReactiveSwift and RxSwift builds pulled in through Moya.
- Clean build on Swift 6 toolchains with no warnings.
- Removed the 2021 CocoaPods example app, which no longer built.
- Added offline tests, and live tests that run against a real account when credentials are provided.
