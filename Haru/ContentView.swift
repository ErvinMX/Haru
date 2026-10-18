
import SwiftUI

struct ContentView: View {
    @ObservedObject private var store = VocabStore.shared

    @State private var databaseWords: [TopikWord] = []
    @State private var isLoading = true
    @State private var setupError: String?
    @State private var selectedTab: HaruTab = .home
    @State private var widgetReviewWord: TopikWord?
    @State private var pendingWidgetLearningUnitID: String?

    @AppStorage("haru.journey.sequentialUnlockedIndex")
    private var journeyUnlockedIndex = 0

    @AppStorage("haru.currentDifficultyIndex")
    private var currentDifficultyIndex = 0

    @AppStorage("haru.navigation.journeyRequest")
    private var journeyRequest = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView(
                    databaseWords: databaseWords,
                    isLoading: isLoading,
                    setupError: setupError,
                    onChooseTheme: {
                        syncCurrentJourneyTheme()
                        selectedTab = .learn
                    }
                )
            }
            .tabItem {
                Label(
                    "Home",
                    systemImage: selectedTab == .home
                        ? "house.fill" : "house"
                )
            }
            .tag(HaruTab.home)

            NavigationStack {
                LearnView(
                    databaseWords: databaseWords,
                    isLoading: isLoading,
                    setupError: setupError
                )
            }
            .tabItem {
                Label(
                    "Learn",
                    systemImage: selectedTab == .learn
                        ? "book.fill" : "book"
                )
            }
            .tag(HaruTab.learn)

            NavigationStack {
                JourneyView(databaseWords: databaseWords)
            }
            .tabItem {
                Label(
                    "Journey",
                    systemImage: selectedTab == .journey
                        ? "map.fill" : "map"
                )
            }
            .tag(HaruTab.journey)
        }
        .tint(HaruTheme().accent)
        .task {
            store.prepareNewVocabularyProgress()

            if databaseWords.isEmpty {
                await loadDatabase()
            }

            syncCurrentJourneyTheme()
        }
        .onChange(of: journeyUnlockedIndex) { _, _ in
            syncCurrentJourneyTheme()
        }
        .onChange(of: currentDifficultyIndex) { _, _ in
            journeyUnlockedIndex = 0
            syncCurrentJourneyTheme()
        }
        .onChange(of: selectedTab) { _, tab in
            if tab == .learn || tab == .home {
                syncCurrentJourneyTheme()
            }
        }
        .onChange(of: journeyRequest) { _, _ in
            selectedTab = .journey
        }
        .onOpenURL { url in
            handleWidgetURL(url)
        }
        .sheet(item: $widgetReviewWord) { word in
            NavigationStack {
                WordReviewView(word: word)
            }
        }
    }

    // MARK: - Fixed Journey Theme

    private func syncCurrentJourneyTheme() {
        let themes = Curriculum.themes(with: databaseWords)

        guard !themes.isEmpty else {
            return
        }

        let index = min(
            max(journeyUnlockedIndex, 0),
            themes.count - 1
        )

        let requiredTheme = themes[index].title

        if store.currentTheme != requiredTheme {
            store.setCurrentTheme(requiredTheme)
        }
    }

    // MARK: - Widget Deep Links

    private func handleWidgetURL(_ url: URL) {
        guard url.scheme == "haru",
              url.host == "review",
              let components = URLComponents(
                url: url,
                resolvingAgainstBaseURL: false
              ),
              let learningUnitID = components.queryItems?
                .first(where: { $0.name == "id" })?.value
        else {
            return
        }

        openWidgetWord(learningUnitID: learningUnitID)
    }

    private func openWidgetWord(learningUnitID: String) {
        guard !databaseWords.isEmpty else {
            pendingWidgetLearningUnitID = learningUnitID
            return
        }

        guard let word = databaseWords.first(where: {
            $0.learningUnitID == learningUnitID
        }) else {
            return
        }

        widgetReviewWord = word
    }

    private func openPendingWidgetWordIfNeeded() {
        guard let id = pendingWidgetLearningUnitID else {
            return
        }

        pendingWidgetLearningUnitID = nil
        openWidgetWord(learningUnitID: id)
    }

    // MARK: - Database

    @MainActor
    private func loadDatabase() async {
        isLoading = true
        setupError = nil

        do {
            let words = try await SupabaseService.shared
                .fetchTopikWords()

            databaseWords = words
            syncCurrentJourneyTheme()
            openPendingWidgetWordIfNeeded()

            print(
                "📚 Loaded \(words.count) Haru vocabulary words."
            )

            if words.isEmpty {
                setupError =
                    "No vocabulary was loaded from Supabase."
            }
        } catch {
            setupError =
                "Unable to load vocabulary. Please try again."

            print("❌ Vocabulary loading error:", error)
        }

        isLoading = false
    }
}

// MARK: - Main Tabs

enum HaruTab {
    case home
    case learn
    case journey
}
