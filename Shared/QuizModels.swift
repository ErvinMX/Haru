
//
//  QuizModels.swift
//  Haru
//
//  Created by Ervin Sng on 20/9/26.
//

import Foundation

enum QuizQuestionType: String, Codable {
    case hangulToEnglish = "Meaning"
    case hangulToRomanization = "Pronunciation"
    case englishToHangul = "Hangul Match"
}

struct QuizQuestion: Codable, Identifiable, Equatable {
    var id: UUID = UUID()

    let theme: String
    let questionType: QuizQuestionType
    let prompt: String
    let subtitle: String
    let options: [String]
    let correctAnswerIndex: Int

    let targetWordHangul: String
    let targetLearningUnitID: String?

    let explanation: String

    enum CodingKeys: String, CodingKey {
        case id
        case theme
        case questionType
        case prompt
        case subtitle
        case options
        case correctAnswerIndex
        case targetWordHangul
        case targetLearningUnitID
        case explanation
    }

    init(
        id: UUID = UUID(),
        theme: String,
        questionType: QuizQuestionType,
        prompt: String,
        subtitle: String,
        options: [String],
        correctAnswerIndex: Int,
        targetWordHangul: String,
        targetLearningUnitID: String? = nil,
        explanation: String
    ) {
        self.id = id
        self.theme = theme
        self.questionType = questionType
        self.prompt = prompt
        self.subtitle = subtitle
        self.options = options
        self.correctAnswerIndex = correctAnswerIndex
        self.targetWordHangul = targetWordHangul
        self.targetLearningUnitID = targetLearningUnitID
        self.explanation = explanation
    }
}

// MARK: - Quiz Model
struct Quiz: Codable, Equatable {
    var questions: [QuizQuestion]
    var partNumber: Int

    init(
        questions: [QuizQuestion],
        partNumber: Int = 1
    ) {
        self.questions = questions
        self.partNumber = partNumber
    }

    enum CodingKeys: String, CodingKey {
        case questions
        case partNumber
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(
            keyedBy: CodingKeys.self
        )

        questions = try container.decode(
            [QuizQuestion].self,
            forKey: .questions
        )

        // Old cached quizzes did not contain partNumber.
        // Treat old caches as Part 1.
        partNumber = try container.decodeIfPresent(
            Int.self,
            forKey: .partNumber
        ) ?? 1
    }
}

// Preserves the existing TopikWord API used by quizzes and widgets.
// The new Supabase IDs are stable strings and serve as learning unit IDs.
struct TopikWord: Codable, Identifiable, Hashable {
    let id: String
    let hangul: String
    let english: String
    let level: String
    let theme: String?
    let partOfSpeech: String?
    let exampleKo: String?
    let exampleEn: String?

    var learningUnitID: String { id }

    enum CodingKeys: String, CodingKey {
        case id, hangul, english, level, theme
        case partOfSpeech = "part_of_speech"
        case exampleKo = "example_ko"
        case exampleEn = "example_en"
    }
}
