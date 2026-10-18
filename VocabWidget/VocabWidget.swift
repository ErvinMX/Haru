import WidgetKit
import SwiftUI

// MARK: - Shared Widget Word

struct WidgetWord: Codable, Hashable {

    let learningUnitID: String
    let hangul: String
    let english: String
}


// MARK: - Timeline Entry

struct VocabEntry: TimelineEntry {

    let date: Date
    let word: WidgetWord?
}


// MARK: - Timeline Provider

struct VocabProvider: TimelineProvider {

    private let appGroup =
        "group.com.mingxiang.koreanvocab"

    private let widgetWordsKey =
        "widget_introduced_words"


    func placeholder(
        in context: Context
    ) -> VocabEntry {

        VocabEntry(
            date: Date(),
            word:
                WidgetWord(
                    learningUnitID: "preview",
                    hangul: "먹다",
                    english: "to eat"
                )
        )
    }


    func getSnapshot(
        in context: Context,
        completion:
            @escaping (VocabEntry) -> Void
    ) {

        let words = loadWords()

        let entry =
            VocabEntry(
                date: Date(),
                word: words.first
            )

        completion(entry)
    }


    func getTimeline(
        in context: Context,
        completion:
            @escaping (Timeline<VocabEntry>) -> Void
    ) {

        let words = loadWords()

        // No learned words yet
        if words.isEmpty {

            let entry =
                VocabEntry(
                    date: Date(),
                    word: nil
                )

            let nextRefresh =
                Calendar.current.date(
                    byAdding: .hour,
                    value: 2,
                    to: Date()
                ) ?? Date()

            completion(
                Timeline(
                    entries: [entry],
                    policy:
                        .after(nextRefresh)
                )
            )

            return
        }


        // Shuffle learned words so the widget
        // does not always show them in the same order.
        let shuffledWords =
            words.shuffled()

        var entries: [VocabEntry] = []

        let now = Date()


        // Prepare 8 widget changes.
        // Each one is approximately 3 hours apart.
        for index in 0..<8 {

            let word =
                shuffledWords[
                    index %
                    shuffledWords.count
                ]

            let entryDate =
                Calendar.current.date(
                    byAdding: .hour,
                    value: index * 3,
                    to: now
                ) ?? now

            let entry =
                VocabEntry(
                    date: entryDate,
                    word: word
                )

            entries.append(entry)
        }


        // Ask WidgetKit for a new timeline
        // after roughly 24 hours.
        let refreshDate =
            Calendar.current.date(
                byAdding: .hour,
                value: 24,
                to: now
            ) ?? now

        completion(
            Timeline(
                entries: entries,
                policy:
                    .after(refreshDate)
            )
        )
    }


    // MARK: - Load Shared Words

    private func loadWords()
        -> [WidgetWord] {

        guard let sharedDefaults =
                UserDefaults(
                    suiteName: appGroup
                ) else {

            return []
        }

        guard let data =
                sharedDefaults.data(
                    forKey:
                        widgetWordsKey
                ) else {

            return []
        }

        do {

            return try
                JSONDecoder()
                .decode(
                    [WidgetWord].self,
                    from: data
                )

        } catch {

            print(
                "❌ Widget word decode error:",
                error
            )

            return []
        }
    }
}


// MARK: - Widget View

struct VocabWidgetEntryView: View {

    let entry: VocabEntry

    @Environment(\.widgetFamily)
    private var family


    var body: some View {

        Group {

            switch family {

            case .accessoryRectangular:

                lockScreenView

            default:

                homeScreenView
            }
        }

        // When there is a real word,
        // tapping the widget opens:
        //
        // haru://review?id=<learningUnitID>
        .widgetURL(widgetURL)
    }


    // MARK: - Deep Link

    private var widgetURL: URL? {

        guard let word =
                entry.word else {

            return nil
        }

        var components =
            URLComponents()

        components.scheme = "haru"

        components.host = "review"

        components.queryItems = [

            URLQueryItem(
                name: "id",
                value:
                    word.learningUnitID
            )
        ]

        return components.url
    }


    // MARK: - Lock Screen Widget

    private var lockScreenView: some View {

        Group {

            if let word = entry.word {

                VStack(
                    alignment: .leading,
                    spacing: 2
                ) {

                    Text(word.hangul)
                        .font(.headline)
                        .bold()

                    Text(word.english)
                        .font(.caption)
                        .lineLimit(1)
                }
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .leading
                )

            } else {

                VStack(
                    alignment: .leading,
                    spacing: 2
                ) {

                    Text("Haru")
                        .font(.headline)
                        .bold()

                    Text(
                        "Learn a word to begin"
                    )
                    .font(.caption)
                }
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .leading
                )
            }
        }
    }


    // MARK: - Home Screen Widget

    private var homeScreenView: some View {

        VStack(spacing: 8) {

            if let word = entry.word {

                Text("Haru")
                    .font(.caption)
                    .foregroundStyle(
                        .secondary
                    )

                Spacer()

                Text(word.hangul)
                    .font(.title)
                    .bold()
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)

                Text(word.english)
                    .font(.subheadline)
                    .foregroundStyle(
                        .secondary
                    )
                    .multilineTextAlignment(
                        .center
                    )
                    .lineLimit(2)

                Spacer()

            } else {

                Text("Haru")
                    .font(.headline)
                    .bold()

                Spacer()

                Text(
                    "Learn your first word to start widget review."
                )
                .font(.caption)
                .foregroundStyle(
                    .secondary
                )
                .multilineTextAlignment(
                    .center
                )

                Spacer()
            }
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
    }
}


// MARK: - Widget

struct VocabWidget: Widget {

    let kind: String =
        "VocabWidget"


    var body: some WidgetConfiguration {

        StaticConfiguration(
            kind: kind,
            provider:
                VocabProvider()
        ) { entry in

            VocabWidgetEntryView(
                entry: entry
            )
            .containerBackground(
                .fill.tertiary,
                for: .widget
            )
        }
        .configurationDisplayName(
            "Haru Vocabulary"
        )
        .description(
            "Review Korean words you've already discovered."
        )
        .supportedFamilies(
            [
                .systemSmall,
                .accessoryRectangular
            ]
        )
    }
}


// MARK: - Preview

#Preview(
    as: .systemSmall
) {

    VocabWidget()

} timeline: {

    VocabEntry(
        date: Date(),
        word:
            WidgetWord(
                learningUnitID:
                    "preview",
                hangul:
                    "먹다",
                english:
                    "to eat"
            )
    )
}


#Preview(
    as: .accessoryRectangular
) {

    VocabWidget()

} timeline: {

    VocabEntry(
        date: Date(),
        word:
            WidgetWord(
                learningUnitID:
                    "preview",
                hangul:
                    "먹다",
                english:
                    "to eat"
            )
    )
}
