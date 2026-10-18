
import SwiftUI

struct TopikThemeProgressView: View {

    let subTheme: SubTheme
    let allWords: [TopikWord]
    var difficulty: HaruDifficulty? = nil

    @ObservedObject private var store =
        VocabStore.shared

    // MARK: - Theme Words

    private var themeWords: [TopikWord] {
        Curriculum.words(
            in: subTheme.title,
            from: allWords,
            level: difficulty
        )
    }

    private var discoveredWords: [TopikWord] {
        themeWords.filter {
            store.hasIntroduced($0)
        }
    }

    private var masteredWords: [TopikWord] {
        discoveredWords.filter {
            store.masteryScore(for: $0) >= 3
        }
    }

    private var progress: Double {
        guard !themeWords.isEmpty else {
            return 0
        }

        return Double(discoveredWords.count)
            / Double(themeWords.count)
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: 20
            ) {
                summaryCard

                Text("VOCABULARY")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)

                VStack(spacing: 0) {
                    ForEach(
                        Array(themeWords.enumerated()),
                        id: \.element.id
                    ) { index, word in

                        wordRow(word: word)

                        if index < themeWords.count - 1 {
                            Divider()
                                .padding(.leading, 16)
                        }
                    }
                }
                .background(
                    Color.gray.opacity(0.08)
                )
                .cornerRadius(16)
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 16)
        }
        .navigationTitle(subTheme.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Summary

    private var summaryCard: some View {
        VStack(
            alignment: .leading,
            spacing: 14
        ) {
            Text("PART \( (difficulty ?? Curriculum.currentDifficulty).part) · \( (difficulty ?? Curriculum.currentDifficulty).title.uppercased()) · \(subTheme.domain.uppercased())")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {
                    Text(subTheme.name)
                        .font(.title2)
                        .bold()

                    Text(
                        "\(discoveredWords.count) of \(themeWords.count) words discovered"
                    )
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }

                Spacer()

                if !themeWords.isEmpty &&
                    discoveredWords.count == themeWords.count {

                    Image(
                        systemName: "checkmark.circle.fill"
                    )
                    .font(.title2)
                    .foregroundColor(.green)
                }
            }

            ProgressView(
                value: Double(discoveredWords.count),
                total: Double(max(themeWords.count, 1))
            )

            HStack {
                VStack(
                    alignment: .leading,
                    spacing: 3
                ) {
                    Text("\(discoveredWords.count)")
                        .font(.headline)

                    Text("Discovered")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(
                    alignment: .trailing,
                    spacing: 3
                ) {
                    Text("\(masteredWords.count)")
                        .font(.headline)

                    Text("Mastered")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(20)
        .background(
            Color.gray.opacity(0.12)
        )
        .cornerRadius(18)
        .padding(.horizontal, 20)
    }

    // MARK: - Word Row

    @ViewBuilder
    private func wordRow(
        word: TopikWord
    ) -> some View {

        if store.hasIntroduced(word) {

            NavigationLink {
                WordReviewView(word: word)
            } label: {
                discoveredWordRow(word: word)
            }
            .buttonStyle(.plain)

        } else {
            undiscoveredWordRow
        }
    }

    // MARK: - Discovered Word

    private func discoveredWordRow(
        word: TopikWord
    ) -> some View {

        let mastery = store.masteryScore(for: word)

        return HStack(spacing: 14) {

            VStack(
                alignment: .leading,
                spacing: 4
            ) {
                Text(word.hangul)
                    .font(.headline)

                Text(word.english)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(
                alignment: .trailing,
                spacing: 4
            ) {
                if mastery >= 3 {
                    Image(
                        systemName: "checkmark.circle.fill"
                    )
                    .foregroundColor(.green)

                } else {
                    HStack(spacing: 2) {
                        ForEach(0..<3, id: \.self) { index in
                            Image(
                                systemName: index < mastery
                                    ? "star.fill"
                                    : "star"
                            )
                            .font(.caption)
                            .foregroundColor(
                                index < mastery
                                    ? .yellow
                                    : .secondary
                            )
                        }
                    }
                }

                Text("\(mastery) / 3")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(16)
    }

    // MARK: - Undiscovered Word

    private var undiscoveredWordRow: some View {
        HStack(spacing: 14) {
            Image(systemName: "lock.fill")
                .foregroundColor(.secondary)

            VStack(
                alignment: .leading,
                spacing: 4
            ) {
                Text("Undiscovered Word")
                    .font(.headline)

                Text("Learn this word to reveal it")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .opacity(0.65)
    }
}
