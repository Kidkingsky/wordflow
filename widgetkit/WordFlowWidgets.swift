import AppIntents
import SwiftUI
import WidgetKit

private struct LearningItem: Codable {
    let id: String
    let kind: String
    let category: String
    let level: String
    let english: String
    let chinese: String
    let note: String
    let example: String
    let exampleChinese: String

    static let placeholder = LearningItem(
        id: "preview", kind: "word", category: "daily", level: "A2",
        english: "balance", chinese: "平衡", note: "名詞／動詞",
        example: "Find a balance between work and life.",
        exampleChinese: "在工作與生活之間找到平衡。"
    )
}

private enum LessonKind: String {
    case word
    case phrase
    var label: String { self == .word ? "每日單字" : "每日實用詞句" }
}

enum WordFlowLevel: String, AppEnum, CaseIterable {
    case a2 = "A2"
    case b1 = "B1"
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "英文程度")
    }
    static var caseDisplayRepresentations: [WordFlowLevel: DisplayRepresentation] {
        [
            .a2: DisplayRepresentation(title: "A2 基礎"),
            .b1: DisplayRepresentation(title: "B1 進階")
        ]
    }
}

enum WordFlowTopic: String, AppEnum, CaseIterable {
    case all
    case travel
    case daily
    case fitness
    case work
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "學習主題")
    }
    static var caseDisplayRepresentations: [WordFlowTopic: DisplayRepresentation] {
        [
            .all: DisplayRepresentation(title: "全部"),
            .travel: DisplayRepresentation(title: "旅遊"),
            .daily: DisplayRepresentation(title: "生活"),
            .fitness: DisplayRepresentation(title: "健身"),
            .work: DisplayRepresentation(title: "工作")
        ]
    }
}

struct WordFlowWidgetSettings: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "WordFlow 單字設定"
    static var description = IntentDescription("選擇 Widget 的英文程度與主題。")

    @Parameter(title: "英文程度") var level: WordFlowLevel
    @Parameter(title: "主題") var topic: WordFlowTopic

    init() {
        level = .a2
        topic = .all
    }
}

private enum Vocabulary {
    static let all: [LearningItem] = {
        guard let url = Bundle.main.url(forResource: "content", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let items = try? JSONDecoder().decode([LearningItem].self, from: data)
        else { return [LearningItem.placeholder] }
        return items
    }()

    // Same local-date / UTC-day index and sorted-ID rotation as Flutter.
    static func pick(date: Date, kind: LessonKind, level: WordFlowLevel, topic: WordFlowTopic) -> LearningItem {
        let choices = all.filter {
            $0.kind == kind.rawValue && $0.level == level.rawValue &&
            (topic == .all || $0.category == topic.rawValue)
        }.sorted { $0.id < $1.id }
        guard !choices.isEmpty else { return .placeholder }

        let local = Calendar.current.dateComponents([.year, .month, .day], from: date)
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(secondsFromGMT: 0)!
        let epoch = utc.date(from: DateComponents(year: 2025, month: 1, day: 1))!
        let chosen = utc.date(from: DateComponents(year: local.year, month: local.month, day: local.day)) ?? epoch
        let day = utc.dateComponents([.day], from: epoch, to: chosen).day ?? 0
        let offset = kind == .phrase ? 7 : 0
        let index = ((day + offset) % choices.count + choices.count) % choices.count
        return choices[index]
    }
}

struct WordFlowEntry: TimelineEntry {
    let date: Date
    fileprivate let item: LearningItem
    fileprivate let kind: LessonKind
}

struct WordFlowProvider: AppIntentTimelineProvider {
    typealias Entry = WordFlowEntry
    typealias Intent = WordFlowWidgetSettings
    fileprivate let kind: LessonKind

    func placeholder(in context: Context) -> WordFlowEntry {
        WordFlowEntry(date: Date(), item: .placeholder, kind: kind)
    }

    func snapshot(for configuration: WordFlowWidgetSettings, in context: Context) async -> WordFlowEntry {
        makeEntry(date: Date(), configuration: configuration)
    }

