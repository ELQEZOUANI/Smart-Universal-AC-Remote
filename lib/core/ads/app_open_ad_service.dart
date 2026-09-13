import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../privacy/tracking_transparency_service.dart';

/// AdMob identifiers and platform guards for full-screen ads.
///
/// Advertising is intentionally enabled only on iOS. Paste the three iOS
/// production ad unit IDs below; an empty or malformed value disables that
/// placement in every build mode.
abstract final class AdMobConfig {
  // Paste the iOS App Open ad unit ID between the quotes.
  static const iosAppOpenAdUnitId = 'ca-app-pub-2535194044471316/1984411297';

  // Paste the iOS Interstitial ad unit ID between the quotes.
  static const iosInterstitialAdUnitId = 'ca-app-pub-2535194044471316/6989325967';

  // Paste the iOS Rewarded ad unit ID between the quotes.
  static const iosRewardedAdUnitId = 'ca-app-pub-2535194044471316/3660455043';

  static bool get isSupportedPlatform =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static String? get appOpenAdUnitId =>
      isSupportedPlatform ? _validUnitId(iosAppOpenAdUnitId) : null;

  static String? get interstitialAdUnitId =>
      isSupportedPlatform ? _validUnitId(iosInterstitialAdUnitId) : null;

  static String? get rewardedAdUnitId =>
      isSupportedPlatform ? _validUnitId(iosRewardedAdUnitId) : null;

  static String? _validUnitId(String value) {
    final id = value.trim();
    return RegExp(r'^ca-app-pub-\d+/\d+$').hasMatch(id) ? id : null;
  }
}

/// Owns consent, loading, frequency controls, and full-screen ad presentation
/// for the app's App Open, navigation interstitial, and Rewarded Ads.
class AppOpenAdService {
  AppOpenAdService._();

  static final instance = AppOpenAdService._();

  static const _maximumCacheAge = Duration(hours: 4);
  static const _minimumInterval = Duration(minutes: 15);
  static const _interstitialMinimumInterval = Duration(minutes: 2);

  final privacyOptionsRequired = ValueNotifier<bool>(false);

  Future<void>? _initialization;
  StreamSubscription<AppState>? _appStateSubscription;
  Completer<bool>? _loadCompleter;
  Completer<bool>? _rewardedLoadCompleter;
  AppOpenAd? _appOpenAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  DateTime? _loadedAt;
  DateTime? _lastFullScreenShownAt;
  var _canRequestAds = false;
  var _foregroundAdsEnabled = false;
  var _isLoading = false;
  var _isShowing = false;
  var _isInterstitialLoading = false;
  var _isInterstitialShowing = false;
  var _isRewardedLoading = false;
  var _isRewardedShowing = false;

  Future<void> initialize() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    if (!AdMobConfig.isSupportedPlatform ||
        (AdMobConfig.appOpenAdUnitId == null &&
            AdMobConfig.interstitialAdUnitId == null &&
            AdMobConfig.rewardedAdUnitId == null)) {
      _log('Ads are not configured for this build.');
      return;
    }

    try {
      await MobileAds.instance.initialize();
      await _gatherConsent();
      await AppStateEventNotifier.startListening();
      _appStateSubscription = AppStateEventNotifier.appStateStream.listen(
        (state) {
          if (state == AppState.foreground) {
            unawaited(_handleForeground());
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          _log('App state listener failed: $error');
        },
      );
    } catch (error, stackTrace) {
      _log('Initialization failed: $error');
      _logStack(stackTrace);
    }
  }

  /// Allows foreground ads only after onboarding has completed.
  void enableForegroundAds() {
    _foregroundAdsEnabled = true;
  }

  Future<void> _gatherConsent() async {
    final update = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () => unawaited(_showRequiredConsentForm(update)),
      (error) {
        _log('Consent update failed (${error.errorCode}): ${error.message}');
        if (!update.isCompleted) update.complete();
      },
    );
    await update.future;

