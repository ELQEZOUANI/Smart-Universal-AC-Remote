import 'package:acremote/app.dart';
import 'package:acremote/core/routing/app_router.dart';
import 'package:acremote/features/discovery/presentation/discovery_screen.dart';
import 'package:acremote/features/guide/presentation/connection_guide_screen.dart';
import 'package:acremote/features/home/presentation/home_screen.dart';
import 'package:acremote/features/remote/controllers/ac_controller.dart';
import 'package:acremote/features/remote/presentation/remote_screen.dart';
import 'package:acremote/features/timer/presentation/timer_screen.dart';
import 'package:acremote/models/ac_device.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('app opens with branded splash and advances to onboarding', (
    tester,
  ) async {
    appRouter.go('/splash');
    await tester.pumpWidget(
      const ProviderScope(child: SmartUniversalAcRemoteApp()),
    );

    expect(find.text('AC Remote: Repair & Diagnose'), findsOneWidget);
    expect(find.text('Remote Control & AC Diagnostic'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 4100));
    await tester.pumpAndSettle();
    expect(find.text('Control your climate'), findsOneWidget);
  });

  testWidgets('repair dashboard route is registered', (tester) async {
    appRouter.go('/repair');
    await tester.pumpWidget(
      const ProviderScope(child: SmartUniversalAcRemoteApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Online brand guides'), findsOneWidget);
    expect(find.text('Choose a brand'), findsOneWidget);
    expect(find.text('Repair'), findsOneWidget);
  });

  testWidgets('diagnosis back button returns to repair dashboard', (
    tester,
  ) async {
    appRouter.go('/repair/diagnosis');
    await tester.pumpWidget(
      const ProviderScope(child: SmartUniversalAcRemoteApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('What problem are you experiencing?'), findsOneWidget);
    expect(find.text('Repair'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back_rounded).first);
    await tester.pumpAndSettle();

    expect(find.text('Online brand guides'), findsOneWidget);
  });

  testWidgets('remote controls update temperature and power', (tester) async {
    await _setCompactPhone(tester);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(acControllerProvider.notifier);
    controller.addDevice(_bedroomDevice);
    await controller.unlockRemote();
    controller.togglePower();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: RemoteScreen()),
      ),
    );

    expect(find.text('22°'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Increase temperature'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('23°'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Turn AC off'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('OFF'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('remote stays locked before the rewarded entitlement', (
    tester,
  ) async {
    await _setCompactPhone(tester);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(acControllerProvider.notifier).addDevice(_bedroomDevice);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: RemoteScreen()),
      ),
    );

    expect(find.text('Your climate console is locked'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -420));
    await tester.pumpAndSettle();
    expect(find.text('Unlock remote'), findsOneWidget);
    expect(find.bySemanticsLabel('Increase temperature'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('discovery never adds fixture devices', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(acControllerProvider).devices, isEmpty);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: DiscoveryScreen()),
      ),
    );

    expect(find.text('Searching for nearby devices…'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 2300));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('No compatible devices found'), findsOneWidget);
    expect(find.text('Nothing found yet'), findsOneWidget);
    expect(container.read(acControllerProvider).devices, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('primary screens do not overflow at 320 logical pixels', (
    tester,
  ) async {
    await _setCompactPhone(tester);
    for (final entry in <(String, Widget)>[
      ('home', const HomeScreen()),
      ('connection guide', const ConnectionGuideScreen()),
      ('remote', const RemoteScreen()),
      ('timers', const TimerScreen()),
    ]) {
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: entry.$2)),
      );
      await tester.pump();
      expect(tester.takeException(), isNull, reason: '${entry.$1} overflowed');
    }
  });

  test(
    'controller clamps temperature and maintains device selection',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(acControllerProvider.notifier);

      controller
        ..addDevice(_bedroomDevice)
        ..addDevice(_livingRoomDevice);

      await controller.setTemperature(40);
      expect(container.read(acControllerProvider).control.temperature, 30);

      controller.selectDevice('living');
      expect(
        container.read(acControllerProvider).selectedDevice?.room,
        'Living Room',
      );
    },
  );

  test('remote unlock entitlement survives state serialization', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(acControllerProvider.notifier);

    await controller.unlockRemote();

    final state = container.read(acControllerProvider);
    expect(state.remoteUnlocked, isTrue);
    expect(ClimaAppState.fromJson(state.toJson()).remoteUnlocked, isTrue);
  });
}

const _bedroomDevice = AcDevice(
  id: 'bedroom',
  name: 'Bedroom AC',
  room: 'Bedroom',
  brand: 'LG',
  model: 'DualCool AI',
  ipAddress: '192.168.1.24',
  port: 8080,
  isOnline: true,
  roomTemperature: 25,
);

const _livingRoomDevice = AcDevice(
  id: 'living',
  name: 'Living Room AC',
  room: 'Living Room',
  brand: 'Samsung',
  model: 'WindFree',
  ipAddress: '192.168.1.35',
  port: 8080,
  isOnline: true,
  roomTemperature: 24,
);

Future<void> _setCompactPhone(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(320, 720);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}
