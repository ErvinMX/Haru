//
//  WordReviewView.swift
//  Haru
//
//  Created by Ervin Sng on 4/10/26.
//

import SwiftUI

struct WordReviewView: View {

    let word: TopikWord
    
    
    @AppStorage("haru.appearance.koreanFontSize")
    private var koreanFontSize = 60.0

    @ObservedObject private var store =
        VocabStore.shared


    var body: some View {

        ScrollView {

            VStack(spacing: 28) {

                Spacer(minLength: 30)


                // MARK: - Word

                VStack(spacing: 12) {

                    Text("WORD REVIEW")
                        .font(.caption)
                        .foregroundColor(.secondary)


                    HStack(spacing: 12) {

                        Text(word.hangul)
                            .font(
                                .system(
                                    size: CGFloat(koreanFontSize),
                                    weight: .bold
                                )
                            )
                            .lineLimit(3)
                            .minimumScaleFactor(0.65)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)


                        Button {

                            SpeechManager.shared
                                .speakKorean(
                                    word.hangul
                                )

                        } label: {

                            Image(
                                systemName:
                                    "speaker.wave.2.fill"
                            )
                            .font(.title2)
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.blue)
                        .accessibilityLabel(
                            "Hear pronunciation"
                        )
                    }


                    Text(word.english)
                        .font(.title2)
                        .foregroundColor(
                            .secondary
                        )
                        .multilineTextAlignment(
                            .center
                        )


                    if let partOfSpeech =
                        word.partOfSpeech {

                        Text(partOfSpeech)
                            .font(.subheadline)
                            .foregroundColor(
                                .secondary
                            )
                            .padding(
                                .horizontal,
                                12
                            )
                            .padding(
                                .vertical,
                                6
                            )
                            .background(
                                Color.gray.opacity(
                                    0.12
                                )
                            )
                            .cornerRadius(10)
                    }
                }


                // MARK: - Example Sentence

                if let korean = word.exampleKo?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !korean.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("EXAMPLE SENTENCE")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)

                        HStack(alignment: .center, spacing: 12) {
                            Text(korean)
                                .font(.body)
                                .fontWeight(.medium)
                                .fixedSize(horizontal: false, vertical: true)

                            Spacer(minLength: 0)

                            Button {
                                SpeechManager.shared.speakKorean(korean)
                            } label: {
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.title3)
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.blue)
                            .accessibilityLabel("Hear example sentence")
                        }

                        if let english = word.exampleEn?.trimmingCharacters(in: .whitespacesAndNewlines),
                           !english.isEmpty {
                            Text(english)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .background(Color.gray.opacity(0.08))
                    .cornerRadius(16)
                }

                // MARK: - Mastery

                VStack(spacing: 12) {

                    Text("Mastery")
                        .font(.headline)


                    HStack(spacing: 10) {

                        ForEach(
                            0..<3,
                            id: \.self
                        ) { index in

                            Image(
                                systemName:
                                    index < masteryScore
                                    ? "star.fill"
                                    : "star"
                            )
                            .font(.title2)
                            .foregroundColor(
                                index < masteryScore
                                ? .orange
                                : .secondary
                            )
                        }
                    }


                    Text(
                        masteryDescription
                    )
                    .font(.subheadline)
                    .foregroundColor(
                        .secondary
                    )
                }
                .frame(
                    maxWidth: .infinity
                )
                .padding(20)
                .background(
                    Color.gray.opacity(0.08)
                )
                .cornerRadius(18)


                // MARK: - Theme

                if let theme = word.theme {

                    VStack(
                        alignment: .leading,
                        spacing: 8
                    ) {

                        Text("Theme")
                            .font(.caption)
                            .foregroundColor(
                                .secondary
                            )


                        Text(theme)
                            .font(.headline)
                    }
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                    .padding(18)
                    .background(
                        Color.gray.opacity(0.08)
                    )
                    .cornerRadius(16)
                }


                Spacer(minLength: 30)
            }
            .padding(
                .horizontal,
                24
            )
        }
        .navigationTitle(
            "Review Word"
        )
        .navigationBarTitleDisplayMode(
            .inline
        )
    }


    // MARK: - Mastery Score

    private var masteryScore: Int {

        store.masteryScore(
            for: word
        )
    }


    // MARK: - Mastery Description

    private var masteryDescription: String {

        switch masteryScore {

        case 0:
            return "0 / 3 · Just discovered"

        case 1:
            return "1 / 3 · Learning"

        case 2:
            return "2 / 3 · Almost mastered"

        case 3:
            return "3 / 3 · Mastered"

        default:
            return "\(masteryScore) / 3"
        }
    }
}
