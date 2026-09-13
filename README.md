# AC Remote: Repair & Diagnose

AC Remote: Repair & Diagnose is a polished Flutter application for remote control, repair guidance, and AC diagnostics.

## Product features

- First-run onboarding that is shown once
- Automatic discovery and manual IP connection flows
- Responsive climate remote with temperature, modes, fan, swing, and comfort functions
- Device management and schedules
- Persistent devices, controls, timers, theme, unit, and preference state
- Light and dark themes
- Phone and tablet layouts
- Branded Android, iOS, and web launch assets
- Consent-gated AdMob App Open, navigation interstitial, and Rewarded Ads on Android and iOS
- One-time rewarded remote unlock that persists across launches

## Run locally

```bash
flutter pub get
flutter run
```

## Verify

```bash
flutter analyze
flutter test
flutter build appbundle --release
flutter build ipa --release
```

Android upload signing is loaded from `android/key.properties`. Copy `android/key.properties.example`, use a securely stored upload keystore, and never commit either the completed properties file or the keystore.

## Release identity

- App name: AC Remote: Repair & Diagnose
- Android application ID: `com.ac.fad`
- iOS bundle ID: `com.ac.fad`
- Version: `1.0.0+1`

See [STORE_SUBMISSION.md](docs/STORE_SUBMISSION.md) before distributing a production build.
See [ADMOB_SETUP.md](docs/ADMOB_SETUP.md) before enabling production ads.

## Integration boundary

The repository currently contains the local product experience and an `AcRepository` boundary. Vendor-specific AC discovery and command protocols must be connected through that interface and validated on physical hardware before the app can claim control support for a model.
