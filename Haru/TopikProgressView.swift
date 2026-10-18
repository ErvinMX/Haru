
import SwiftUI

struct TopikProgressView: View {

    let allWords: [TopikWord]

    @ObservedObject private var store = VocabStore.shared

    // MARK: - Current Difficulty

    private var levelWords: [TopikWord] {
        allWords.filter {
            $0.level == Curriculum.currentDifficulty.rawValue
        }
    }

    private var availableThemes: [SubTheme] {
        Curriculum.themes(with: levelWords)
    }

    // MARK: - Domains

    private var domains: [String] {
        var result: [String] = []

        for subTheme in availableThemes {
            if !result.contains(subTheme.domain) {
                result.append(subTheme.domain)
            }
        }

        return result
    }

    // MARK: - Overall Progress

    private var discoveredWords: [TopikWord] {
        levelWords.filter {
            store.hasIntroduced($0)
        }
    }

    private var masteredWords: [TopikWord] {
        discoveredWords.filter {
            store.masteryScore(for: $0) >= 3
        }
    }

    private var overallProgress: Double {
        guard !levelWords.isEmpty else {
            return 0
        }

        return Double(discoveredWords.count)
            / Double(levelWords.count)
    }

    private var overallPercentageText: String {
        let percentage = overallProgress * 100

        if percentage > 0 && percentage < 10 {
            return String(
                format: "%.1f%%",
                percentage
            )
        }

        return String(
            format: "%.0f%%",
            percentage
        )
    }

    private var completedThemeCount: Int {
        availableThemes.filter { subTheme in
            let words = Curriculum.words(
                in: subTheme.title,
                from: levelWords
            )

            return !words.isEmpty &&
                words.allSatisfy {
                    store.hasIntroduced($0)
                }
        }.count
    }

    private var totalThemeCount: Int {
        availableThemes.count
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: 24
            ) {
                overallCard

                ForEach(domains, id: \.self) { domain in
                    domainSection(domain: domain)
                }
            }
            .padding(.vertical, 16)
        }
        .navigationTitle(
            "\(Curriculum.currentDifficulty.title) Progress"
        )
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Overall Card

    private var overallCard: some View {
        let isComplete =
            !levelWords.isEmpty &&
            discoveredWords.count == levelWords.count

        return VStack(
            alignment: .leading,
            spacing: 16
        ) {
            HStack {
                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {
                    Text("OVERALL")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(
                        isComplete
                            ? "\(Curriculum.currentDifficulty.title) Complete"
                            : "\(overallPercentageText) Discovered"
                    )
                    .font(.title2)
                    .bold()
                }

                Spacer()

                Image(
                    systemName: isComplete
                        ? "checkmark.seal.fill"
                        : "chart.bar.fill"
                )
                .font(.title2)
                .foregroundStyle(
                    isComplete ? Color.green : Color.blue
                )
            }

            ProgressView(
                value: Double(discoveredWords.count),
                total: Double(max(levelWords.count, 1))
            )

            HStack {
                progressStat(
                    value: "\(discoveredWords.count) / \(levelWords.count)",
                    label: "Discovered"
                )

                Spacer()

                progressStat(
                    value: "\(masteredWords.count)",
                    label: "Mastered"
                )

                Spacer()

                progressStat(
                    value: "\(completedThemeCount) / \(totalThemeCount)",
                    label: "Themes"
                )
            }
        }
        .padding(20)
        .background(Color.gray.opacity(0.12))
        .clipShape(
            RoundedRectangle(cornerRadius: 18)
        )
        .padding(.horizontal, 20)
    }

    // MARK: - Domain Section

    @ViewBuilder
    private func domainSection(
        domain: String
    ) -> some View {
        let subThemes = availableThemes.filter {
            $0.domain == domain
        }

        if !subThemes.isEmpty {
            VStack(
                alignment: .leading,
                spacing: 12
            ) {
                Text(domain)
                    .font(.title3)
                    .bold()
                    .padding(.horizontal, 20)

                VStack(spacing: 0) {
                    ForEach(
                        Array(subThemes.enumerated()),
                        id: \.element
                    ) { index, subTheme in
                        NavigationLink {
                            TopikThemeProgressView(
                                subTheme: subTheme,
                                allWords: levelWords
                            )
                        } label: {
                            themeRow(subTheme: subTheme)
                        }
                        .buttonStyle(.plain)

                        if index < subThemes.count - 1 {
                            Divider()
                                .padding(.leading, 16)
                        }
                    }
                }
                .background(Color.gray.opacity(0.08))
                .clipShape(
                    RoundedRectangle(cornerRadius: 16)
                )
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Theme Row

    private func themeRow(
        subTheme: SubTheme
    ) -> some View {
        let words = Curriculum.words(
            in: subTheme.title,
            from: levelWords
        )

        let discovered = words.filter {
            store.hasIntroduced($0)
        }.count

        let mastered = words.filter {
            store.masteryScore(for: $0) >= 3
        }.count

        let progress = words.isEmpty
            ? 0.0
            : Double(discovered) / Double(words.count)

        let complete =
            !words.isEmpty &&
            discovered == words.count

        return VStack(
            alignment: .leading,
            spacing: 9
        ) {
            HStack(alignment: .center) {
                VStack(
                    alignment: .leading,
                    spacing: 3
                ) {
                    Text(subTheme.name)
                        .font(.headline)

                    Text(
                        "\(discovered) / \(words.count) discovered · \(mastered) mastered"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                if complete {
                    Image(
                        systemName: "checkmark.circle.fill"
                    )
                    .foregroundStyle(.green)
                } else {
                    Text(
                        "\(Int((progress * 100).rounded()))%"
                    )
                    .font(.caption)
                    .bold()
                    .foregroundStyle(.secondary)
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ProgressView(
                value: Double(discovered),
                total: Double(max(words.count, 1))
            )
        }
        .padding(16)
    }

    // MARK: - Small Stat

    private func progressStat(
        value: String,
        label: String
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: 3
        ) {
            Text(value)
                .font(.headline)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
