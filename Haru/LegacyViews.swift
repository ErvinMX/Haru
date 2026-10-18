
import SwiftUI

// MARK: - Journey Placeholder
// Retained for compatibility with existing project references.

struct JourneyPlaceholderView: View {
    let databaseWords: [TopikWord]
    let isLoading: Bool
    let setupError: String?

    private var theme: HaruTheme {
        HaruTheme()
    }

    var body: some View {
        ZStack {
            theme.backgroundGradient
                .ignoresSafeArea()

            if isLoading {
                ProgressView("Loading journey...")
                    .tint(theme.accent)
            } else if let setupError {
                Text(setupError)
                    .font(.subheadline)
                    .foregroundStyle(theme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(30)
            } else {
                VStack(spacing: 24) {
                    Spacer()

                    Image(systemName: "map.fill")
                        .font(.system(size: 58))
                        .foregroundStyle(theme.journeyAccent)

                    VStack(spacing: 7) {
                        Text("Your Journey")
                            .font(
                                .system(
                                    size: 32,
                                    weight: .bold,
                                    design: .serif
                                )
                            )

                        Text(
                            "Explore your vocabulary journey."
                        )
                        .font(.subheadline)
                        .foregroundStyle(theme.secondaryText)
                    }

                    NavigationLink {
                        TopikProgressView(
                            allWords: databaseWords.filter {
                                $0.level == Curriculum.currentDifficulty.rawValue
                            }
                        )
                    } label: {
                        HStack {
                            Text("View Progress")
                                .fontWeight(.semibold)

                            Image(systemName: "arrow.right")
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 22)
                        .frame(height: 50)
                        .background(theme.journeyAccent)
                        .clipShape(
                            RoundedRectangle(cornerRadius: 14)
                        )
                    }
                    .buttonStyle(.plain)

                    Spacer()
                    Spacer()
                }
                .padding(24)
                .foregroundStyle(theme.primaryText)
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Theme Picker
// Retained for compatibility, but no longer opened by ContentView.

struct ThemePickerView: View {
    let selectedTheme: String?
    let onSelect: (String) -> Void

    @Environment(\.dismiss)
    private var dismiss

    private var domains: [String] {
        var result: [String] = []

        for subTheme in Curriculum.allSubThemes {
            if !result.contains(subTheme.domain) {
                result.append(subTheme.domain)
            }
        }

        return result
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(domains, id: \.self) { domain in
                    Section(domain) {
                        let themes = Curriculum.allSubThemes
                            .filter {
                                $0.domain == domain
                            }

                        ForEach(themes, id: \.self) { subTheme in
                            Button {
                                onSelect(subTheme.title)
                            } label: {
                                HStack {
                                    Text(subTheme.name)
                                        .foregroundStyle(.primary)

                                    Spacer()

                                    if selectedTheme == subTheme.title {
                                        Image(
                                            systemName:
                                                "checkmark.circle.fill"
                                        )
                                        .foregroundStyle(.blue)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Choose Theme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
