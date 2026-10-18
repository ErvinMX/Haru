
import Foundation

struct SubTheme: Equatable, Hashable {
    let domain: String
    let name: String
    var title: String { name }
}

enum HaruDifficulty: String, CaseIterable, Identifiable {
    case beginner, intermediate, advanced

    var id: String { rawValue }

    var part: Int {
        Self.allCases.firstIndex(of: self)! + 1
    }

    var title: String { rawValue.capitalized }

    var next: HaruDifficulty? {
        Self.allCases.dropFirst(part).first
    }
}

enum Curriculum {
    static let allSubThemes: [SubTheme] = [
        SubTheme(domain: "Actions & Changes", name: "Actions & Changes"),
        SubTheme(domain: "Arts & Entertainment", name: "Arts & Entertainment"),
        SubTheme(domain: "Communication & Media", name: "Communication & Media"),
        SubTheme(domain: "Descriptions & Qualities", name: "Descriptions & Qualities"),
        SubTheme(domain: "Education & Learning", name: "Education & Learning"),
        SubTheme(domain: "Feelings & Emotions", name: "Feelings & Emotions"),
        SubTheme(domain: "Food & Cooking", name: "Food & Cooking"),
        SubTheme(domain: "Government & Law", name: "Government & Law"),
        SubTheme(domain: "Grammar & Expressions", name: "Grammar & Expressions"),
        SubTheme(domain: "Health & Body", name: "Health & Body"),
        SubTheme(domain: "Home & Living", name: "Home & Living"),
        SubTheme(domain: "Nature & Environment", name: "Nature & Environment"),
        SubTheme(domain: "People & Relationships", name: "People & Relationships"),
        SubTheme(domain: "Places & Services", name: "Places & Services"),
        SubTheme(domain: "Science & Technology", name: "Science & Technology"),
        SubTheme(domain: "Shopping & Money", name: "Shopping & Money"),
        SubTheme(domain: "Society & Culture", name: "Society & Culture"),
        SubTheme(domain: "Space & Direction", name: "Space & Direction"),
        SubTheme(domain: "Sports & Leisure", name: "Sports & Leisure"),
        SubTheme(domain: "Thinking & Reasoning", name: "Thinking & Reasoning"),
        SubTheme(domain: "Time & Numbers", name: "Time & Numbers"),
        SubTheme(domain: "Travel & Transportation", name: "Travel & Transportation"),
        SubTheme(domain: "Work & Careers", name: "Work & Careers")
    ]

    static var allThemeTitles: [String] {
        allSubThemes.map(\.title)
    }

    static var currentDifficulty: HaruDifficulty {
        let index = min(
            2,
            max(
                0,
                UserDefaults.standard.integer(
                    forKey: "haru.currentDifficultyIndex"
                )
            )
        )

        return HaruDifficulty.allCases[index]
    }

    static func words(
        in theme: String,
        from words: [TopikWord],
        level: HaruDifficulty? = nil
    ) -> [TopikWord] {
        let selected = level ?? currentDifficulty

        return words.filter {
            $0.theme == theme &&
            $0.level == selected.rawValue
        }
    }

    static func themes(
        with words: [TopikWord],
        level: HaruDifficulty? = nil
    ) -> [SubTheme] {
        let selected = level ?? currentDifficulty

        let available = Set(
            words
                .filter { $0.level == selected.rawValue }
                .compactMap(\.theme)
        )

        return allSubThemes.filter {
            available.contains($0.title)
        }
    }

    static func complete(
        level: HaruDifficulty,
        words: [TopikWord],
        introducedIDs: Set<String>
    ) -> Bool {
        let levelWords = words.filter {
            $0.level == level.rawValue
        }

        return !levelWords.isEmpty &&
            levelWords.allSatisfy {
                introducedIDs.contains($0.learningUnitID)
            }
    }
}
