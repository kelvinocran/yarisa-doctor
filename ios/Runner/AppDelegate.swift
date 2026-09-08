import Flutter
import UIKit
import PushKit
import ObjectiveC
import flutter_callkit_incoming

@main
@objc class AppDelegate: FlutterAppDelegate, PKPushRegistryDelegate {
  private var voipRegistry: PKPushRegistry?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    #if targetEnvironment(simulator)
    Self.disableJitsiPluginOnSimulator()
    #endif
    GeneratedPluginRegistrant.register(with: self)

    // Register for VoIP pushes so CallKit can ring when the app is killed.
    #if !targetEnvironment(simulator)
    let registry = PKPushRegistry(queue: DispatchQueue.main)
    registry.delegate = self
    registry.desiredPushTypes = [.voIP]
    voipRegistry = registry
    #endif

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // MARK: - PKPushRegistryDelegate

  public func pushRegistry(
    _ registry: PKPushRegistry,
    didUpdate pushCredentials: PKPushCredentials,
    for type: PKPushType
  ) {
    let token = pushCredentials.token.map { String(format: "%02x", $0) }.joined()
    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP(token)
    UserDefaults.standard.set(token, forKey: "yarisa_voip_token")
  }

  public func pushRegistry(
    _ registry: PKPushRegistry,
    didInvalidatePushTokenFor type: PKPushType
  ) {
    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP("")
    UserDefaults.standard.removeObject(forKey: "yarisa_voip_token")
  }

  public func pushRegistry(
    _ registry: PKPushRegistry,
    didReceiveIncomingPushWith payload: PKPushPayload,
    for type: PKPushType,
    completion: @escaping () -> Void
  ) {
    guard type == .voIP else {
      completion()
      return
    }

    let dict = payload.dictionaryPayload
    let id = (dict["id"] as? String)
      ?? (dict["callId"] as? String)
      ?? UUID().uuidString
    let nameCaller = (dict["nameCaller"] as? String)
      ?? (dict["peerName"] as? String)
      ?? (dict["senderName"] as? String)
      ?? (dict["patientName"] as? String)
      ?? "Patient"
    let handle = (dict["handle"] as? String) ?? nameCaller
    let callType = ((dict["callType"] as? String) ?? (dict["extra_type"] as? String) ?? "voice")
      .lowercased()
    let isVideo = (dict["isVideo"] as? Bool) ?? (callType == "video")

    let data = flutter_callkit_incoming.Data(
      id: id,
      nameCaller: nameCaller,
      handle: handle,
      type: isVideo ? 1 : 0
    )
    data.extra = dict

    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.showCallkitIncoming(
      data,
      fromPushKit: true
    ) {
      completion()
    }
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
