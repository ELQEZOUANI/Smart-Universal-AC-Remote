import AppTrackingTransparency
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var trackingChannel: FlutterMethodChannel?
  private var trackingActivationObserver: NSObjectProtocol?
  private var pendingTrackingResult: FlutterResult?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let channel = FlutterMethodChannel(
      name: "com.ac.fad/tracking_transparency",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "requestAuthorizationIfNeeded" else {
        result(FlutterMethodNotImplemented)
        return
      }
      DispatchQueue.main.async {
        self?.requestTrackingAuthorizationIfNeeded(result: result)
      }
    }
    trackingChannel = channel
  }

  private func requestTrackingAuthorizationIfNeeded(result: @escaping FlutterResult) {
    guard #available(iOS 14.0, *) else {
      result("unavailable")
      return
    }

    let status = ATTrackingManager.trackingAuthorizationStatus
    guard status == .notDetermined else {
      result(trackingStatusName(status))
      return
    }

    guard UIApplication.shared.applicationState == .active else {
      guard pendingTrackingResult == nil else {
        result(
          FlutterError(
            code: "request_in_progress",
            message: "An ATT authorization request is already waiting for the app to become active.",
            details: nil
          )
        )
        return
      }
      pendingTrackingResult = result
      trackingActivationObserver = NotificationCenter.default.addObserver(
        forName: UIApplication.didBecomeActiveNotification,
        object: nil,
        queue: .main
      ) { [weak self] _ in
        self?.requestPendingTrackingAuthorization()
      }
      return
    }

    performTrackingAuthorizationRequest(result: result)
  }

  @available(iOS 14.0, *)
  private func requestPendingTrackingAuthorization() {
    guard let result = pendingTrackingResult else { return }
    pendingTrackingResult = nil
    removeTrackingActivationObserver()
    performTrackingAuthorizationRequest(result: result)
  }

  @available(iOS 14.0, *)
  private func performTrackingAuthorizationRequest(result: @escaping FlutterResult) {
    ATTrackingManager.requestTrackingAuthorization { [weak self] status in
      DispatchQueue.main.async {
        guard let self else {
          result("unknown")
          return
        }
        result(self.trackingStatusName(status))
      }
    }
  }

  @available(iOS 14.0, *)
  private func trackingStatusName(
    _ status: ATTrackingManager.AuthorizationStatus
  ) -> String {
    switch status {
    case .notDetermined:
      return "notDetermined"
    case .restricted:
      return "restricted"
    case .denied:
      return "denied"
    case .authorized:
      return "authorized"
    @unknown default:
      return "unknown"
    }
  }

  private func removeTrackingActivationObserver() {
    if let observer = trackingActivationObserver {
      NotificationCenter.default.removeObserver(observer)
      trackingActivationObserver = nil
    }
  }

  deinit {
    removeTrackingActivationObserver()
  }
}
