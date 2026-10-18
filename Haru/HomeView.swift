
import SwiftUI

struct HomeView: View {

    @ObservedObject private var store = VocabStore.shared

    // Freeze quiz questions before opening QuizView.
    @State private var activePracticeQuestions: [QuizQuestion] = []
    @State private var showingPracticeQuiz = false

    let databaseWords: [TopikWord]
    let isLoading: Bool
    let setupError: String?

    // Kept for compatibility with ContentView.
    let onChooseTheme: () -> Void

    private var theme: HaruTheme {
        HaruTheme()
    }

    @AppStorage("haru.currentDifficultyIndex")
    private var currentDifficultyIndex = 0

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {

            theme.backgroundGradient
                .ignoresSafeArea()

            // Time-based background artwork
            Image(theme.backgroundImageName)
                .resizable()
                .scaledToFill()
                .frame(height: 390)
                .clipped()
                .opacity(
                    theme.period == .night ? 0.48 : 0.38
                )
                .ignoresSafeArea(edges: .top)

            // Artwork fade
            LinearGradient(
                colors: [
                    theme.background.opacity(0.05),
                    theme.background.opacity(0.22),
                    theme.background.opacity(0.68),
                    theme.background
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 410)
            .ignoresSafeArea(edges: .top)
            .allowsHitTesting(false)

            ScrollView {
                VStack(spacing: 20) {

                    header

                    Spacer()
                        .frame(height: 85)

                    if isLoading {
                        loadingView
                    } else if let setupError {
                        errorView(setupError)
                    } else {

                        if let currentTheme = store.currentTheme {
                            continueLearningCard(
                                currentTheme: currentTheme
                            )
                        } else {
                            firstThemeLoadingCard
                        }

                        practiceCard

                        journeyCard

                        learningInsightsPreview
                    }

                    Spacer(minLength: 30)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
        }
        .foregroundStyle(theme.primaryText)
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $showingPracticeQuiz) {
            QuizView(questions: activePracticeQuestions)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 18) {

            HStack {
                Text("Haru")
                    .font(
                        .system(
                            size: 36,
                            weight: .bold,
                            design: .serif
                        )
                    )

                Spacer()

                NavigationLink {
                    SettingsView()
                } label: {
                    Image(systemName: "gearshape")
                        .font(
                            .system(
                                size: 19,
                                weight: .medium
                            )
                        )
                        .frame(width: 42, height: 42)
                        .background(
                            theme.card.opacity(0.75)
                        )
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Settings")
            }

            VStack(
                alignment: .leading,
                spacing: 4
            ) {
                Text(
                    "PART \(currentDifficultyIndex + 1) · \(Curriculum.currentDifficulty.title.uppercased())"
                )
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.accent)

                Text(theme.koreanGreeting)
                    .font(
                        .system(
                            size: 24,
                            weight: .semibold,
                            design: .serif
                        )
                    )

                Text(theme.englishGreeting)
                    .font(.subheadline)
                    .foregroundStyle(
                        theme.secondaryText
                    )
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Continue Learning

    private func continueLearningCard(
        currentTheme: String
    ) -> some View {

        let progress = themeProgress(
            for: currentTheme
        )

        let progressValue: Double =
            progress.total == 0
            ? 0
            : Double(progress.discovered)
                / Double(progress.total)

        let isComplete =
            progress.total > 0 &&
            progress.discovered == progress.total

        return VStack(
            alignment: .leading,
            spacing: 16
        ) {

            HStack(alignment: .top) {
                VStack(
                    alignment: .leading,
                    spacing: 5
                ) {

                    Text("CURRENT JOURNEY STAGE")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .tracking(0.8)
                        .foregroundStyle(
                            theme.secondaryText
                        )

                    Text(
                        themeDisplayName(currentTheme)
                    )
                    .font(
                        .system(
                            size: 25,
                            weight: .bold,
                            design: .serif
                        )
                    )

                    if let domain = themeDomain(
                        currentTheme
                    ) {
                        Text(domain)
                            .font(.subheadline)
                            .foregroundStyle(
                                theme.secondaryText
                            )
                    }
                }

                Spacer()

                Image(
                    systemName: isComplete
                        ? "checkmark.circle.fill"
                        : "book.closed.fill"
                )
                .font(.system(size: 25))
                .foregroundStyle(
                    theme.accent.opacity(0.85)
                )
            }

            VStack(
                alignment: .leading,
                spacing: 8
            ) {

                HStack {
                    Text(
                        "\(progress.discovered) of \(progress.total) words discovered"
                    )
                    .font(.subheadline)
                    .foregroundStyle(
                        theme.secondaryText
                    )

                    Spacer()

                    Text(
                        "\(Int((progressValue * 100).rounded()))%"
                    )
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(
                        theme.secondaryText
                    )
                }

                ProgressView(
                    value: progressValue
                )
                .tint(theme.accent)
            }

            if isComplete {
                Label(
                    "All words discovered!",
                    systemImage:
                        "checkmark.circle.fill"
                )
                .font(.subheadline)
                .foregroundStyle(theme.accent)

                Text(
                    "Visit Journey to reveal your next stage."
                )
                .font(.subheadline)
                .foregroundStyle(
                    theme.secondaryText
                )

                NavigationLink {
                    JourneyView(
                        databaseWords: databaseWords
                    )
                } label: {
                    actionButtonLabel(
                        "View Journey"
                    )
                }
                .buttonStyle(.plain)

            } else {
                NavigationLink {
                    LearningView(
                        theme: currentTheme,
                        words: Curriculum.words(
                            in: currentTheme,
                            from: databaseWords
                        )
                    )
                } label: {
                    actionButtonLabel(
                        progress.discovered == 0
                            ? "Start Learning"
                            : "Continue"
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .background(theme.card)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 22
            )
        )
    }

    private func actionButtonLabel(
        _ title: String
    ) -> some View {
        HStack {
            Text(title)
                .fontWeight(.semibold)

            Spacer()

            Image(
                systemName: "arrow.right"
            )
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 18)
        .frame(height: 50)
        .background(theme.accent)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 14
            )
        )
    }
    
    // MARK: - Initial Theme

    private var firstThemeLoadingCard: some View {
        VStack(alignment: .leading, spacing: 14) {

            Image(systemName: "book.closed.fill")
                .font(.title2)
                .foregroundStyle(theme.accent)

            Text("Preparing your journey")
                .font(
                    .system(
                        size: 24,
                        weight: .bold,
                        design: .serif
                    )
                )

            Text(
                "Haru is preparing your first vocabulary theme."
            )
            .font(.subheadline)
            .foregroundStyle(theme.secondaryText)

            ProgressView()
                .tint(theme.accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(theme.card)
        .clipShape(
            RoundedRectangle(cornerRadius: 22)
        )
    }

    // MARK: - Practice

    private var practiceCard: some View {
        VStack(alignment: .leading, spacing: 14) {

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("PRACTICE")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .tracking(0.8)
                        .foregroundStyle(theme.secondaryText)

                    Text("Practice Quiz")
                        .font(
                            .system(
                                size: 22,
                                weight: .bold,
                                design: .serif
                            )
                        )
                }

                Spacer()

                Image(
                    systemName: store.isPracticeQuizUnlocked
                        ? "brain.head.profile"
                        : "lock.fill"
                )
                .font(.title2)
                .foregroundStyle(
                    store.isPracticeQuizUnlocked
                        ? theme.secondaryAccent
                        : theme.secondaryText
                )
            }

            if !store.isPracticeQuizUnlocked {

                Text(
                    "Discover \(max(0, 10 - introducedWords.count)) more words to unlock Practice."
                )
                .font(.subheadline)
                .foregroundStyle(theme.secondaryText)

                ProgressView(
                    value: Double(min(introducedWords.count, 10)),
                    total: 10
                )
                .tint(theme.secondaryAccent)

            } else if introducedWords.count < 4 {

                Text(
                    "Keep learning a few more words before starting a quiz."
                )
                .font(.subheadline)
                .foregroundStyle(theme.secondaryText)

            } else {

                HStack {
                    VStack(alignment: .leading, spacing: 3) {

                        Text(
                            "\(introducedWords.count) words available for practice"
                        )
                        .font(.subheadline)
                        .foregroundStyle(theme.secondaryText)

                        if practiceWords.isEmpty {
                            Text("All discovered words mastered. Keep them fresh!")
                                .font(.caption)
                                .foregroundStyle(theme.secondaryText)
                        } else if almostMasteredCount > 0 {
                            Text(
                                "\(almostMasteredCount) close to mastery"
                            )
                            .font(.caption)
                            .foregroundStyle(theme.secondaryText)
                        }
                    }

                    Spacer()

                    Button {
                        startPracticeQuiz()
                    } label: {
                        HStack(spacing: 7) {
                            Text("Start Quiz")
                            Image(systemName: "arrow.right")
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(theme.primaryText)
                        .padding(.horizontal, 14)
                        .frame(height: 42)
                        .background(
                            theme.secondaryAccent.opacity(0.18)
                        )
                        .clipShape(
                            RoundedRectangle(cornerRadius: 12)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(20)
        .background(theme.card)
        .clipShape(
            RoundedRectangle(cornerRadius: 22)
        )
    }

    // MARK: - Start Practice Quiz

    private func startPracticeQuiz() {
        let quiz = QuizGenerator.shared.generatePracticeQuiz(
            from: introducedWords,
            store: store,
            questionCount: 10
        )

        guard !quiz.questions.isEmpty else { return }
        activePracticeQuestions = quiz.questions
        showingPracticeQuiz = true
    }

    // MARK: - Learning Insights (V2 Preview)

    private var learningInsightsPreview: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 21))
                .foregroundStyle(theme.secondaryText)
                .frame(width: 44, height: 44)
                .background(theme.secondaryAccent.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("Learning Insights")
                        .font(.system(size: 20, weight: .bold, design: .serif))

                    Spacer(minLength: 4)

                    Text("COMING IN V2")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(0.5)
                        .foregroundStyle(theme.secondaryText)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(theme.secondaryAccent.opacity(0.12))
                        .clipShape(Capsule())
                }

                Text("See how your vocabulary, quiz accuracy, and confidence grow over time.")
                    .font(.subheadline)
                    .foregroundStyle(theme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)

                Label("A little progress is still progress.", systemImage: "lock")
                    .font(.caption)
                    .foregroundStyle(theme.secondaryText)
                    .padding(.top, 3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(theme.card.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .accessibilityElement(children: .combine)
    }
    
    // MARK: - Journey

    private var journeyCard: some View {
        NavigationLink {
            TopikProgressView(
                allWords: databaseWords.filter {
                    $0.level == Curriculum.currentDifficulty.rawValue
                }
            )
        } label: {
            VStack(alignment: .leading, spacing: 14) {

                HStack {
                    VStack(alignment: .leading, spacing: 4) {

                        Text("YOUR JOURNEY")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .tracking(0.8)
                            .foregroundStyle(theme.secondaryText)

                        Text(
                            "Part \(currentDifficultyIndex + 1) · \(Curriculum.currentDifficulty.title)"
                        )
                        .font(
                            .system(
                                size: 22,
                                weight: .bold,
                                design: .serif
                            )
                        )
                    }

                    Spacer()

                    Image(systemName: "map.fill")
                        .font(.title2)
                        .foregroundStyle(theme.journeyAccent)
                }

                journeyPath

                HStack {
                    Text(
                        "\(overallPercentage)% of vocabulary discovered"
                    )
                    .font(.subheadline)
                    .foregroundStyle(theme.secondaryText)

                    Spacer()

                    Image(systemName: "arrow.right")
                        .foregroundStyle(theme.journeyAccent)
                }
            }
            .padding(20)
            .background(theme.card)
            .clipShape(
                RoundedRectangle(cornerRadius: 22)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Journey Preview

    private var journeyPath: some View {
        GeometryReader { geometry in
            ZStack {
                Capsule()
                    .fill(
                        theme.journeyAccent.opacity(0.18)
                    )
                    .frame(height: 3)

                HStack {
                    journeyDot(
                        filled: overallPercentage > 0
                    )

                    Spacer()

                    journeyDot(
                        filled: overallPercentage >= 25
                    )

                    Spacer()

                    journeyDot(
                        filled: overallPercentage >= 50
                    )

                    Spacer()

                    journeyDot(
                        filled: overallPercentage >= 75
                    )

                    Spacer()

                    journeyDot(
                        filled: overallPercentage >= 100
                    )
                }
                .frame(width: geometry.size.width)
            }
        }
        .frame(height: 22)
    }

    private func journeyDot(
        filled: Bool
    ) -> some View {
        Circle()
            .fill(
                filled
                    ? theme.journeyAccent
                    : theme.card
            )
            .overlay {
                Circle()
                    .stroke(
                        theme.journeyAccent,
                        lineWidth: 2
                    )
            }
            .frame(width: 14, height: 14)
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 14) {
            ProgressView()
                .tint(theme.accent)

            Text("Loading vocabulary...")
                .font(.subheadline)
                .foregroundStyle(theme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 50)
    }

    // MARK: - Error

    private func errorView(
        _ message: String
    ) -> some View {
        VStack(spacing: 12) {
            Image(
                systemName: "exclamationmark.triangle"
            )
            .font(.title2)
            .foregroundStyle(theme.accent)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(theme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(theme.card)
        .clipShape(
            RoundedRectangle(cornerRadius: 22)
        )
    }

    // MARK: - Data Helpers

    private var introducedWords: [TopikWord] {
        databaseWords.filter {
            store.hasIntroduced($0)
        }
    }

    private var practiceWords: [TopikWord] {
        introducedWords.filter {
            store.masteryScore(for: $0) < 3
        }
    }

    private var almostMasteredCount: Int {
        practiceWords.filter {
            store.masteryScore(for: $0) == 2
        }.count
    }

    private var overallPercentage: Int {
        let levelWords = databaseWords.filter {
            $0.level == Curriculum.currentDifficulty.rawValue
        }

        guard !levelWords.isEmpty else {
            return 0
        }

        let discovered = levelWords.filter {
            store.hasIntroduced($0)
        }.count

        let progress =
            Double(discovered)
            / Double(levelWords.count)

        return Int((progress * 100).rounded())
    }

    private func themeProgress(
        for themeName: String
    ) -> (
        discovered: Int,
        mastered: Int,
        total: Int
    ) {
        let words = Curriculum.words(
            in: themeName,
            from: databaseWords
        )

        let discovered = words.filter {
            store.hasIntroduced($0)
        }.count

        let mastered = words.filter {
            store.masteryScore(for: $0) >= 3
        }.count

        return (
            discovered,
            mastered,
            words.count
        )
    }

    private func themeDisplayName(
        _ fullTheme: String
    ) -> String {
        guard let separator = fullTheme.firstIndex(
            of: ":"
        ) else {
            return fullTheme
        }

        let afterSeparator = fullTheme[
            fullTheme.index(after: separator)...
        ]

        return afterSeparator.trimmingCharacters(
            in: .whitespaces
        )
    }

    private func themeDomain(
        _ fullTheme: String
    ) -> String? {
        guard let separator = fullTheme.firstIndex(
            of: ":"
        ) else {
            return nil
        }

        return String(
            fullTheme[..<separator]
        )
        .trimmingCharacters(in: .whitespaces)
    }
}