    await _refreshPrivacyOptionsRequirement();
    await TrackingTransparencyService.requestAuthorizationIfNeeded();
    _canRequestAds = await ConsentInformation.instance.canRequestAds();
    if (_canRequestAds) {
      unawaited(_loadAd());
      _loadInterstitialAd();
      unawaited(_loadRewardedAd());
    }
  }

  Future<void> _showRequiredConsentForm(Completer<void> update) async {
    try {
      await ConsentForm.loadAndShowConsentFormIfRequired((error) {
        if (error != null) {
          _log('Consent form failed (${error.errorCode}): ${error.message}');
        }
      });
    } catch (error, stackTrace) {
      _log('Consent form failed: $error');
      _logStack(stackTrace);
    } finally {
      if (!update.isCompleted) update.complete();
    }
  }

  Future<void> _refreshPrivacyOptionsRequirement() async {
    try {
      final status = await ConsentInformation.instance
          .getPrivacyOptionsRequirementStatus();
      privacyOptionsRequired.value =
          status == PrivacyOptionsRequirementStatus.required;
    } catch (error) {
      _log('Could not read privacy options status: $error');
    }
  }

  Future<void> showPrivacyOptions() async {
    if (!AdMobConfig.isSupportedPlatform) return;

    try {
      await ConsentForm.showPrivacyOptionsForm((error) {
        if (error != null) {
          _log('Privacy options failed (${error.errorCode}): ${error.message}');
        }
      });
      await _refreshPrivacyOptionsRequirement();
      _canRequestAds = await ConsentInformation.instance.canRequestAds();
      if (_canRequestAds) {
        unawaited(_loadAd());
        _loadInterstitialAd();
        unawaited(_loadRewardedAd());
      }
    } catch (error, stackTrace) {
      _log('Privacy options failed: $error');
      _logStack(stackTrace);
    }
  }

  Future<void> _handleForeground() async {
    if (!_foregroundAdsEnabled ||
        !_canRequestAds ||
        _isShowing ||
        _isInterstitialShowing ||
        _isRewardedShowing) {
      return;
    }
    if (_appOpenAd == null) {
      unawaited(_loadAd());
      return;
    }
    await showIfAvailable();
  }

  Future<bool> _loadAd() {
    final adUnitId = AdMobConfig.appOpenAdUnitId;
    if (_hasFreshAd) return Future<bool>.value(true);
    if (_isLoading && _loadCompleter != null) {
      return _loadCompleter!.future;
    }
    if (adUnitId == null || !_canRequestAds || _appOpenAd != null) {
      return Future<bool>.value(false);
    }

    final loadResult = Completer<bool>();
    _loadCompleter = loadResult;
    _isLoading = true;
    unawaited(_requestAd(adUnitId: adUnitId, loadResult: loadResult));
    return loadResult.future;
  }

  Future<void> _requestAd({
    required String adUnitId,
    required Completer<bool> loadResult,
  }) async {
    void complete(bool loaded) {
      _isLoading = false;
      if (identical(_loadCompleter, loadResult)) _loadCompleter = null;
      if (!loadResult.isCompleted) loadResult.complete(loaded);
    }

    try {
      await AppOpenAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            _appOpenAd = ad;
            _loadedAt = DateTime.now();
            _log('App open ad loaded.');
            complete(true);
          },
          onAdFailedToLoad: (error) {
            _log('App open ad failed to load: $error');
            complete(false);
          },
        ),
      );
    } catch (error, stackTrace) {
      _log('App open ad request failed: $error');
      _logStack(stackTrace);
      complete(false);
    }
  }

  bool get _hasFreshAd {
    final loadedAt = _loadedAt;
    if (_appOpenAd == null || loadedAt == null) return false;
    return DateTime.now().difference(loadedAt) < _maximumCacheAge;
  }

  bool get _isOutsideFrequencyCap {
    final lastShownAt = _lastFullScreenShownAt;
    return lastShownAt == null ||
        DateTime.now().difference(lastShownAt) >= _minimumInterval;
  }

  bool get _isInterstitialOutsideFrequencyCap {
    final lastShownAt = _lastFullScreenShownAt;
    return lastShownAt == null ||
        DateTime.now().difference(lastShownAt) >= _interstitialMinimumInterval;
  }

  /// Waits briefly for the launch ad, shows it over the splash screen, and
  /// completes after dismissal. A timeout or no-fill never blocks navigation.
  Future<bool> showAfterSplash({
    Duration maximumWait = const Duration(seconds: 6),
  }) async {
    final initialization = _initialization;
    if (initialization == null) return false;

    final startedAt = DateTime.now();
    try {
      await initialization.timeout(maximumWait);
      if (!_canRequestAds) {
        _log('Launch ad skipped because consent does not allow ad requests.');
        return false;
      }

      final elapsed = DateTime.now().difference(startedAt);
      final remaining = maximumWait - elapsed;
      if (remaining <= Duration.zero) return false;

      final loaded = _hasFreshAd || await _loadAd().timeout(remaining);
      if (!loaded) return false;
      return showIfAvailable(respectFrequencyCap: false);
    } on TimeoutException {
      _log('Launch ad timed out; continuing into the app.');
      return false;
    } catch (error, stackTrace) {
      _log('Launch ad flow failed: $error');
      _logStack(stackTrace);
      return false;
    }
  }

  /// Shows a preloaded ad and completes after it is dismissed.
  Future<bool> showIfAvailable({bool respectFrequencyCap = true}) async {
    if (!_canRequestAds ||
        _isShowing ||
        _isInterstitialShowing ||
        _isRewardedShowing ||
        !_hasFreshAd ||
        (respectFrequencyCap && !_isOutsideFrequencyCap)) {
      if (_appOpenAd != null && !_hasFreshAd) {
        await _disposeLoadedAd();
        unawaited(_loadAd());
      }
      return false;
    }

    final ad = _appOpenAd!;
    final result = Completer<bool>();
    _appOpenAd = null;
    _loadedAt = null;
    _isShowing = true;

    void finish(bool shown) {
      _isShowing = false;
      unawaited(ad.dispose());
      if (!result.isCompleted) result.complete(shown);
      unawaited(_loadAd());
    }

    ad.fullScreenContentCallback = FullScreenContentCallback<AppOpenAd>(
      onAdShowedFullScreenContent: (_) {
        _lastFullScreenShownAt = DateTime.now();
        _log('App open ad shown.');
      },
      onAdDismissedFullScreenContent: (_) => finish(true),
      onAdFailedToShowFullScreenContent: (_, error) {
        _log('App open ad failed to show: $error');
        finish(false);
      },
    );

    try {
      await ad.show();
    } catch (error, stackTrace) {
      _log('App open ad show call failed: $error');
      _logStack(stackTrace);
      finish(false);
    }
    return result.future;
  }

  void _loadInterstitialAd() {
    final adUnitId = AdMobConfig.interstitialAdUnitId;
    if (adUnitId == null ||
        !_canRequestAds ||
        _isInterstitialLoading ||
        _interstitialAd != null) {
      return;
    }

    _isInterstitialLoading = true;
    unawaited(_requestInterstitialAd(adUnitId));
  }

  Future<void> _requestInterstitialAd(String adUnitId) async {
    try {
      await InterstitialAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _isInterstitialLoading = false;
            _interstitialAd = ad;
            _log('Interstitial ad loaded.');
          },
          onAdFailedToLoad: (error) {
            _isInterstitialLoading = false;
            _log('Interstitial ad failed to load: $error');
          },
        ),
      );
    } catch (error, stackTrace) {
      _isInterstitialLoading = false;
      _log('Interstitial ad request failed: $error');
      _logStack(stackTrace);
    }
  }

  /// Shows a preloaded interstitial before a user opens a major destination.
  ///
  /// Release builds observe a two-minute gap from any full-screen ad. Test
  /// builds show the preloaded test ad immediately. It never waits for a late
  /// load, so navigation is never held up by an ad request.
  Future<bool> showInterstitialForNavigation() async {
    final frequencyAllowsPresentation =
        !kReleaseMode || _isInterstitialOutsideFrequencyCap;
    if (!frequencyAllowsPresentation ||
        !_canRequestAds ||
        _isShowing ||
        _isInterstitialShowing ||
        _isRewardedShowing) {
      return false;
    }

    final ad = _interstitialAd;
    if (ad == null) {
      _loadInterstitialAd();
      return false;
    }

    final result = Completer<bool>();
    _interstitialAd = null;
    _isInterstitialShowing = true;

    void finish(bool shown) {
      _isInterstitialShowing = false;
      unawaited(ad.dispose());
      if (!result.isCompleted) result.complete(shown);
      _loadInterstitialAd();
    }

    ad.fullScreenContentCallback = FullScreenContentCallback<InterstitialAd>(
      onAdShowedFullScreenContent: (_) {
        _lastFullScreenShownAt = DateTime.now();
        _log('Interstitial ad shown.');
      },
      onAdDismissedFullScreenContent: (_) => finish(true),
      onAdFailedToShowFullScreenContent: (_, error) {
        _log('Interstitial ad failed to show: $error');
        finish(false);
      },
    );

    try {
      await ad.show();
    } catch (error, stackTrace) {
      _log('Interstitial ad show call failed: $error');
      _logStack(stackTrace);
      finish(false);
    }
    return result.future;
  }

  /// Kept as a semantic entry point for the Settings navigation call site.
  Future<bool> showInterstitialForSettingsEntry() =>
      showInterstitialForNavigation();

  Future<bool> _loadRewardedAd() {
    final adUnitId = AdMobConfig.rewardedAdUnitId;
    if (_rewardedAd != null) return Future<bool>.value(true);
    if (_isRewardedLoading && _rewardedLoadCompleter != null) {
      return _rewardedLoadCompleter!.future;
    }
    if (adUnitId == null || !_canRequestAds) {
      return Future<bool>.value(false);
    }

    final loadResult = Completer<bool>();
    _rewardedLoadCompleter = loadResult;
    _isRewardedLoading = true;
    unawaited(_requestRewardedAd(adUnitId: adUnitId, loadResult: loadResult));
    return loadResult.future;
  }

  Future<void> _requestRewardedAd({
    required String adUnitId,
    required Completer<bool> loadResult,
  }) async {
    void complete(bool loaded) {
      _isRewardedLoading = false;
      if (identical(_rewardedLoadCompleter, loadResult)) {
        _rewardedLoadCompleter = null;
      }
      if (!loadResult.isCompleted) loadResult.complete(loaded);
    }

    try {
      await RewardedAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd = ad;
            _log('Rewarded ad loaded.');
            complete(true);
          },
          onAdFailedToLoad: (error) {
            _log('Rewarded ad failed to load: $error');
            complete(false);
          },
        ),
      );
    } catch (error, stackTrace) {
      _log('Rewarded ad request failed: $error');
      _logStack(stackTrace);
      complete(false);
    }
  }

  /// Presents the one-time remote-unlock reward after explicit user consent.
  ///
  /// The result is true only when the SDK invokes [onUserEarnedReward]. A
  /// dismissal, timeout, unavailable ad, or presentation failure never grants
  /// access.
  Future<bool> showRewardedRemoteUnlock({
    required Future<void> Function() onRewardEarned,
    Duration maximumWait = const Duration(seconds: 6),
  }) async {
    final initialization = _initialization ?? initialize();
    final startedAt = DateTime.now();
    try {
      await initialization.timeout(maximumWait);
      if (!_canRequestAds ||
          _isShowing ||
          _isInterstitialShowing ||
          _isRewardedShowing) {
        return false;
      }

      final elapsed = DateTime.now().difference(startedAt);
      final remaining = maximumWait - elapsed;
      if (remaining <= Duration.zero) return false;
      final loaded =
          _rewardedAd != null || await _loadRewardedAd().timeout(remaining);
      if (!loaded || _rewardedAd == null) return false;

      final ad = _rewardedAd!;
      final result = Completer<bool>();
      _rewardedAd = null;
      _isRewardedShowing = true;
      var rewardEarned = false;
      var finished = false;
      Future<void>? rewardDelivery;

      Future<void> finish() async {
        if (finished) return;
        finished = true;
        _isRewardedShowing = false;
        unawaited(ad.dispose());
        var rewardDelivered = false;
        if (rewardEarned) {
          try {
            await rewardDelivery;
            rewardDelivered = true;
          } catch (error, stackTrace) {
            _log('Remote unlock persistence failed: $error');
            _logStack(stackTrace);
          }
        }
        if (!result.isCompleted) {
          result.complete(rewardDelivered);
        }
        unawaited(_loadRewardedAd());
      }

      ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
        onAdShowedFullScreenContent: (_) {
          _lastFullScreenShownAt = DateTime.now();
          _log('Rewarded ad shown.');
        },
        onAdDismissedFullScreenContent: (_) => unawaited(finish()),
        onAdFailedToShowFullScreenContent: (_, error) {
          _log('Rewarded ad failed to show: $error');
          unawaited(finish());
        },
      );

      try {
        await ad.show(
          onUserEarnedReward: (_, reward) {
            if (rewardEarned) return;
            rewardEarned = true;
            rewardDelivery = Future<void>.sync(onRewardEarned);
            _log(
              'Remote unlock reward earned (${reward.amount} ${reward.type}).',
            );
          },
        );
      } catch (error, stackTrace) {
        _log('Rewarded ad show call failed: $error');
        _logStack(stackTrace);
        unawaited(finish());
      }
      return result.future;
    } on TimeoutException {
      _log('Rewarded ad timed out; remote remains locked.');
      return false;
    } catch (error, stackTrace) {
      _log('Rewarded unlock flow failed: $error');
      _logStack(stackTrace);
      return false;
    }
  }

  Future<void> _disposeLoadedAd() async {
    final ad = _appOpenAd;
    _appOpenAd = null;
    _loadedAt = null;
    if (ad != null) await ad.dispose();
  }

  Future<void> dispose() async {
    final subscription = _appStateSubscription;
    _appStateSubscription = null;
    await subscription?.cancel();
    if (AdMobConfig.isSupportedPlatform) {
      try {
        await AppStateEventNotifier.stopListening();
      } catch (error) {
        _log('Could not stop the app state listener: $error');
      }
    }
    await _disposeLoadedAd();
    final interstitialAd = _interstitialAd;
    _interstitialAd = null;
    _isInterstitialLoading = false;
    _isInterstitialShowing = false;
    if (interstitialAd != null) await interstitialAd.dispose();
    final rewardedAd = _rewardedAd;
    _rewardedAd = null;
    _isRewardedLoading = false;
    _isRewardedShowing = false;
    if (rewardedAd != null) await rewardedAd.dispose();
    final loadCompleter = _loadCompleter;
    _loadCompleter = null;
    _isLoading = false;
    if (loadCompleter != null && !loadCompleter.isCompleted) {
      loadCompleter.complete(false);
    }
    final rewardedLoadCompleter = _rewardedLoadCompleter;
    _rewardedLoadCompleter = null;
    if (rewardedLoadCompleter != null && !rewardedLoadCompleter.isCompleted) {
      rewardedLoadCompleter.complete(false);
    }
    _initialization = null;
    _canRequestAds = false;
    _foregroundAdsEnabled = false;
  }

  void _log(String message) {
    if (kDebugMode) debugPrint('[AdMob] $message');
  }

  void _logStack(StackTrace stackTrace) {
    if (kDebugMode) debugPrintStack(stackTrace: stackTrace);
  }
}

/// Initializes the ads service only in real app launches. Widget tests that
/// pump [SmartUniversalAcRemoteApp] directly remain isolated from platform
/// channels.
class AdMobAppLifecycle extends StatefulWidget {
  const AdMobAppLifecycle({required this.child, super.key});

  final Widget child;

  @override
  State<AdMobAppLifecycle> createState() => _AdMobAppLifecycleState();
}

class _AdMobAppLifecycleState extends State<AdMobAppLifecycle> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(AppOpenAdService.instance.initialize());
    });
  }

  @override
  void dispose() {
    unawaited(AppOpenAdService.instance.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
