//
//  QuizGnerator.swift
//  Haru
//
//  Created by Ervin Sng on 20/9/26.
//
import Foundation

final class QuizGenerator {
    static let shared = QuizGenerator()
    private init() {}

    // MARK: - Local Beginner Quiz Generation
    func generateBeginnerQuiz(from pool: [TopikWord], theme: String = "Daily Verbs", questionCount: Int = 10) -> Quiz {
        guard pool.count >= 4 else { return Quiz(questions: []) }

        var generatedQuestions: [QuizQuestion] = []
        let availableTypes: [QuizQuestionType] = [.hangulToEnglish, .englishToHangul]
        let targets = pool.shuffled().prefix(questionCount)

        for target in targets {
            let qType = availableTypes.randomElement() ?? .hangulToEnglish
            let distractors = pool.filter { $0.id != target.id }.shuffled().prefix(3)
            guard distractors.count == 3 else { continue }

            var options: [String] = []
            var prompt = ""
            var subtitle = ""
            var explanation = ""

            switch qType {
            case .hangulToEnglish:
                prompt = target.hangul
                subtitle = "Choose the correct English meaning"
                options = ([target.english] + distractors.map { $0.english }).shuffled()
                explanation = "\(target.hangul) means \"\(target.english)\"."
                
            case .englishToHangul:
                prompt = target.english
                subtitle = "Select the matching Hangul word"
                options = ([target.hangul] + distractors.map { $0.hangul }).shuffled()
                explanation = "\"\(target.english)\" in Korean is \(target.hangul)."
                
            case .hangulToRomanization: // Fallback just in case
                prompt = target.hangul
                subtitle = "Choose the correct English meaning"
                options = ([target.english] + distractors.map { $0.english }).shuffled()
                explanation = "\(target.hangul) means \"\(target.english)\"."
            }

            let correctValue = (qType == .englishToHangul) ? target.hangul : target.english

            if let correctIndex = options.firstIndex(of: correctValue) {
                generatedQuestions.append(
                    QuizQuestion(
                        theme: theme,
                        questionType: qType,
                        prompt: prompt,
                        subtitle: subtitle,
                        options: options,
                        correctAnswerIndex: correctIndex,
                        targetWordHangul: target.hangul,
                        explanation: explanation
                    )
                )
            }
        }

        return Quiz(questions: generatedQuestions)
    }

    // MARK: - Hybrid Quiz Generation (New + Review)
    func generateHybridQuiz(currentWords: [TopikWord], pastWords: [TopikWord], currentTheme: String, newCount: Int = 10, reviewCount: Int = 5) -> Quiz {
        
        // 1. Generate new questions
        let newQuiz = generateBeginnerQuiz(from: currentWords, theme: currentTheme, questionCount: newCount)
        
        // 2. Generate review questions (fallback to empty if no past words exist yet)
        var reviewQuestions: [QuizQuestion] = []
        if pastWords.count >= 4 {
            let reviewQuiz = generateBeginnerQuiz(from: pastWords, theme: "Review", questionCount: reviewCount)
            reviewQuestions = reviewQuiz.questions
        }
        
        // 3. Combine them (Review questions at the end)
        return Quiz(questions: newQuiz.questions + reviewQuestions)
    }
}