    func timeline(for configuration: WordFlowWidgetSettings, in context: Context) async -> Timeline<WordFlowEntry> {
        let calendar = Calendar.current
        let firstDay = calendar.startOfDay(for: Date())
        let entries: [WordFlowEntry] = (0..<14).compactMap { day in
            guard let date = calendar.date(byAdding: .day, value: day, to: firstDay) else { return nil }
            return makeEntry(date: date, configuration: configuration)
        }
        return Timeline(entries: entries, policy: .atEnd)
    }

    private func makeEntry(date: Date, configuration: WordFlowWidgetSettings) -> WordFlowEntry {
        WordFlowEntry(
            date: date,
            item: Vocabulary.pick(date: date, kind: kind, level: configuration.level, topic: configuration.topic),
            kind: kind
        )
    }
}

private struct WordFlowWidgetView: View {
    let entry: WordFlowEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            switch family {
            case .accessoryInline:
                Text("\(entry.item.english) · \(entry.item.chinese)").lineLimit(1)
            case .accessoryCircular:
                VStack(spacing: 2) {
                    Image(systemName: "character.book.closed.fill").font(.system(size: 15))
                    Text(String(entry.item.english.prefix(9)))
                        .font(.system(size: 9, weight: .bold))
                        .minimumScaleFactor(0.6).lineLimit(1)
                }
            case .accessoryRectangular:
                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.item.english).font(.headline).minimumScaleFactor(0.75).lineLimit(1)
                    Text(entry.item.chinese).font(.caption).lineLimit(1)
                }.frame(maxWidth: .infinity, alignment: .leading)
            default:
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(entry.kind.label)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color(red: 0.08, green: 0.48, blue: 0.48))
                        Spacer(minLength: 4)
                        Text(entry.item.level).font(.system(size: 11, weight: .bold)).foregroundStyle(.secondary)
                    }
                    Text(entry.item.english)
                        .font(.system(size: family == .systemSmall ? 23 : 27, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 0.08, green: 0.15, blue: 0.21))
                        .lineLimit(2).minimumScaleFactor(0.6)
                    Text(entry.item.chinese)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color(red: 0.13, green: 0.36, blue: 0.38))
                        .lineLimit(2)
                    if family == .systemMedium {
                        Text(entry.item.example).font(.system(size: 12)).foregroundStyle(.secondary).lineLimit(2)
                    }
                    Spacer(minLength: 0)
                    Text("WORDFLOW · 每天一點英文")
                        .font(.system(size: 10, weight: .medium)).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(16)
            }
        }
        .containerBackground(for: .widget) {
            Color(red: 0.90, green: 0.96, blue: 0.94)
        }
        .widgetURL(URL(string: "wordflow:///"))
    }
}

struct WordFlowDailyWordWidget: Widget {
    let kind = "WordFlowDailyWord"
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind, intent: WordFlowWidgetSettings.self,
            provider: WordFlowProvider(kind: .word)
        ) { entry in WordFlowWidgetView(entry: entry) }
            .configurationDisplayName("WordFlow 每日單字")
            .description("每天更新英文單字與中文解釋。")
            .supportedFamilies([.systemSmall, .systemMedium, .accessoryInline, .accessoryCircular, .accessoryRectangular])
    }
}

struct WordFlowDailyPhraseWidget: Widget {
    let kind = "WordFlowDailyPhrase"
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind, intent: WordFlowWidgetSettings.self,
            provider: WordFlowProvider(kind: .phrase)
        ) { entry in WordFlowWidgetView(entry: entry) }
            .configurationDisplayName("WordFlow 每日詞句")
            .description("每天輪換實用英文句子。")
            .supportedFamilies([.systemSmall, .systemMedium, .accessoryInline, .accessoryRectangular])
    }
}

@main
struct WordFlowWidgets: WidgetBundle {
    var body: some Widget {
        WordFlowDailyWordWidget()
        WordFlowDailyPhraseWidget()
    }
}
