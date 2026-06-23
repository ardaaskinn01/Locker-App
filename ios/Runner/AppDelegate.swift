import Flutter
import UIKit
import SwiftUI

#if canImport(FamilyControls)
import FamilyControls
#endif

#if canImport(SwiftUI) && canImport(FamilyControls)
@available(iOS 16.0, *)
struct AppPickerView: View {
    @Binding var selection: FamilyActivitySelection
    var onDone: () -> Void
    var onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            FamilyActivityPicker(selection: $selection)
                .navigationTitle("Uygulama Seçin")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("İptal") {
                            onCancel()
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Tamam") {
                            onDone()
                        }
                    }
                }
        }
    }
}
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
                #if canImport(FamilyControls)
                if #available(iOS 16.0, *) {
                    let status = AuthorizationCenter.shared.authorizationStatus
                    result(status == .approved)
                } else {
                    result(false)
                }
                #else
                result(false)
                #endif
                
            case "checkAccessibilityAccess":
                // iOS does not have Android-style accessibility service for app locking.
                // Screen Time is the iOS equivalent. Return based on auth status.
                #if canImport(FamilyControls)
                if #available(iOS 16.0, *) {
                    let status = AuthorizationCenter.shared.authorizationStatus
                    result(status == .approved)
                } else {
                    result(false)
                }
                #else
                result(false)
                #endif
                
            case "openUsageStatsSettings", "openAccessibilitySettings", "openAppSettings":
                // On iOS, open the Settings app for Screen Time / Permissions
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
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
                // This call is a no-op on iOS (managed via Screen Time shields).
                result(nil)
                
            case "getAppUsageToday":
                // iOS does not allow querying per-app usage via API without DeviceActivity reports.
                result(0)
                
            case "selectAppsIOS":
                #if canImport(FamilyControls)
                if #available(iOS 16.0, *) {
                    DispatchQueue.main.async {
                        let pickerVC = UIHostingController(rootView: AppPickerView(
                            selection: Binding(
                                get: { AppLockService.shared.selectionToShield },
                                set: { AppLockService.shared.selectionToShield = $0 }
                            ),
                            onDone: {
                                controller.dismiss(animated: true, completion: nil)
                                result(AppLockService.shared.selectionToShield.applicationTokens.count + AppLockService.shared.selectionToShield.categoryTokens.count)
                            },
                            onCancel: {
                                controller.dismiss(animated: true, completion: nil)
                                result(0)
                            }
                        ))
                        controller.present(pickerVC, animated: true, completion: nil)
                    }
                } else {
                    result(0)
                }
                #else
                result(0)
                #endif
                
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
