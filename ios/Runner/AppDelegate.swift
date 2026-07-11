import Flutter
import UIKit
import StoreKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "com.daniel.isbn/app_transaction",
        binaryMessenger: controller.binaryMessenger)
      channel.setMethodCallHandler { call, result in
        guard call.method == "getOriginalAppVersion" else {
          result(FlutterMethodNotImplemented)
          return
        }
        // 付費時代老買家判斷用：回傳最初購買時的 build 版本（iOS 16+）
        if #available(iOS 16.0, *) {
          Task {
            do {
              let transaction = try await AppTransaction.shared
              switch transaction {
              case .verified(let appTransaction), .unverified(let appTransaction, _):
                result(appTransaction.originalAppVersion)
              }
            } catch {
              result(nil)
            }
          }
        } else {
          result(nil)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
