# Changelog

## 3.0.0

Refresh of the 2021 SDK for current Xcode and the current Syte API.

### Breaking

- Minimum iOS is now 15.
- Shopper and session IDs are stored in a dedicated `com.syte.sdk` defaults suite instead of the keychain. Apps upgrading from 2.x get a new shopper ID once.

### Fixed

- Adding the package by version in Xcode failed because one dependency was pinned to a branch. That dependency is gone.
- The shopper ID was wiped on every app launch, which reset personalization and broke purchase attribution. Startup also deleted every keychain password the host app had stored under its own bundle ID, which is the default for that keychain library and many others. Startup no longer clears anything.
- Purchase, checkout and add-to-cart events now send their data inside `rawData`, as Syte's event API requires. Before, purchases were not counted.
- Text search filters were sent as malformed JSON, which made the API fail with a 500.
- Autocomplete and popular searches returned an error when there were simply no results. They now return an empty result.
- Platform settings failed to load because one settings field changed shape on the server.
- Search hits now include their `sku`.

### Changed

- Calls go to `cdn-api.syteapi.com`, the host in Syte's current API docs.
- Visual search, recommendation and event calls also send the API key in the `x-api-key` header, as the docs describe. Text search keeps the `sig` parameter, since those endpoints reject the header.
- Dropped the SwiftKeychainWrapper and SwiftLint dependencies, and the ReactiveSwift and RxSwift builds pulled in through Moya.
- Clean build on Swift 6 toolchains with no warnings.
- Added offline tests, and live tests that run against a real account when credentials are provided.
