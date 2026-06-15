import Flutter
import UIKit

#if canImport(FamilyControls)
import FamilyControls
#endif

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let lockChannel = FlutterMethodChannel(name: "com.lockapp/lock", binaryMessenger: controller.binaryMessenger)
    
    lockChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
        if #available(iOS 15.0, *) {
            switch call.method {
            case "requestScreenTimePermission":
                #if canImport(FamilyControls)
                AppLockService.shared.requestAuthorization { granted in
                    result(granted)
                }
                #else
                result(false)
                #endif
                
            case "checkUsageAccess":
                // iOS uses Screen Time API, not usage stats. Check authorization status.
                if #available(iOS 16.0, *) {
                    let status = AuthorizationCenter.shared.authorizationStatus
                    result(status == .approved)
                } else {
                    result(false)
                }
                
            case "checkAccessibilityAccess":
                // iOS does not have Android-style accessibility service for app locking.
                // Screen Time is the iOS equivalent. Return based on auth status.
                if #available(iOS 16.0, *) {
                    let status = AuthorizationCenter.shared.authorizationStatus
                    result(status == .approved)
                } else {
                    result(false)
                }
                
            case "openUsageStatsSettings", "openAccessibilitySettings":
                // On iOS, open the Settings app for Screen Time
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
                result(nil)
                
            case "setLimitStatus":
                if let args = call.arguments as? [String: Any],
                   let isLimitReached = args["isLimitReached"] as? Bool {
                    AppLockService.shared.setShieldedApps(isLimitReached: isLimitReached)
                    result(nil)
                } else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Arguments missing", details: nil))
                }
                
            case "setLockedApps":
                // iOS uses FamilyActivityPicker tokens, not package names.
                // The locked apps must be selected via the FamilyActivityPicker UI.
                // This call is a no-op on iOS (managed via Screen Time shields).
                result(nil)
                
            case "getAppUsageToday":
                // iOS does not allow querying per-app usage via API without DeviceActivity reports.
                // Return 0 as a safe default; iOS usage sync is handled differently.
                result(0)
                
            default:
                result(FlutterMethodNotImplemented)
            }
        } else {
            result(FlutterError(code: "UNSUPPORTED_OS", message: "iOS 15 or higher is required", details: nil))
        }
    })

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
