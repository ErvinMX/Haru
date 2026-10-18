
import SwiftUI

// MARK: - Learn Tab

struct LearnView: View {
    @ObservedObject private var store = VocabStore.shared

    let databaseWords: [TopikWord]
    let isLoading: Bool
    let setupError: String?

    private var theme: HaruTheme {
        HaruTheme()
    }

    // MARK: - Discovered Vocabulary

    private var discoveredWords: [TopikWord] {
        databaseWords.filter {
            store.hasIntroduced($0)
        }
    }

    private var discoveredThemeCount: Int {
        Set(
            discoveredWords.map {
                "\($0.level):\($0.theme ?? "")"
            }
        ).count
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            theme.backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(
                    alignment: .leading,
                    spacing: 20
                ) {
                    header

                    if isLoading {
                        ProgressView("Loading vocabulary...")
                            .tint(theme.accent)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 50)

                    } else if let setupError {
                        Text(setupError)
                            .font(.subheadline)
                            .foregroundStyle(theme.secondaryText)
                            .frame(maxWidth: .infinity)
                            .padding(24)
                            .background(theme.card)
                            .clipShape(
                                RoundedRectangle(cornerRadius: 22)
                            )

                    } else {
                        themeReviewCard
                        languageChallengeCard
                    }

                    Spacer(minLength: 30)
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
            }
        }
        .foregroundStyle(theme.primaryText)
        .navigationBarHidden(true)
    }

    // MARK: - Header

    private var header: some View {
        VStack(
            alignment: .leading,
            spacing: 5
        ) {
            Text("Learn")
                .font(
                    .system(
                        size: 34,
                        weight: .bold,
                        design: .serif
                    )
                )

            Text("Revisit the Korean you've discovered.")
                .font(.subheadline)
                .foregroundStyle(theme.secondaryText)
        }
    }

    // MARK: - Theme Review

    private var themeReviewCard: some View {
        NavigationLink {
            ThemeLibraryView(
                allWords: discoveredWords
            )
        } label: {
            VStack(
                alignment: .leading,
                spacing: 14
            ) {
                HStack {
                    Image(
                        systemName: "books.vertical.fill"
                    )
                    .font(.title2)
                    .foregroundStyle(theme.journeyAccent)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(theme.secondaryText)
                }

                Text("Theme Review")
                    .font(
                        .system(
                            size: 24,
                            weight: .bold,
                            design: .serif
                        )
                    )

                Text(
                    "Choose a theme to revisit its vocabulary or take a theme-only quiz."
                )
                .font(.subheadline)
                .foregroundStyle(theme.secondaryText)

                HStack(spacing: 16) {
                    Label(
                        "\(discoveredThemeCount) themes started",
                        systemImage: "square.grid.2x2"
                    )

                    Label(
                        "\(discoveredWords.count) words",
                        systemImage: "book.closed"
                    )
                }
                .font(.caption)
                .foregroundStyle(theme.secondaryText)

                HStack {
                    Text("Browse themes")
                        .font(
                            .subheadline.weight(.semibold)
                        )

                    Spacer()

                    Image(systemName: "arrow.right")
                }
                .foregroundStyle(theme.journeyAccent)
                .padding(.top, 3)
            }
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
            .padding(20)
            .background(theme.card)
            .clipShape(
                RoundedRectangle(cornerRadius: 22)
            )
        }
        .buttonStyle(.plain)
        .disabled(discoveredWords.isEmpty)
        .opacity(
            discoveredWords.isEmpty ? 0.65 : 1
        )
    }

    // MARK: - Language Challenge (V2)

    private var languageChallengeCard: some View {
        VStack(
            alignment: .leading,
            spacing: 14
        ) {
            HStack {
                Image(
                    systemName: "text.book.closed.fill"
                )
                .font(.title2)
                .foregroundStyle(theme.secondaryAccent)

                Spacer()

                Label(
                    "Coming in V2",
                    systemImage: "lock.fill"
                )
                .font(.caption)
                .foregroundStyle(theme.secondaryText)
            }

            Text("Language Challenge")
                .font(
                    .system(
                        size: 24,
                        weight: .bold,
                        design: .serif
                    )
                )

            Text(
                "Explore vocabulary, grammar, sentence completion and reading in a future challenge."
            )
            .font(.subheadline)
            .foregroundStyle(theme.secondaryText)
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding(20)
        .background(
            theme.card.opacity(0.75)
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 22)
        )
        .opacity(0.8)
        .accessibilityElement(children: .combine)
    }
}
