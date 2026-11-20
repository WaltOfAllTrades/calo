import Foundation
import Testing

/// The fixed values and must-dos that live in the app bundle (CLAUDE.md → Fixed values,
/// architecture §6). Hosted in the app so `Bundle.main` is the real one.
struct InfoPlistTests {
    private var info: [String: Any] {
        Bundle.main.infoDictionary ?? [:]
    }

    @Test("the bundle ID is the fixed one")
    func bundleId() {
        #expect(Bundle.main.bundleIdentifier == "com.waltofalltrades.calo")
    }

    @Test("portrait only, iPhone only, no multiple scenes")
    func orientationAndScenes() {
        let orientations = info["UISupportedInterfaceOrientations"] as? [String]
        #expect(orientations == ["UIInterfaceOrientationPortrait"])
        let manifest = info["UIApplicationSceneManifest"] as? [String: Any]
        #expect(manifest?["UIApplicationSupportsMultipleScenes"] as? Bool == false)
    }

    @Test("the privacy manifest ships with the UserDefaults reason")
    func privacyManifest() throws {
        let url = try #require(Bundle.main.url(forResource: "PrivacyInfo", withExtension: "xcprivacy"))
        let data = try Data(contentsOf: url)
        let plist = try #require(PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any])
        #expect(plist["NSPrivacyTracking"] as? Bool == false)
        let apis = try #require(plist["NSPrivacyAccessedAPITypes"] as? [[String: Any]])
        let types = apis.compactMap { $0["NSPrivacyAccessedAPIType"] as? String }
        #expect(types.contains("NSPrivacyAccessedAPICategoryUserDefaults"))
    }

    @Test("the strings catalog resolves the brand")
    func stringsCatalog() {
        #expect(String(localized: "calo.brand", bundle: .main) == "Calo")
    }
}
