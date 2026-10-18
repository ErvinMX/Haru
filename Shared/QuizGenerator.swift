
import Foundation

final class QuizGenerator {

    static let shared = QuizGenerator()

    private init() {}

    // MARK: - Standard Quiz Generation

    func generateBeginnerQuiz(
        from pool: [TopikWord],
        theme: String = "Vocabulary",
        questionCount: Int = 10
    ) -> Quiz {

        generateQuiz(
            targets: Array(
                pool
                    .shuffled()
                    .prefix(questionCount)
            ),
            distractorPool: pool,
            fallbackTheme: theme
        )
    }

    // MARK: - Practice Quiz Generation

    func generatePracticeQuiz(
        from introducedWords: [TopikWord],
        store: VocabStore,
        questionCount: Int = 10
    ) -> Quiz {

        // All introduced words remain eligible,
        // including words already mastered.

        guard introducedWords.count >= 4,
              questionCount > 0 else {
            return Quiz(questions: [])
        }

        // Avoid repeating the same learning unit.

        var seen = Set<String>()

        let pool = introducedWords.filter {
            seen.insert($0.learningUnitID).inserted
        }

        let targetCount = min(
            questionCount,
            pool.count
        )

        // MARK: - Recent vs Older Vocabulary
        //
        // The new VocabStore no longer tracks
        // introduction timestamps.
        //
        // Treat words from the current Journey
        // theme as recent vocabulary.
        //
        // All other discovered words are older
        // review vocabulary.

        let recent = pool.filter {
            $0.theme == store.currentTheme
        }

        let older = pool.filter {
            $0.theme != store.currentTheme
        }

        // Aim for approximately 70% recent
        // and 30% older vocabulary.

        let recentGoal = Int(
            (Double(targetCount) * 0.7).rounded()
        )

        let olderGoal = targetCount - recentGoal

        var selected = weightedTargets(
            from: recent,
            store: store,
            count: recentGoal
        )

        selected += weightedTargets(
            from: older,
            store: store,
            count: olderGoal
        )

        // Fill any remaining slots from either
        // group without repeating learning units.

        let selectedIDs = Set(
            selected.map(\.learningUnitID)
        )

        let remaining = pool.filter {
            !selectedIDs.contains($0.learningUnitID)
        }

        selected += weightedTargets(
            from: remaining,
            store: store,
            count: targetCount - selected.count
        )

        return generateQuiz(
            targets: selected.shuffled(),
            distractorPool: pool,
            fallbackTheme: "Practice"
        )
    }

    // MARK: - Weighted Target Selection

    private func weightedTargets(
        from words: [TopikWord],
        store: VocabStore,
        count: Int
    ) -> [TopikWord] {

        guard count > 0 else {
            return []
        }

        var remaining = words
        var selected: [TopikWord] = []

        while !remaining.isEmpty &&
              selected.count < count {

            // Less-mastered words have a
            // higher chance of being selected.

            let weightedPool = remaining.flatMap {
                word -> [TopikWord] in

                let weight: Int

                switch store.masteryScore(for: word) {
                case 0:
                    weight = 6

                case 1:
                    weight = 4

                case 2:
                    weight = 2

                default:
                    weight = 1
                }

                return Array(
                    repeating: word,
                    count: weight
                )
            }

            guard let chosen =
                weightedPool.randomElement() else {
                break
            }

            selected.append(chosen)

            remaining.removeAll {
                $0.learningUnitID ==
                    chosen.learningUnitID
            }
        }

        return selected
    }

    // MARK: - Core Question Generation

