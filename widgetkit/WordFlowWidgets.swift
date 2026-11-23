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

    var partOfSpeech: String? {
        guard kind == "word" else { return nil }
        let label = note.components(separatedBy: "｜").first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return label.isEmpty ? nil : label
    }

    var labeledMeaning: String {
        guard let partOfSpeech = partOfSpeech else { return chinese }
        return "\(partOfSpeech) · \(chinese)"
    }

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

private enum WordFlowPalette {
    static func gradient(for category: String) -> [Color] {
        switch category {
        case "travel":
            return [Color(red: 0.06, green: 0.54, blue: 0.70), Color(red: 0.05, green: 0.29, blue: 0.55)]
        case "fitness":
            return [Color(red: 0.98, green: 0.42, blue: 0.38), Color(red: 0.72, green: 0.25, blue: 0.45)]
        case "work":
            return [Color(red: 0.26, green: 0.45, blue: 0.86), Color(red: 0.22, green: 0.26, blue: 0.58)]
        default:
            return [Color(red: 0.60, green: 0.38, blue: 0.89), Color(red: 0.35, green: 0.27, blue: 0.70)]
        }
    }

    static func name(for category: String) -> String {
        switch category {
        case "travel": return "旅遊"
        case "fitness": return "健身"
        case "work": return "工作"
        default: return "生活"
        }
    }

    static func symbol(for category: String) -> String {
        switch category {
        case "travel": return "airplane"
        case "fitness": return "figure.run"
        case "work": return "briefcase.fill"
        default: return "sparkles"
        }
    }
}

private struct WordFlowWidgetView: View {
    let entry: WordFlowEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            switch family {
            case .accessoryInline:
                Text("\(entry.item.english) · \(entry.item.chinese)")
                    .lineLimit(1)
            case .accessoryCircular:
                VStack(spacing: 2) {
                    Image(systemName: "character.book.closed.fill").font(.system(size: 14))
                    Text(String(entry.item.english.prefix(8)))
                        .font(.system(size: 9, weight: .bold))
                        .minimumScaleFactor(0.65)
                        .lineLimit(1)
                }
            case .accessoryRectangular:
                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.item.english)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .lineLimit(1).minimumScaleFactor(0.7)
                    Text(entry.item.labeledMeaning)
                        .font(.system(size: 12, weight: .medium))
                        .lineLimit(1)
                }.frame(maxWidth: .infinity, alignment: .leading)
            default:
                fullColorCard
            }
        }
        .containerBackground(for: .widget) {
            ZStack(alignment: .topTrailing) {
                LinearGradient(
                    colors: WordFlowPalette.gradient(for: entry.item.category),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Circle()
                    .fill(.white.opacity(0.09))
                    .frame(width: 190, height: 190)
                    .offset(x: 80, y: -90)
            }
        }
        .widgetURL(URL(string: "wordflow:///"))
    }

    private var fullColorCard: some View {
        let isSmall = family == .systemSmall
        let isLarge = family == .systemLarge

        return VStack(alignment: .leading, spacing: isSmall ? 7 : 10) {
            HStack(spacing: 8) {
                Image(systemName: WordFlowPalette.symbol(for: entry.item.category))
                    .font(.system(size: isSmall ? 12 : 15, weight: .bold))
                Text(entry.kind.label)
                    .font(.system(size: isSmall ? 11 : 13, weight: .heavy))
                Spacer(minLength: 2)
                Text(entry.item.level)
                    .font(.system(size: 11, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.white.opacity(0.20), in: Capsule())
            }
            .foregroundStyle(.white.opacity(0.95))

            Spacer(minLength: 0)

            Text(entry.item.english)
                .font(.system(size: isSmall ? 26 : (isLarge ? 39 : 34),
                              weight: .heavy, design: .rounded))
                .tracking(-0.6)
                .foregroundStyle(.white)
                .lineLimit(isSmall ? 2 : 3)
                .minimumScaleFactor(0.58)

            if let partOfSpeech = entry.item.partOfSpeech {
                Text(partOfSpeech)
                    .font(.system(size: isSmall ? 10 : 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.95))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(.white.opacity(0.19), in: Capsule())
            }

            Text(entry.item.chinese)
                .font(.system(size: isSmall ? 16 : (isLarge ? 22 : 19),
                              weight: .semibold))
                .foregroundStyle(.white.opacity(0.94))
                .lineLimit(isSmall ? 2 : 3)
                .minimumScaleFactor(0.78)

            if !isSmall {
                if !entry.item.example.isEmpty {
                    Text(entry.item.example)
                        .font(.system(size: isLarge ? 16 : 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.87))
                        .lineLimit(isLarge ? 3 : 2)
                } else {
                    Text("每天學一個，慢慢累積英文力")
                        .font(.system(size: isLarge ? 15 : 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.83))
                        .lineLimit(1)
                }

                if isLarge && !entry.item.exampleChinese.isEmpty {
                    Text(entry.item.exampleChinese)
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.78))
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 0)

            HStack {
                Text("WORDFLOW  ·  \(WordFlowPalette.name(for: entry.item.category))")
                    .font(.system(size: isSmall ? 9 : 11, weight: .bold))
                    .tracking(isSmall ? 0.5 : 1.1)
                    .foregroundStyle(.white.opacity(0.76))
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.76))
            }
        }
        .padding(isSmall ? 15 : (isLarge ? 25 : 20))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
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
            .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryInline, .accessoryCircular, .accessoryRectangular])
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
            .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryInline, .accessoryRectangular])
    }
}


