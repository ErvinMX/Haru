
import SwiftUI

struct LearningView: View {

    let theme: String
    let words: [TopikWord]

    @ObservedObject private var store = VocabStore.shared

    @Environment(\.dismiss)
    private var dismiss

    @AppStorage("haru.audio.pronunciationEnabled")
    private var pronunciationEnabled = true

    @AppStorage("haru.audio.autoPlayEnabled")
    private var autoPlayEnabled = false

    @AppStorage("haru.appearance.koreanFontSize")
    private var koreanFontSize = 60.0

    // Shared navigation request with ContentView.
    @AppStorage("haru.navigation.journeyRequest")
    private var journeyRequest = 0

    @AppStorage("haru.journey.sequentialUnlockedIndex")
    private var journeyUnlockedIndex = 0

    @State private var currentWord: TopikWord?
    @State private var answerOptions: [String] = []
    @State private var selectedAnswer: String?
    @State private var hasAnswered = false
    @State private var wasCorrect = false
    @State private var showCompletionAnimation = false

    // MARK: - Text Size

    private var answerFontSize: CGFloat {
        17
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

            Text(theme)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            if let word = currentWord {
                learningContent(for: word)
            } else {
                themeCompleteContent
            }
        }
            .padding(24)
            .frame(maxWidth: .infinity, minHeight: 620)
        }
        .navigationTitle("Learn")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadCurrentWord()
        }
    }

    // MARK: - Learning Content

    @ViewBuilder
    private func learningContent(
        for word: TopikWord
    ) -> some View {

        VStack(spacing: 10) {
            Text("Guess the meaning")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Text(word.hangul)
                    .font(
                        .system(
                            size: koreanFontSize,
                            weight: .bold
                        )
                    )
                    .lineLimit(2)
                    .minimumScaleFactor(0.65)
                    .multilineTextAlignment(.center)

                Button {
                    SpeechManager.shared.speakKorean(
                        word.hangul
                    )
                } label: {
                    Image(
                        systemName: "speaker.wave.2.fill"
                    )
                    .font(.title2)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.blue)
                .disabled(!pronunciationEnabled)
                .opacity(pronunciationEnabled ? 1 : 0.4)
                .accessibilityLabel(
                    "Hear pronunciation"
                )
            }

                if let korean = word.exampleKo?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !korean.isEmpty {
                    VStack(spacing: 8) {
                        Text("EXAMPLE SENTENCE")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 12) {
                            Text(korean)
                                .font(.body)
                                .fontWeight(.medium)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)

                            Button {
                                SpeechManager.shared.speakKorean(korean)
                            } label: {
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.title3)
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.blue)
                            .disabled(!pronunciationEnabled)
                            .opacity(pronunciationEnabled ? 1 : 0.4)
                            .accessibilityLabel("Hear example sentence")
                        }

                        if hasAnswered,
                           let english = word.exampleEn?.trimmingCharacters(in: .whitespacesAndNewlines),
                           !english.isEmpty {
                            Text(english)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(Color.gray.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.top, 8)
                }
        }

        Spacer(minLength: 8)

        VStack(spacing: 12) {
            ForEach(answerOptions, id: \.self) { option in
                Button {
                    selectAnswer(
                        option,
                        for: word
                    )
                } label: {
                    HStack {
                        Text(option)
                            .font(
                                .system(
                                    size: answerFontSize,
                                    weight: .semibold
                                )
                            )

                        Spacer()

                        if hasAnswered {
                            if option == word.english {
                                Image(
                                    systemName:
                                        "checkmark.circle.fill"
                                )
                                .foregroundStyle(.green)
                            } else if option == selectedAnswer {
                                Image(
                                    systemName:
                                        "xmark.circle.fill"
                                )
                                .foregroundStyle(.red)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        backgroundColor(
                            for: option,
                            correctAnswer: word.english
                        )
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 14
                        )
                    )
                }
                .buttonStyle(.plain)
                .disabled(hasAnswered)
            }
        }

        if hasAnswered {
            VStack(spacing: 8) {
                Text(
                    wasCorrect
                        ? "Correct!"
                        : "Not quite"
                )
                .font(.title3)
                .bold()
                .foregroundStyle(
                    wasCorrect
                        ? .green
                        : .red
                )

                if !wasCorrect {
                    Text(
                        "\(word.hangul) means \"\(word.english)\"."
                    )
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                }

                if let partOfSpeech = word.partOfSpeech {
                    Text(partOfSpeech)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }


            }
            .padding(.top, 6)

            Button {
                showNextWord()
            } label: {
                Text("Next Word")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 14
                        )
                    )
            }
            .padding(.top, 6)
        }
    }

    // MARK: - Theme Complete

    private var themeCompleteContent: some View {
        VStack(spacing: 20) {

            Image(
                systemName: "checkmark.circle.fill"
            )
            .font(.system(size: 52))
            .foregroundStyle(.green)
            .scaleEffect(
                showCompletionAnimation ? 1 : 0.7
            )
            .opacity(
                showCompletionAnimation ? 1 : 0
            )
            .animation(
                .spring(
                    response: 0.65,
                    dampingFraction: 0.8
                ),
                value: showCompletionAnimation
            )
            .onAppear {
                showCompletionAnimation = true
            }

            VStack(spacing: 8) {
                Text("Theme Discovered!")
                    .font(.title2)
                    .bold()

                Text(
                    "You've encountered every word in this theme."
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

                Text(
                    "A new part of your journey awaits."
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            }

            // MARK: - Progress

            VStack(spacing: 12) {
                HStack {
                    Text("Discovered")

                    Spacer()

                    Text(
                        "\(discoveredCount) / \(words.count)"
                    )
                    .bold()
                }

                HStack {
                    Text("Mastered")

                    Spacer()

                    Text("\(masteredCount)")
                        .bold()
                }

                HStack {
                    Text("Still Learning")

                    Spacer()

                    Text("\(learningCount)")
                        .bold()
                }
            }
            .padding()
            .background(
                Color.gray.opacity(0.10)
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 16
                )
            )

            // MARK: - Theme Practice

            if themePracticeQuiz.questions.isEmpty {
                Text(
                    masteredCount == words.count
                        ? "You've mastered every word in this theme."
                        : "You can revisit these words in Practice whenever you like."
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            } else {
                NavigationLink {
                    QuizView(
                        questions:
                            themePracticeQuiz.questions
                    )
                } label: {
                    Text("Practice This Theme")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 14
                            )
                        )
                }
            }

            // MARK: - Continue to Journey

            Button {
                dismiss()

                // ContentView observes this value and
                // switches to the Journey tab.
                journeyRequest += 1

            } label: {
                HStack(spacing: 8) {
                    Text("Continue to Journey")

                    Image(
                        systemName: "arrow.right"
                    )
                }
                .font(.headline)
                .foregroundStyle(.blue)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    Color.blue.opacity(0.12)
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 14
                    )
                )
            }
        }
    }

    // MARK: - Theme Progress

    private var discoveredWords: [TopikWord] {
        words.filter {
            store.hasIntroduced($0)
        }
    }

    private var discoveredCount: Int {
        discoveredWords.count
    }

    private var masteredCount: Int {
        discoveredWords.filter {
            store.masteryScore(for: $0) >= 3
        }.count
    }

    private var learningCount: Int {
        discoveredWords.filter {
            store.masteryScore(for: $0) < 3
        }.count
    }

    // MARK: - Theme Practice Quiz

    private var themePracticeQuiz: Quiz {
        QuizGenerator.shared.generatePracticeQuiz(
            from: discoveredWords,
            store: store,
            questionCount: 10
        )
    }

    // MARK: - Load Current Word

    private func loadCurrentWord() {
        let unseenWords = words.filter {
            !store.hasIntroduced($0)
        }

        guard let nextWord = unseenWords.first else {
            showCompletionAnimation = false
            currentWord = nil
            answerOptions = []
            return
        }

        currentWord = nextWord
        prepareAnswers(for: nextWord)

        // Only play automatically when both
        // pronunciation and auto-play are enabled.
        if pronunciationEnabled && autoPlayEnabled {
            SpeechManager.shared.speakKorean(
                nextWord.hangul
            )
        }
    }

    // MARK: - Prepare Answers

    private func prepareAnswers(
        for word: TopikWord
    ) {
        let distractors = words
            .filter {
                $0.learningUnitID != word.learningUnitID
            }
            .map {
                $0.english
            }
            .filter {
                $0 != word.english
            }
            .shuffled()

        let uniqueDistractors = Array(
            Set(distractors)
        )
        .shuffled()

        let selectedDistractors = Array(
            uniqueDistractors.prefix(3)
        )

        answerOptions = (
            [word.english] + selectedDistractors
        )
        .shuffled()

        selectedAnswer = nil
        hasAnswered = false
        wasCorrect = false
    }

    // MARK: - Select Answer

    private func selectAnswer(
        _ answer: String,
        for word: TopikWord
    ) {
        guard !hasAnswered else {
            return
        }

        selectedAnswer = answer
        wasCorrect = answer == word.english
        hasAnswered = true

        // First exposure only.
        // Learning does not change mastery.
        store.markIntroduced(word)
    }

    // MARK: - Next Word

    private func showNextWord() {
        loadCurrentWord()
    }

    // MARK: - Answer Colour

    private func backgroundColor(
        for option: String,
        correctAnswer: String
    ) -> Color {
        guard hasAnswered else {
            return Color.gray.opacity(0.12)
        }

        if option == correctAnswer {
            return Color.green.opacity(0.18)
        }

        if option == selectedAnswer {
            return Color.red.opacity(0.18)
        }

        return Color.gray.opacity(0.08)
    }
}
