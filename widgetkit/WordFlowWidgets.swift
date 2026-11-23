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
        // Same whitelist as LearningItem.partOfSpeech in Dart, so a free-text
        // note never ends up squeezed into the word-class capsule.
        return Self.wordClasses.contains(label) ? label : nil
    }

    private static let wordClasses: Set<String> = [
        "名詞", "動詞", "形容詞", "副詞", "介系詞", "連接詞",
        "代名詞", "名詞／動詞", "動詞／名詞", "名詞片語",
        "名詞複數", "常用詞",
    ]

    var hasExample: Bool { !example.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

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

/// The next-word action runs inside the WidgetKit extension and deliberately
/// avoids App Groups, which may be unavailable to SideStore free signing.
private struct WordFlowNextWordIntent: AppIntent {
    static var title: LocalizedStringResource = "換下一個英文單字"
    static var description = IntentDescription("鎖定畫面看熟的字，可直接換成下一個單字。")
    static var openAppWhenRun = false

    func perform() async throws -> some IntentResult {
        let defaults = UserDefaults.standard
        let key = "wordflow.widget.word_rotation"
        let current = defaults.integer(forKey: key)
        defaults.set((current + 1) % 1500, forKey: key)
        WidgetCenter.shared.reloadTimelines(ofKind: "WordFlowDailyWord")
        return .result()
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
        // A tap on the Lock Screen widget stores rotation in its own container.
        // The extension and its AppIntent share these UserDefaults; the Flutter
        // host app does not, so no App Group entitlement is required.
        let manual = kind == .word
            ? UserDefaults.standard.integer(forKey: "wordflow.widget.word_rotation")
            : 0
        let index = ((day + offset + manual) % choices.count + choices.count) % choices.count
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
            return [Color(red: 0.39, green: 0.30, blue: 0.48), Color(red: 0.28, green: 0.21, blue: 0.35)]
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
                ZStack {
                    AccessoryWidgetBackground()
                    VStack(spacing: 1) {
                        Image(systemName: "character.book.closed.fill").font(.system(size: 12))
                        // Show the full word scaled down instead of cutting it
                        // to 8 letters ("reservat" is not a word).
                        Text(entry.item.english)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .minimumScaleFactor(0.45)
                            .lineLimit(1)
                            .padding(.horizontal, 3)
                    }
                }
            case .accessoryRectangular:
                HStack(alignment: .center, spacing: 5) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(entry.item.english)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .lineLimit(1).minimumScaleFactor(0.7)
                        Text(entry.item.labeledMeaning)
                            .font(.system(size: 12, weight: .medium))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Phrase widgets keep their existing behavior.
                    if entry.kind == .word {
                        Button(intent: WordFlowNextWordIntent()) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 13, weight: .semibold))
                                .frame(width: 30, height: 35)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("換下一個英文單字")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
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

    // MARK: - Home Screen layouts

    @ViewBuilder
    private var fullColorCard: some View {
        switch family {
        case .systemSmall: smallCard
        case .systemMedium: mediumCard
        default: largeCard
        }
    }

    private var item: LearningItem { entry.item }

    private func header(compact: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: WordFlowPalette.symbol(for: item.category))
                .font(.system(size: compact ? 11 : 14, weight: .bold))
            Text(compact ? (entry.kind == .word ? "今日單字" : "今日詞句") : entry.kind.label)
                .font(.system(size: compact ? 11 : 13, weight: .heavy))
                .lineLimit(1)
            Spacer(minLength: 2)
            Text(item.level)
                .font(.system(size: compact ? 10 : 11, weight: .bold))
                .padding(.horizontal, compact ? 6 : 8)
                .padding(.vertical, 3)
                .background(.white.opacity(0.20), in: Capsule())
        }
        .foregroundStyle(.white.opacity(0.95))
    }

    private func englishText(size: CGFloat, lines: Int) -> some View {
        Text(item.english)
            .font(.system(size: size, weight: .heavy, design: .rounded))
            .tracking(-0.5)
            .foregroundStyle(.white)
            .lineLimit(lines)
            .minimumScaleFactor(0.5)
    }

    @ViewBuilder
    private func posCapsule(size: CGFloat) -> some View {
        if let pos = item.partOfSpeech {
            Text(pos)
                .font(.system(size: size, weight: .semibold))
                .foregroundStyle(.white.opacity(0.95))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(.white.opacity(0.19), in: Capsule())
                .fixedSize()
        }
    }

    private var footer: some View {
        HStack {
            Text("WORDFLOW  ·  \(WordFlowPalette.name(for: item.category))")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.1)
            Spacer()
            Image(systemName: "arrow.up.right")
                .font(.system(size: 10, weight: .bold))
        }
        .foregroundStyle(.white.opacity(0.76))
    }

    /// About 158pt square: header, word, and one "word class · meaning" line.
    /// No footer: there is no room for it once the word wraps to two lines.
    private var smallCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            header(compact: true)
            Spacer(minLength: 0)
            englishText(size: entry.kind == .word ? 28 : 19, lines: entry.kind == .word ? 2 : 3)
            Text(item.labeledMeaning)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.92))
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .padding(2)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    /// About 338x158pt: wide and short, so word and meaning go on the left and
    /// the example (or the topic icon) on the right, instead of one tall column.
    private var mediumCard: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                header(compact: true)
                Spacer(minLength: 0)
                englishText(size: entry.kind == .word ? 30 : 20, lines: 2)
                HStack(spacing: 6) {
                    posCapsule(size: 10)
                    Text(item.chinese)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.94))
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)

            if item.hasExample {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.kind == .word ? "EXAMPLE" : "IN CONTEXT")
                        .font(.system(size: 9, weight: .heavy))
                        .tracking(1.2)
                        .foregroundStyle(.white.opacity(0.7))
                    Text(item.example)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.92))
                        .lineLimit(4)
                        .minimumScaleFactor(0.85)
                    Spacer(minLength: 0)
                }
                .padding(10)
                .frame(width: 130, alignment: .leading)
                .frame(maxHeight: .infinity, alignment: .topLeading)
                .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 14))
            } else {
                Image(systemName: WordFlowPalette.symbol(for: item.category))
                    .font(.system(size: 52, weight: .bold))
                    .foregroundStyle(.white.opacity(0.22))
                    .frame(width: 84)
                    .frame(maxHeight: .infinity)
            }
        }
        .padding(4)
    }

    /// About 338x354pt: room for everything; the example sits in its own panel.
    private var largeCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            header(compact: false)
            Spacer(minLength: 0)
            englishText(size: entry.kind == .word ? 42 : 28, lines: 3)
            posCapsule(size: 12)
            Text(item.chinese)
                .font(.system(size: 21, weight: .semibold))
                .foregroundStyle(.white.opacity(0.94))
                .lineLimit(3)
                .minimumScaleFactor(0.8)
            if item.hasExample {
                VStack(alignment: .leading, spacing: 5) {
                    Text(item.example)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white.opacity(0.92))
                        .lineLimit(3)
                    if !item.exampleChinese.isEmpty {
                        Text(item.exampleChinese)
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.75))
                            .lineLimit(2)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 16))
            } else {
                Text("先想想怎麼用在句子裡，再打開 App 複習")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
            footer
        }
        .padding(6)
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
            .activityBackgroundTint(Color(red: 0.965, green: 0.953, blue: 0.933))
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
