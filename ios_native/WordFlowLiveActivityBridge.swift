import ActivityKit
import Flutter
import UIKit

// Exposes opt-in, time-limited vocabulary study sessions through a Flutter MethodChannel.
// Must register during FlutterImplicitEngineDelegate initialization for Flutter 3.41+.
enum WordFlowLiveActivityBridge {
    private static let channelName = "com.kidkingsky.wordflow/lockscreen"

    static func register(messenger: FlutterBinaryMessenger) {
        let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
        channel.setMethodCallHandler { call, result in
            switch call.method {
            case "start":
                guard ActivityAuthorizationInfo().areActivitiesEnabled else {
                    result(FlutterError(
                        code: "LIVE_ACTIVITIES_DISABLED",
                        message: "請到 iPhone 設定允許 WordFlow 使用即時動態。",
                        details: nil
                    ))
                    return
                }
                guard let args = call.arguments as? [String: Any],
                      let rawWords = args["words"] as? [[String: Any]],
                      let level = args["level"] as? String,
                      let category = args["category"] as? String else {
                    result(FlutterError(code: "INVALID_WORDS", message: "無法讀取四個單字。", details: nil))
                    return
                }

                let words: [WordFlowLiveWord] = rawWords.compactMap { raw in
                    guard let en = raw["english"] as? String,
                          let zh = raw["chinese"] as? String,
                          !en.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                          !zh.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                        return nil
                    }
                    return WordFlowLiveWord(english: en, chinese: zh)
                }
                guard words.count == 4 else {
                    result(FlutterError(code: "INVALID_WORDS", message: "需要四個完整的中英單字。", details: nil))
                    return
                }

                Task { @MainActor in
                    // Only one WordFlow study session should appear on the Lock Screen.
                    for activity in Activity<WordFlowLiveAttributes>.activities {
                        await activity.end(nil, dismissalPolicy: .immediate)
                    }
                    do {
                        let attributes = WordFlowLiveAttributes(category: category)
                        let state = WordFlowLiveAttributes.ContentState(words: words, level: level)
                        let activity = try Activity<WordFlowLiveAttributes>.request(
                            attributes: attributes,
                            content: ActivityContent(state: state, staleDate: Date().addingTimeInterval(8 * 3600)),
                            pushType: nil
                        )
                        result(activity.id)
                    } catch {
                        result(FlutterError(
                            code: "LIVE_ACTIVITY_START_FAILED",
                            message: "無法啟動四格單字：\(error.localizedDescription)",
                            details: nil
                        ))
                    }
                }

            case "stop":
                Task { @MainActor in
                    for activity in Activity<WordFlowLiveAttributes>.activities {
                        await activity.end(nil, dismissalPolicy: .immediate)
                    }
                    result(nil)
                }

            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
}