private struct WordFlowStudyLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WordFlowLiveAttributes.self) { context in
            VStack(alignment: .leading, spacing: 9) {
                HStack(spacing: 5) {
                    Image(systemName: "sparkles")
                    Text("WORDFLOW  ·  鎖定畫面單字")
                        .font(.system(size: 12, weight: .heavy))
                    Spacer(minLength: 2)
                    Text(context.state.level)
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundStyle(Color(red: 0.28, green: 0.20, blue: 0.45))

                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 7), GridItem(.flexible(), spacing: 7)],
                    spacing: 7
                ) {
                    ForEach(0..<min(4, context.state.words.count), id: \.self) { i in
                        let word = context.state.words[i]
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(alignment: .firstTextBaseline, spacing: 3) {
                                Text(word.english)
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.65)
                                Spacer(minLength: 0)
                                if !word.partOfSpeech.isEmpty {
                                    Text(word.partOfSpeech)
                                        .font(.system(size: 9, weight: .semibold))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.6)
                                        .foregroundStyle(Color(red: 0.36, green: 0.27, blue: 0.57))
                                }
                            }
                            Text(word.chinese)
                                .font(.system(size: 12, weight: .medium))
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)
                        }
                        .foregroundStyle(Color(red: 0.20, green: 0.17, blue: 0.30))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 11)
                        .frame(maxWidth: .infinity, minHeight: 51, alignment: .leading)
                        .background(
                            Color.white.opacity(0.86),
                            in: RoundedRectangle(cornerRadius: 11)
                        )
                    }
                }

                HStack {
                    Text("打開 WordFlow 複習")
                        .font(.system(size: 11, weight: .medium))
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundStyle(Color(red: 0.37, green: 0.29, blue: 0.51))
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 12)
            .activityBackgroundTint(Color(red: 0.91, green: 0.88, blue: 0.98))
            .activitySystemActionForegroundColor(.black)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label("WordFlow", systemImage: "book.closed.fill")
                        .font(.caption.bold())
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.level).font(.caption.bold())
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.words.map(\.english).joined(separator: " · "))
                        .font(.caption)
                        .lineLimit(2)
                }
            } compactLeading: {
                Image(systemName: "book.closed.fill")
            } compactTrailing: {
                Text("4字").font(.caption2.bold())
            } minimal: {
                Image(systemName: "book.closed.fill")
            }
            .widgetURL(URL(string: "wordflow:///"))
        }
    }
}

@main
struct WordFlowWidgets: WidgetBundle {
    var body: some Widget {
        WordFlowDailyWordWidget()
        WordFlowDailyPhraseWidget()
        WordFlowStudyLiveActivityWidget()
    }
}
