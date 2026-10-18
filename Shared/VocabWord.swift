//
//  VocabWord.swift
//  Haru
//

import Foundation

struct VocabWord: Codable, Identifiable, Equatable {
    let id: UUID
    let hangul: String
    let romanization: String
    let englishMeaning: String
    let audioFileName: String?
    let topikLevel: Int

    init(
        id: UUID = UUID(),
        hangul: String,
        romanization: String,
        englishMeaning: String,
        audioFileName: String? = nil,
        topikLevel: Int = 1
    ) {
        self.id = id
        self.hangul = hangul
        self.romanization = romanization
        self.englishMeaning = englishMeaning
        self.audioFileName = audioFileName
        self.topikLevel = topikLevel
    }
}
