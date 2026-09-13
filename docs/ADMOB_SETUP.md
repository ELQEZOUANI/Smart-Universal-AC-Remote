# AdMob Full-Screen Ad Setup

The App Open, navigation interstitial, and one-time remote-unlock Rewarded Ad
integrations are enabled only on iOS. Android contains no AdMob App ID or ad
unit configuration. No Google test App IDs or test ad units are configured.

## Before enabling production ads

1. Confirm the iOS app in AdMob uses bundle ID `com.ac.fad`.
2. The production iOS AdMob App ID is stored as `GADApplicationIdentifier` in
   `ios/Runner/Info.plist`.
3. Create iOS App Open, Interstitial, and Rewarded ad units.
4. Paste those three unit IDs into `AdMobConfig` near the top of
   `lib/core/ads/app_open_ad_service.dart`.
5. In AdMob **Privacy & messaging**, publish the consent messages required for
   the regions where AC Remote: Repair & Diagnose is distributed.
6. Publish and verify `app-ads.txt` on the developer website.
7. Update the public privacy policy and store data disclosures to match the
   final AdMob and mediation configuration.

An AdMob **App ID** contains a tilde (`~`). An **ad unit ID** contains a slash
(`/`). Do not place an ad unit ID in the Android manifest or iOS plist.

## Add the iOS production ad units

Paste each iOS ad unit ID between the matching quotes:

```dart
static const iosAppOpenAdUnitId = '';
static const iosInterstitialAdUnitId = '';
static const iosRewardedAdUnitId = '';
```

An empty or malformed value disables that placement in every build. The
Rewarded unit is mandatory for a usable release because the remote cannot be
unlocked without completing that placement.

The iOS release build validates the native AdMob App ID and all three unit IDs.
Android release builds validate upload signing but contain no advertising
configuration.

## Current behavior

- Consent information is refreshed on every launch.
- Ads load only after the consent SDK reports that requests are allowed.
- Cold-start ads wait for and display over the existing AC Remote: Repair & Diagnose splash
  screen, then navigation continues after dismissal.
- A failed, unavailable, or slow ad request is skipped after six seconds.
- Cold-start ads are attempted on every app launch.
- Ads are frequency-capped to one presentation every 15 minutes.
- Loaded ads expire after four hours and are discarded.
- Interstitials are requested only when the user enters Settings through the
  bottom navigation bar. Home, Remote, and Devices never trigger them.
- Release interstitials observe a two-minute gap from any full-screen ad.
- Re-tapping an already-selected Settings tab never shows an ad, and the
  placement never waits for a late load.
- The first remote connection or direct remote opening presents a clear,
  optional Rewarded Ad prompt. The remote unlock is stored only after the SDK
  reports that the reward was earned.
- The remote entitlement is permanent for that app installation. Cancelling,
  closing early, no-fill, timeout, and presentation errors do not unlock it.
- The Settings privacy-choice entry appears whenever the consent SDK requires
  an ongoing privacy options entry point.

Always validate consent and every ad placement on a physical iOS device before
App Store submission.
