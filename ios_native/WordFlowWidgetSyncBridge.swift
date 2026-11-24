import Flutter
import Foundation
import WidgetKit

/// Finds the App Group this build can actually open.
///
/// SideStore / AltStore re-sign the app with the user's own team, which
/// rewrites the App Group ID (for example
/// `group.com.kidkingsky.wordflow.ABCDE12345`). A hard-coded
/// `group.com.kidkingsky.wordflow` then silently fails in the app, the widget
/// or both. The rewritten IDs are published in the `ALTAppGroups` Info.plist
/// key, and the bundle ID gets the same suffix, so try those first.
enum WordFlowAppGroup {
    static let baseID = "group.com.kidkingsky.wordflow"

    static var candidates: [String] {
        var ids: [String] = []
        if let alt = Bundle.main.object(forInfoDictionaryKey: "ALTAppGroups") as? [String] {
            ids.append(contentsOf: alt)
        }
        if var bundleID = Bundle.main.bundleIdentifier {
            // The widget extension is "<app id>.WordFlowWidgets".
            if Bundle.main.bundleURL.pathExtension == "appex",
               let dot = bundleID.lastIndex(of: ".") {
                bundleID = String(bundleID[..<dot])
            }
            ids.append("group.\(bundleID)")
        }
        ids.append(baseID)
        var seen = Set<String>()
        return ids.filter { seen.insert($0).inserted }
    }

    static func resolve() -> String? {
        candidates.first {
            FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: $0) != nil
        }
    }
}

/// SideStore / WidgetKit App Groups experiment.
/// A successful Flutter call proves only that the host app can access the
/// group. The widget must independently read the same selection on device.
enum WordFlowWidgetSyncBridge {
    private static let channelName = "com.kidkingsky.wordflow/widgetsync"
    private static let selectedKey = "wordflow.sync.selectedWordId"
    private static let revisionKey = "wordflow.sync.revision"

    static func register(messenger: FlutterBinaryMessenger) {
        let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
        channel.setMethodCallHandler { call, result in
            guard let groupID = WordFlowAppGroup.resolve(),
                  let defaults = UserDefaults(suiteName: groupID) else {
                result([
                    "available": false,
                    "reason": "App Groups 共用容器無法存取（試過：\(WordFlowAppGroup.candidates.joined(separator: "、"))）。請確認簽署工具有保留 App Groups 權限。"
                ] as [String: Any])
                return
            }
            switch call.method {
            case "status":
                result(response(defaults: defaults, groupID: groupID))
            case "setWord":
                guard let arguments = call.arguments as? [String: Any],
                      let selected = arguments["wordId"] as? String,
                      !selected.isEmpty else {
                    result(FlutterError(code: "INVALID_WORD",
                                        message: "沒有有效的單字 ID。", details: nil))
                    return
                }
                let revision = defaults.integer(forKey: revisionKey) + 1
                defaults.set(selected, forKey: selectedKey)
                defaults.set(revision, forKey: revisionKey)
                guard defaults.string(forKey: selectedKey) == selected else {
                    result(FlutterError(code: "APP_GROUP_WRITE_FAILED",
                                        message: "App 無法讀回剛寫入的單字。", details: nil))
                    return
                }
                WidgetCenter.shared.reloadAllTimelines()
                result(response(defaults: defaults, groupID: groupID))
            case "clear":
                defaults.removeObject(forKey: selectedKey)
                defaults.set(defaults.integer(forKey: revisionKey) + 1,
                             forKey: revisionKey)
                WidgetCenter.shared.reloadAllTimelines()
                result(response(defaults: defaults, groupID: groupID))
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    private static func response(defaults: UserDefaults, groupID: String) -> [String: Any] {
        var data: [String: Any] = [
            "available": true,
            "groupId": groupID,
            "revision": defaults.integer(forKey: revisionKey)
        ]
        if let wordId = defaults.string(forKey: selectedKey) {
            data["wordId"] = wordId
        }
        return data
    }
}
