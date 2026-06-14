import Flutter
import UIKit

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
            if call.method == "requestScreenTimePermission" {
                AppLockService.shared.requestAuthorization { granted in
                    result(granted)
                }
            } else if call.method == "setLimitStatus" {
                if let args = call.arguments as? [String: Any],
                   let isLimitReached = args["isLimitReached"] as? Bool {
                    AppLockService.shared.setShieldedApps(isLimitReached: isLimitReached)
                    result(nil)
                } else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Arguments missing", details: nil))
                }
            } else {
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
