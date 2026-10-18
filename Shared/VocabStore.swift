
//
//  VocabStore.swift
//  Haru
//

import Foundation
import Combine
import SwiftUI
import WidgetKit

final class VocabStore: ObservableObject {

    static let shared = VocabStore()

    private let userDefaults = UserDefaults.standard

    // MARK: - Persistence Keys

    private let scoresKey = "haru_v3_mastery_scores"
    private let introducedWordsKey = "haru_v3_introduced_word_ids"
    private let introducedDatesKey = "haru_v3_introduced_dates"
    private let currentThemeKey = "haru_v3_current_theme"
    private let practiceQuizUnlockedKey = "haru_v3_practice_quiz_unlocked"

    // MARK: - Widget Sharing

    private let widgetAppGroup = "group.com.mingxiang.koreanvocab"
    private let widgetWordsKey = "haru_v3_widget_introduced_words"

    // MARK: - Published Properties

    /// learning_unit_id -> mastery score (0...3)
    @Published var masteryScores: [String: Int] = [:]

    /// Every vocabulary learning unit
    /// the user has already encountered.
    @Published var introducedLearningUnitIDs: Set<String> = []

    /// First introduction date for each learning unit.
    @Published private(set) var introductionDates: [String: Date] = [:]

    /// The user's currently selected theme.
    @Published var currentTheme: String? = nil

    /// Once the user has discovered at least
    /// 10 words, Practice Quiz stays unlocked.
    @Published var isPracticeQuizUnlocked: Bool = false

    // MARK: - Widget Word Model

    /// Lightweight vocabulary model stored in the App Group
    /// for the widget extension.
    struct WidgetWord: Codable {
        let learningUnitID: String
        let hangul: String
        let english: String
    }

    // MARK: - Init

    private init() {
        loadData()
    }

    // Legacy learning-unit IDs belong to the earlier TOPIK dataset.
    // Keep their saved values intact, but begin a separate Haru V3 history.
    func prepareNewVocabularyProgress() {
        let migrationKey = "haru.vocabulary.v3.progressPrepared"
        guard !userDefaults.bool(forKey: migrationKey) else { return }
        userDefaults.set(0, forKey: "haru.journey.sequentialUnlockedIndex")
        userDefaults.set(0, forKey: "haru.currentDifficultyIndex")
        userDefaults.set(true, forKey: migrationKey)
    }

    // MARK: - Load from Disk

    private func loadData() {

        if let savedScores =
            userDefaults.dictionary(
                forKey: scoresKey
            ) as? [String: Int] {

            masteryScores = savedScores
        }

        if let savedIDs =
            userDefaults.array(
                forKey: introducedWordsKey
            ) as? [String] {

            introducedLearningUnitIDs =
                Set(savedIDs)
        }

        if let dates = userDefaults.dictionary(forKey: introducedDatesKey) as? [String: Date] {
            introductionDates = dates
        }

        currentTheme =
            userDefaults.string(
                forKey: currentThemeKey
            )

        isPracticeQuizUnlocked =
            userDefaults.bool(
                forKey: practiceQuizUnlockedKey
            )
    }

    // MARK: - Save to Disk

    private func saveData() {

        userDefaults.set(
            masteryScores,
            forKey: scoresKey
        )

        userDefaults.set(
            Array(introducedLearningUnitIDs),
            forKey: introducedWordsKey
        )

        userDefaults.set(
            introductionDates,
            forKey: introducedDatesKey
        )

        userDefaults.set(
            currentTheme,
            forKey: currentThemeKey
        )

        userDefaults.set(
            isPracticeQuizUnlocked,
            forKey: practiceQuizUnlockedKey
        )
    }

    // MARK: - Introduction Tracking

    func hasIntroduced(_ word: TopikWord) -> Bool {
        introducedLearningUnitIDs.contains(
            word.learningUnitID
        )
    }

    func markIntroduced(_ word: TopikWord) {

        let id = word.learningUnitID

        guard !introducedLearningUnitIDs.contains(id) else {
            return
        }

        introducedLearningUnitIDs.insert(id)

        introductionDates[id] = Date()

        if introducedLearningUnitIDs.count >= 10 {
            isPracticeQuizUnlocked = true
        }

        saveData()
        syncWidgetWords()
    }

    // MARK: - Mastery Tracking

    func masteryScore(for word: TopikWord) -> Int {
        masteryScores[word.learningUnitID] ?? 0
    }

    func setMasteryScore(
        _ score: Int,
        for word: TopikWord
    ) {

        masteryScores[word.learningUnitID] =
            min(max(score, 0), 3)

        saveData()
    }

    func incrementMastery(for word: TopikWord) {

        let current =
            masteryScores[word.learningUnitID] ?? 0

        masteryScores[word.learningUnitID] =
            min(current + 1, 3)

        saveData()
    }

    func decrementMastery(for word: TopikWord) {

        let current =
            masteryScores[word.learningUnitID] ?? 0

        masteryScores[word.learningUnitID] =
            max(current - 1, 0)

        saveData()
    }

    // MARK: - Theme Progress

    func introducedCount(
        for theme: String,
        from words: [TopikWord]
    ) -> Int {

        words.filter {
            $0.theme == theme &&
            introducedLearningUnitIDs.contains(
                $0.learningUnitID
            )
        }.count
    }

    func totalCount(
        for theme: String,
        from words: [TopikWord]
    ) -> Int {

        words.filter {
            $0.theme == theme
        }.count
    }

    func isThemeCompleted(
        _ theme: String,
        from words: [TopikWord]
    ) -> Bool {

        let themeWords = words.filter {
            $0.theme == theme
        }

        guard !themeWords.isEmpty else {
            return false
        }

        return themeWords.allSatisfy {
            introducedLearningUnitIDs.contains(
                $0.learningUnitID
            )
        }
    }

    // MARK: - Difficulty Progress

    func introducedCount(
        for difficulty: HaruDifficulty,
        from words: [TopikWord]
    ) -> Int {

        words.filter {
            $0.level == difficulty.rawValue &&
            introducedLearningUnitIDs.contains(
                $0.learningUnitID
            )
        }.count
    }

    func totalCount(
        for difficulty: HaruDifficulty,
        from words: [TopikWord]
    ) -> Int {

        words.filter {
            $0.level == difficulty.rawValue
        }.count
    }

    func isDifficultyCompleted(
        _ difficulty: HaruDifficulty,
        from words: [TopikWord]
    ) -> Bool {

        Curriculum.complete(
            level: difficulty,
            words: words,
            introducedIDs: introducedLearningUnitIDs
        )
    }

    // MARK: - Current Theme

    func setCurrentTheme(_ theme: String?) {

        currentTheme = theme

        saveData()
    }

    // MARK: - Widget Sync

    func syncWidgetWords() {

        guard let sharedDefaults =
            UserDefaults(suiteName: widgetAppGroup) else {
            return
        }

        sharedDefaults.set(
            Array(introducedLearningUnitIDs),
            forKey: widgetWordsKey
        )

        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Reset Progress

    func resetProgress() {

        masteryScores.removeAll()
        introducedLearningUnitIDs.removeAll()
        introductionDates.removeAll()

        currentTheme = nil
        isPracticeQuizUnlocked = false

        userDefaults.set(
            0,
            forKey: "haru.currentDifficultyIndex"
        )

        userDefaults.set(
            0,
            forKey: "haru.journey.sequentialUnlockedIndex"
        )

        saveData()
        syncWidgetWords()
    }
}
