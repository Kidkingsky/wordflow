import ActivityKit

// Keep this shared definition identical in the Runner and WidgetKit extension.
struct WordFlowLiveWord: Codable, Hashable {
    let english: String
    let chinese: String
    let partOfSpeech: String
}

struct WordFlowLiveAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var words: [WordFlowLiveWord]
        var level: String
    }

    var category: String
}
