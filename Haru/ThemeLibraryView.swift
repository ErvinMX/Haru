
import SwiftUI

// MARK: - Theme Library

struct ThemeLibraryView: View {

    let allWords: [TopikWord]

    private var haruTheme: HaruTheme { HaruTheme() }

    @ObservedObject private var store =
        VocabStore.shared

    @AppStorage("haru.currentDifficultyIndex")
    private var currentDifficultyIndex = 0

    // MARK: - Body

    var body: some View {
        List {
            ForEach(HaruDifficulty.allCases) { difficulty in
                if difficulty.part <= currentDifficultyIndex + 1 {
                    NavigationLink {
                        reviewList(for: difficulty)
                    } label: {
                        difficultyRow(
                            difficulty,
                            locked: false
                        )
                    }
                } else {
                    difficultyRow(
                        difficulty,
                        locked: true
                    )
                    .opacity(0.45)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(
            haruTheme.backgroundGradient
                .ignoresSafeArea()
        )
        .navigationTitle("Theme Review")
    }

    // MARK: - Difficulty Selection

    private func difficultyRow(
        _ difficulty: HaruDifficulty,
        locked: Bool
    ) -> some View {
        HStack {
            VStack(
                alignment: .leading,
                spacing: 5
            ) {
                Text(
                    "Part \(difficulty.part) · \(difficulty.title)"
                )
                .font(.headline)

                Text(
                    locked
                        ? "Complete the previous part to unlock"
                        : "Revisit discovered vocabulary"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            if locked {
                Image(systemName: "lock.fill")
            }
        }
        .padding(.vertical, 12)
    }

    // MARK: - Themes Within Difficulty

    private func reviewList(
        for difficulty: HaruDifficulty
    ) -> some View {

        let levelWords = allWords.filter {
            $0.level == difficulty.rawValue
        }

        let grouped = Dictionary(
            grouping: levelWords,
            by: { $0.theme ?? "Uncategorized" }
        )

        return Group {
            if grouped.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(
                        grouped.keys.sorted(),
                        id: \.self
                    ) { theme in
                        if let words = grouped[theme] {
                            NavigationLink {
                                ThemeDetailView(
                                    theme: theme,
                                    words: words
                                )
                            } label: {
                                themeRow(
                                    theme: theme,
                                    words: words
                                )
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
        .background(
            haruTheme.backgroundGradient
                .ignoresSafeArea()
        )
        .navigationTitle(difficulty.title)
    }

    // MARK: - Theme Row

    private func themeRow(
        theme: String,
        words: [TopikWord]
    ) -> some View {

        let mastered = words.filter {
            store.masteryScore(for: $0) >= 3
        }.count

        return VStack(
            alignment: .leading,
            spacing: 8
        ) {
            Text(theme)
                .font(.headline)
                .foregroundStyle(haruTheme.primaryText)

            HStack(spacing: 16) {
                Label(
                    "\(words.count) discovered",
                    systemImage: "book.fill"
                )

                Label(
                    "\(mastered) mastered",
                    systemImage: "star.fill"
                )
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 10)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "books.vertical")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No Words to Review Yet")
                .font(.title3)
                .bold()

            Text(
                "Words will appear here after you discover them."
            )
            .font(.subheadline)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Theme Detail

struct ThemeDetailView: View {

    private var haruTheme: HaruTheme { HaruTheme() }

    let theme: String
    let words: [TopikWord]

    @AppStorage("haru.appearance.koreanFontSize")
    private var koreanFontSize = 60.0

    @ObservedObject private var store =
        VocabStore.shared

    @State private var isPresentingQuiz = false
    @State private var reviewQuestions: [QuizQuestion] = []

    // MARK: - Progress

    private var masteredCount: Int {
        words.filter {
            store.masteryScore(for: $0) >= 3
        }.count
    }

    private var learningCount: Int {
        words.filter {
            store.masteryScore(for: $0) < 3
        }.count
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {

            progressHeader

            List {
                Section("Vocabulary") {
                    ForEach(
                        words,
                        id: \.learningUnitID
                    ) { word in

                        NavigationLink {
                            WordReviewView(word: word)
                        } label: {
                            wordRow(word)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)

            reviewQuizButton
                .padding()
        }
        .background(
            haruTheme.backgroundGradient
                .ignoresSafeArea()
        )
        .foregroundStyle(haruTheme.primaryText)
        .navigationTitle(theme)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isPresentingQuiz) {
            NavigationStack {
                QuizView(questions: reviewQuestions)
            }
        }
    }

    // MARK: - Progress Header

    private var progressHeader: some View {
        VStack(spacing: 14) {
            Text("THEME PROGRESS")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 36) {
                VStack(spacing: 4) {
                    Text("\(words.count)")
                        .font(.title2)
                        .bold()

                    Text("Discovered")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack(spacing: 4) {
                    Text(
                        "\(masteredCount) / \(words.count)"
                    )
                    .font(.title2)
                    .bold()

                    Text("Mastered")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack(spacing: 4) {
                    Text("\(learningCount)")
                        .font(.title2)
                        .bold()

                    Text("Learning")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(haruTheme.card)
    }

    // MARK: - Word Row

    private func wordRow(
        _ word: TopikWord
    ) -> some View {

        let score = store.masteryScore(for: word)

        return HStack(spacing: 12) {
            VStack(
                alignment: .leading,
                spacing: 4
            ) {
                Text(word.hangul)
                    .font(
                        .system(
                            size: min(
                                CGFloat(koreanFontSize) * 0.4,
                                30
                            ),
                            weight: .semibold
                        )
                    )
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)

                Text(word.english)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if let partOfSpeech = word.partOfSpeech {
                    Text(partOfSpeech)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            masteryStars(score: score)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Mastery Stars

    private func masteryStars(
        score: Int
    ) -> some View {

        HStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { index in
                Image(
                    systemName: index < score
                        ? "star.fill"
                        : "star"
                )
                .font(.caption)
                .foregroundColor(
                    index < score
                        ? .orange
                        : .secondary
                )
            }
        }
    }

    // MARK: - Review Quiz Button

    @ViewBuilder
    private var reviewQuizButton: some View {

        if words.count >= 4 {
            Button {
                startReviewQuiz()
            } label: {
                HStack {
                    Image(
                        systemName: "brain.head.profile"
                    )

                    Text("Review Quiz")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(haruTheme.accent)
                .cornerRadius(14)
            }
        } else {
            VStack(spacing: 6) {
                Text("Review Quiz")
                    .font(.headline)

                Text(
                    "Discover at least 4 words in this theme to start a review quiz."
                )
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(haruTheme.card)
            .cornerRadius(14)
        }
    }

    // MARK: - Start Review Quiz

    private func startReviewQuiz() {

        let quiz = QuizGenerator.shared.generateBeginnerQuiz(
            from: words,
            theme: "\(theme) Review",
            questionCount: min(10, words.count)
        )

        reviewQuestions = quiz.questions

        guard !reviewQuestions.isEmpty else {
            return
        }

        isPresentingQuiz = true
    }
}
