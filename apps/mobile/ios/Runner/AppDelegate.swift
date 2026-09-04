import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let dartDefinesString = Bundle.main.infoDictionary?["DART_DEFINES"] as? String ?? ""
    var mapsApiKey = ""
    for definedValue in dartDefinesString.components(separatedBy: ",") {
        if let decodedData = Data(base64Encoded: definedValue),
           let decodedString = String(data: decodedData, encoding: .utf8),
           decodedString.hasPrefix("GOOGLE_MAPS_API_KEY=") {
            mapsApiKey = String(decodedString.dropFirst("GOOGLE_MAPS_API_KEY=".count))
        }
    }
    
    GMSServices.provideAPIKey(mapsApiKey)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
