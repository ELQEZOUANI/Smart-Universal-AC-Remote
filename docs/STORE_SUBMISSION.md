# AC Remote: Repair & Diagnose Store Submission Checklist

## Completed in the project

- [x] Production app name and version metadata
- [x] Android application ID and iOS bundle ID changed from `com.example`
- [x] Branded launcher icons for Android, iOS, and web
- [x] Branded native launch screens
- [x] Android local-network permissions
- [x] iOS local-network usage description
- [x] iOS App Tracking Transparency usage description and authorization flow
- [x] iOS non-exempt encryption declaration for standard network transport
- [x] Persistent onboarding, settings, devices, controls, and timers
- [x] Release builds have no seeded sample devices or schedules
- [x] Empty, loading, validation, offline, and disabled UI states
- [x] Privacy policy and terms drafts
- [x] Published privacy policy URL: <https://smartuniversalacremote.blogspot.com/2026/08/blog-post.html>
- [x] Consent-gated, iOS-only App Open, Interstitial, and Rewarded Ad infrastructure
- [x] One-time rewarded remote entitlement persists after the reward callback
- [x] Fixture devices and simulated discovery results removed from all build modes
- [x] Android release builds fail closed when upload signing is missing
- [x] iOS release builds fail closed when the production AdMob App ID is missing
- [x] Current Flutter configuration targets Android API 36
- [x] iOS builds use Xcode 26 and the iOS 26 SDK toolchain
- [x] Analyzer and widget-test coverage for compact layouts and controls

## Required owner actions before upload

- [ ] Confirm ownership and availability of `com.ac.fad` in both stores
- [ ] Confirm that `fadma01x@gmail.com` and the public terms URL are live
- [ ] Verify the published [privacy policy](https://smartuniversalacremote.blogspot.com/2026/08/blog-post.html) matches the final app and AdMob configuration
- [ ] Replace `LocalAcRepository` with tested vendor/network protocol adapters
- [ ] Validate every advertised device model on physical hardware and real routers
- [ ] Create the Android upload keystore and complete `android/key.properties`
- [ ] Install the Android toolchain (JDK and SDK/API 36) and validate the signed AAB
- [ ] Confirm the Apple team, certificates, App ID, and provisioning profile in Xcode
- [ ] Set final version/build numbers for the release
- [ ] Capture current phone and tablet screenshots
- [ ] Complete App Privacy and Google Play Data safety disclosures
- [ ] Provide production iOS App Open, Interstitial, and Rewarded ad unit IDs
- [ ] Test the rewarded unlock through completion, early dismissal, no-fill, and reinstall on physical devices
- [ ] Create and publish the required AdMob privacy messages for supported regions
- [ ] Test the ATT prompt on a fresh physical-device install and complete the App Store tracking disclosures
- [ ] Publish and verify `app-ads.txt` for the developer website
- [ ] Declare that the iOS app contains ads and review the App Store age rating
- [ ] Provide store descriptions, keywords, support URL, privacy URL, and age rating
- [ ] Test signed release builds through TestFlight and Play internal testing

See [ADMOB_SETUP.md](ADMOB_SETUP.md) before creating an ad-enabled build. Do not submit a build that uses Google sample ad identifiers, debug signing, or advertises unverified device compatibility.

Submission baseline checked August 29, 2026: Apple requires Xcode 26 with the
iOS 26 SDK, and Google Play requires new mobile apps and updates to target API
36 from August 31, 2026. Recheck the official [Apple requirements](https://developer.apple.com/news/upcoming-requirements/)
and [Google Play target API policy](https://support.google.com/googleplay/android-developer/answer/11926878?hl=en)
immediately before upload.
