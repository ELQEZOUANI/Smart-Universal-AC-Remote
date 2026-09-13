import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Requests Apple's App Tracking Transparency authorization on iOS.
///
/// The native implementation only presents the system prompt while the status
/// is undetermined. All other platforms treat the request as unavailable.
abstract final class TrackingTransparencyService {
  static const _channel = MethodChannel('com.ac.fad/tracking_transparency');

  static Future<void> requestAuthorizationIfNeeded() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;

    try {
      final status = await _channel.invokeMethod<String>(
        'requestAuthorizationIfNeeded',
      );
      if (kDebugMode) debugPrint('[ATT] Authorization status: $status');
    } on MissingPluginException {
      if (kDebugMode) debugPrint('[ATT] Native channel is unavailable.');
    } on PlatformException catch (error) {
      if (kDebugMode) {
        debugPrint('[ATT] Authorization request failed: ${error.message}');
      }
    }
  }
}
