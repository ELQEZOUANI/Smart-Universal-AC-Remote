import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/ads/app_open_ad_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const AdMobAppLifecycle(
      child: ProviderScope(child: SmartUniversalAcRemoteApp()),
    ),
  );
}
