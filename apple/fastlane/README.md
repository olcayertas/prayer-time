fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Archive NamazVaktiiOS (Release), export for App Store Connect, upload to TestFlight (internal), wait for processing.

Options: build_number:<n> (default: latest TestFlight build number + 1). Does NOT submit for review.

Run it from `apple/` on a clean checkout of `main`:

1. Run `bundle config set --local path vendor/bundle`, then `bundle install` (first time only).
2. Set `ASC_KEY_ID` and `ASC_KEY_PATH` (absolute path to the `.p8`, outside the repo or gitignored).
3. Keep the issuer ID in the login keychain as service `ASC_ISSUER_ID`. The Fastfile reads it when `ASC_ISSUER_ID` is not set.
4. Sign in to Xcode with the Account Holder account. Signing uses that account (automatic signing), not the API key.

### ios metadata

```sh
[bundle exec] fastlane ios metadata
```

Push App Store listing metadata + screenshots (no binary; the build comes from the beta lane). Does NOT submit.

### ios clear_screenshots

```sh
[bundle exec] fastlane ios clear_screenshots
```

Delete ALL screenshots on the editable version (both locales) — used to clear duplicate uploads.

### ios dedupe_screenshots

```sh
[bundle exec] fastlane ios dedupe_screenshots
```

Delete duplicate screenshots (deliver double-uploads 1320x2868 into APP_IPHONE_67); keep one per file name.

### ios inspect

```sh
[bundle exec] fastlane ios inspect
```

Diagnostic: print the app's primary locale + each version's localizations (what's actually on App Store Connect).

----


## Mac

### mac metadata

```sh
[bundle exec] fastlane mac metadata
```

Push App Store metadata + screenshots for Namaz Vakti for Mac (no binary; the build comes from Xcode Cloud). Does NOT submit.

### mac inspect

```sh
[bundle exec] fastlane mac inspect
```

Diagnostic: the macOS app's locales + screenshot counts per set.

### mac dedupe_screenshots

```sh
[bundle exec] fastlane mac dedupe_screenshots
```

Delete duplicate macOS screenshots (deliver double-uploads); keep one per file name.

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
