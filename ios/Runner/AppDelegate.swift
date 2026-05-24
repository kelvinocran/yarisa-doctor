import Flutter
import UIKit
import ObjectiveC

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    #if targetEnvironment(simulator)
    Self.disableJitsiPluginOnSimulator()
    #endif
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  #if targetEnvironment(simulator)
  private static func disableJitsiPluginOnSimulator() {
    guard let cls = NSClassFromString("JitsiMeetPlugin") else { return }
    let sel = NSSelectorFromString("registerWithRegistrar:")
    guard let original = class_getClassMethod(cls, sel) else { return }
    let block: @convention(block) (AnyObject, AnyObject) -> Void = { _, _ in
      NSLog("[AppDelegate] Skipping JitsiMeetPlugin registration on iOS Simulator.")
    }
    let imp = imp_implementationWithBlock(block)
    method_setImplementation(original, imp)
  }
  #endif
}
