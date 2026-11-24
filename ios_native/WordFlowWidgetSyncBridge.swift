import Flutter
import Foundation
import WidgetKit

/// SideStore / WidgetKit App Groups experiment.
/// A successful Flutter call proves only that the host app can access the
/// group. The widget must independently read the same selection on device.
enum WordFlowWidgetSyncBridge {
    private static let channelName = "com.kidkingsky.wordflow/widgetsync"
    private static let groupID = "group.com.kidkingsky.wordflow"
    private static let selectedKey = "wordflow.sync.selectedWordId"
    private static let revisionKey = "wordflow.sync.revision"

    static func register(messenger: FlutterBinaryMessenger) {
        let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
        channel.setMethodCallHandler { call, result in
            guard FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: groupID
            ) != nil, let defaults = UserDefaults(suiteName: groupID) else {
                result([
                    "available": false,
                    "reason": "App Groups 共用容器無法存取。請檢查 SideStore 是否保留簽署權限。"
                ] as [String: Any])
                return
            }
            switch call.method {
            case "status":
                result(response(defaults: defaults))
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
                WidgetCenter.shared.reloadTimelines(ofKind: "WordFlowDailyWord")
                result(response(defaults: defaults))
            case "clear":
                defaults.removeObject(forKey: selectedKey)
                defaults.set(defaults.integer(forKey: revisionKey) + 1,
                             forKey: revisionKey)
                WidgetCenter.shared.reloadTimelines(ofKind: "WordFlowDailyWord")
                result(response(defaults: defaults))
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    private static func response(defaults: UserDefaults) -> [String: Any] {
        var data: [String: Any] = [
            "available": true,
            "revision": defaults.integer(forKey: revisionKey)
        ]
        if let wordId = defaults.string(forKey: selectedKey) {
            data["wordId"] = wordId
        }
        return data
    }
}
