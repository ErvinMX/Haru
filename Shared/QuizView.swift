
import SwiftUI

struct QuizView: View {

    @Environment(\.dismiss)
    private var dismiss

    @ObservedObject private var store = VocabStore.shared

    let questions: [QuizQuestion]

    @AppStorage("haru.appearance.koreanFontSize")
    private var koreanFontSize = 60.0

    // Keep questions unchanged while the quiz is active.
    @State private var frozenQuestions: [QuizQuestion] = []

    @State private var currentIndex = 0
    @State private var selectedOptionIndex: Int? = nil
    @State private var score = 0
    @State private var showResults = false

    private var currentQuestion: QuizQuestion? {
        guard currentIndex < frozenQuestions.count else {
            return nil
        }
        return frozenQuestions[currentIndex]
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {

                if showResults {
                    resultsView

                } else if let question = currentQuestion {

                    // MARK: - Header

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("THEME")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.secondary)

                                Text(question.theme)
                                    .font(.title3)
                                    .fontWeight(.heavy)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.8)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Text(question.questionType.rawValue)
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.12))
                                    .foregroundStyle(.blue)
                                    .clipShape(Capsule())

                                Text(
                                    "\(currentIndex + 1) of \(frozenQuestions.count)"
                                )
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                        }

                        ProgressView(
                            value: Double(currentIndex + 1),
                            total: Double(max(frozenQuestions.count, 1))
                        )
                        .tint(.blue)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)

                    // MARK: - Question

                    VStack(spacing: 8) {
                        Text(question.prompt)
                            .font(
                                .system(
                                    size: containsKorean(question.prompt)
                                        ? CGFloat(koreanFontSize)
                                        : 40,
                                    weight: .bold
                                )
                            )
                            .lineLimit(3)
                            .minimumScaleFactor(0.65)
                            .multilineTextAlignment(.center)
                            .padding(.top, 8)

                        Text(question.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(.systemGray6))
                    .clipShape(
                        RoundedRectangle(cornerRadius: 18)
                    )
                    .padding(.horizontal, 20)

                    // MARK: - Answers

                    VStack(spacing: 12) {
                        ForEach(
                            0..<question.options.count,
                            id: \.self
                        ) { index in
                            optionButton(
                                title: question.options[index],
                                index: index,
                                question: question
                            )
                        }
                    }
                    .padding(.horizontal, 20)

                    // MARK: - Feedback

                    if let selected = selectedOptionIndex {

                        VStack(alignment: .leading, spacing: 6) {
                            Text(
                                selected == question.correctAnswerIndex
                                    ? "Correct!"
                                    : "Not quite"
                            )
                            .font(.headline)
                            .foregroundStyle(
                                selected == question.correctAnswerIndex
                                    ? Color.green
                                    : Color.red
                            )

                            Text(question.explanation)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .frame(
                            maxWidth: .infinity,
                            alignment: .leading
                        )
                        .padding()
                        .background(Color(.systemBackground))
                        .clipShape(
                            RoundedRectangle(cornerRadius: 12)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    Color(.systemGray4),
                                    lineWidth: 1
                                )
                        }
                        .padding(.horizontal, 20)

                        Spacer()

                        Button {
                            nextQuestion()
                        } label: {
                            Text(
                                currentIndex + 1 < frozenQuestions.count
                                    ? "Next Question"
                                    : "Finish Quiz"
                            )
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .clipShape(
                                RoundedRectangle(cornerRadius: 14)
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)

                    } else {
                        Spacer()
                    }
                }
            }
            .navigationTitle("Practice Quiz")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            if frozenQuestions.isEmpty {
                frozenQuestions = questions
            }
        }
    }

    // MARK: - Korean Text Detection

    private func containsKorean(_ text: String) -> Bool {
        text.unicodeScalars.contains { scalar in
            (0xAC00...0xD7A3).contains(scalar.value)
        }
    }

    // MARK: - Option Button

    private func optionButton(
        title: String,
        index: Int,
        question: QuizQuestion
    ) -> some View {

        Button {
            handleAnswerSelected(
                index: index,
                question: question
            )
        } label: {
            HStack {
                Text(title)
                    .font(.title3)
                    .bold()
                    .lineLimit(3)
                    .minimumScaleFactor(0.8)

                Spacer()

                if let selected = selectedOptionIndex {
                    if index == question.correctAnswerIndex {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)

                    } else if index == selected {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                buttonBackgroundColor(
                    for: index,
                    question: question
                )
            )
            .foregroundStyle(.primary)
            .clipShape(
                RoundedRectangle(cornerRadius: 14)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        buttonBorderColor(
                            for: index,
                            question: question
                        ),
                        lineWidth: 1.5
                    )
            }
        }
        .disabled(selectedOptionIndex != nil)
    }

    // MARK: - Answer Handling

    private func handleAnswerSelected(
        index: Int,
        question: QuizQuestion
    ) {
        guard selectedOptionIndex == nil else {
            return
        }

        selectedOptionIndex = index

        let isCorrect =
            index == question.correctAnswerIndex

        if isCorrect {
            score += 1
        }

        guard let learningUnitID =
            question.targetLearningUnitID else {
            return
        }

        // The updated VocabStore no longer has
        // updateMastery(forLearningUnitID:isCorrect:).
        //
        // Update the published mastery dictionary
        // directly, then persist it using the new
        // vocabulary progress key.

        let currentMastery =
            store.masteryScores[learningUnitID] ?? 0

        let newMastery: Int

        if isCorrect {
            newMastery = min(currentMastery + 1, 3)
        } else {
            newMastery = max(currentMastery - 1, 0)
        }

        store.masteryScores[learningUnitID] = newMastery

        UserDefaults.standard.set(
            store.masteryScores,
            forKey: "haru_v3_mastery_scores"
        )
    }

    // MARK: - Next Question

    private func nextQuestion() {
        if currentIndex + 1 < frozenQuestions.count {
            currentIndex += 1
            selectedOptionIndex = nil
        } else {
            showResults = true
        }
    }

    // MARK: - Button Colours

    private func buttonBackgroundColor(
        for index: Int,
        question: QuizQuestion
    ) -> Color {

        guard let selected = selectedOptionIndex else {
            return Color(.systemGray6)
        }

        if index == question.correctAnswerIndex {
            return Color.green.opacity(0.15)
        }

        if index == selected {
            return Color.red.opacity(0.15)
        }

        return Color(.systemGray6)
    }

    private func buttonBorderColor(
        for index: Int,
        question: QuizQuestion
    ) -> Color {

        guard let selected = selectedOptionIndex else {
            return .clear
        }

        if index == question.correctAnswerIndex {
            return .green
        }

        if index == selected {
            return .red
        }

        return .clear
    }

    // MARK: - Results

    private var resultsView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(
                systemName:
                    score >= frozenQuestions.count / 2
                    ? "star.circle.fill"
                    : "book.circle.fill"
            )
            .font(.system(size: 72))
            .foregroundStyle(.blue)

            Text("Practice Complete!")
                .font(.largeTitle)
                .bold()

            Text(
                "Score: \(score) / \(frozenQuestions.count)"
            )
            .font(.title2)
            .foregroundStyle(.secondary)

            Text(
                "Your vocabulary mastery has been updated."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("Back to Haru")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 14)
                    )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
    }
}