    private func generateQuiz(
        targets: [TopikWord],
        distractorPool: [TopikWord],
        fallbackTheme: String
    ) -> Quiz {

        guard distractorPool.count >= 4 else {
            return Quiz(questions: [])
        }

        var generatedQuestions: [QuizQuestion] = []

        let availableTypes: [QuizQuestionType] = [
            .hangulToEnglish,
            .englishToHangul
        ]

        for target in targets {

            let qType =
                availableTypes.randomElement()
                ?? .hangulToEnglish

            let distractors = chooseDistractors(
                for: target,
                from: distractorPool,
                questionType: qType
            )

            guard distractors.count == 3 else {
                continue
            }

            var options: [String] = []
            var prompt = ""
            var subtitle = ""
            var explanation = ""

            switch qType {

            case .hangulToEnglish:

                prompt = target.hangul

                subtitle =
                    "Choose the correct English meaning"

                options = (
                    [target.english] +
                    distractors.map {
                        $0.english
                    }
                )
                .shuffled()

                explanation =
                    "\(target.hangul) means \"\(target.english)\"."

            case .englishToHangul:

                prompt = target.english

                subtitle =
                    "Select the matching Hangul word"

                options = (
                    [target.hangul] +
                    distractors.map {
                        $0.hangul
                    }
                )
                .shuffled()

                explanation =
                    "\"\(target.english)\" in Korean is \(target.hangul)."

            case .hangulToRomanization:

                // Romanization remains disabled
                // until pronunciation data is ready.

                prompt = target.hangul

                subtitle =
                    "Choose the correct English meaning"

                options = (
                    [target.english] +
                    distractors.map {
                        $0.english
                    }
                )
                .shuffled()

                explanation =
                    "\(target.hangul) means \"\(target.english)\"."
            }

            let correctValue =
                qType == .englishToHangul
                ? target.hangul
                : target.english

            guard let correctIndex =
                options.firstIndex(of: correctValue)
            else {
                continue
            }

            let question = QuizQuestion(
                theme: target.theme ?? fallbackTheme,
                questionType: qType,
                prompt: prompt,
                subtitle: subtitle,
                options: options,
                correctAnswerIndex: correctIndex,
                targetWordHangul: target.hangul,
                targetLearningUnitID:
                    target.learningUnitID,
                explanation: explanation
            )

            generatedQuestions.append(question)
        }

        return Quiz(
            questions: generatedQuestions
        )
    }

    // MARK: - Distractor Selection

    private func chooseDistractors(
        for target: TopikWord,
        from pool: [TopikWord],
        questionType: QuizQuestionType
    ) -> [TopikWord] {

        var candidates = pool.filter {
            $0.learningUnitID != target.learningUnitID
        }

        // Prevent duplicate visible answers.

        switch questionType {

        case .hangulToEnglish,
             .hangulToRomanization:

            candidates = uniqueByEnglish(
                candidates,
                excluding: target.english
            )

        case .englishToHangul:

            candidates = uniqueByHangul(
                candidates,
                excluding: target.hangul
            )
        }

        return Array(
            candidates
                .shuffled()
                .prefix(3)
        )
    }

    // MARK: - Unique English Answers

    private func uniqueByEnglish(
        _ words: [TopikWord],
        excluding targetEnglish: String
    ) -> [TopikWord] {

        var seen: Set<String> = [
            targetEnglish
        ]

        var result: [TopikWord] = []

        for word in words.shuffled() {

            guard !seen.contains(word.english) else {
                continue
            }

            seen.insert(word.english)
            result.append(word)
        }

        return result
    }

    // MARK: - Unique Hangul Answers

    private func uniqueByHangul(
        _ words: [TopikWord],
        excluding targetHangul: String
    ) -> [TopikWord] {

        var seen: Set<String> = [
            targetHangul
        ]

        var result: [TopikWord] = []

        for word in words.shuffled() {

            guard !seen.contains(word.hangul) else {
                continue
            }

            seen.insert(word.hangul)
            result.append(word)
        }

        return result
    }

    // MARK: - Legacy Hybrid Quiz

    func generateHybridQuiz(
        currentWords: [TopikWord],
        pastWords: [TopikWord],
        newCount: Int = 10,
        reviewCount: Int = 5
    ) -> Quiz {

        let newQuiz = generateBeginnerQuiz(
            from: currentWords,
            theme: "New Vocabulary",
            questionCount: newCount
        )

        var reviewQuestions: [QuizQuestion] = []

        if pastWords.count >= 4 {

            let reviewQuiz = generateBeginnerQuiz(
                from: pastWords,
                theme: "Review",
                questionCount: reviewCount
            )

            reviewQuestions = reviewQuiz.questions
        }

        return Quiz(
            questions: (
                newQuiz.questions +
                reviewQuestions
            )
            .shuffled()
        )
    }
}
