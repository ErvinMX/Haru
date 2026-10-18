
import SwiftUI

private struct JourneyNode: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let position: CGPoint
    let theme: SubTheme?
}

private struct JourneyEdge: Identifiable {
    let id: String
    let from: String
    let to: String
}

struct JourneyView: View {
    let databaseWords: [TopikWord]

    @ObservedObject private var store = VocabStore.shared
    @State private var selectedTheme: JourneyNode?

    @AppStorage("haru.currentDifficultyIndex")
    private var currentDifficultyIndex = 0

    @AppStorage("haru.journey.sequentialUnlockedIndex")
    private var highestUnlockedIndex = 0

    // The part being viewed is separate from the highest part unlocked.
    @State private var selectedDifficultyIndex = 0

    @State private var displayedUnlockedIndex = 0
    @State private var hasLoadedJourney = false
    @State private var animatingEdgeIndex: Int? = nil
    @State private var lineDrawProgress: CGFloat = 0
    @State private var glowingNodeID: String? = nil
    @State private var glowStrength: CGFloat = 0
    @State private var isRevealing = false
    @State private var showingChapterComplete = false
    @State private var hasPresentedChapterComplete = false

    private let nodeWidth: CGFloat = 152
    private let nodeHeight: CGFloat = 92

    // MARK: - Appearance

    private var theme: HaruTheme {
        HaruTheme()
    }

    private var background: LinearGradient {
        theme.journeyBackground
    }

    private var chapterAccent: Color {
        switch selectedDifficultyIndex {
        case 1:
            return Color(
                red: 0.40,
                green: 0.59,
                blue: 0.72
            )
        case 2:
            return Color(
                red: 0.61,
                green: 0.53,
                blue: 0.71
            )
        default:
            return theme.journeyAccent
        }
    }

    private var isLightJourney: Bool {
        theme.period != .night
    }

    private var journeyTextColor: Color {
        isLightJourney
            ? Color(red: 0.15, green: 0.23, blue: 0.33)
            : .white
    }

    private var nodeBackgroundColor: Color {
        isLightJourney
            ? Color.white.opacity(0.78)
            : Color.white.opacity(0.14)
    }

    private var completedNodeBackgroundColor: Color {
        isLightJourney
            ? Color.white.opacity(0.94)
            : Color.white.opacity(0.23)
    }

    private var nodeBorderColor: Color {
        isLightJourney
            ? chapterAccent.opacity(0.38)
            : Color.white.opacity(0.28)
    }

    private var journeyLineColor: Color {
        isLightJourney
            ? chapterAccent.opacity(0.65)
            : Color.white.opacity(0.35)
    }

    private var progressTrackColor: Color {
        isLightJourney
            ? chapterAccent.opacity(0.15)
            : Color.white.opacity(0.18)
    }

    private var progressFillColor: Color {
        isLightJourney
            ? chapterAccent
            : Color.white.opacity(0.85)
    }

    private var revealGlowColor: Color {
        isLightJourney
            ? chapterAccent
            : .cyan
    }

    // MARK: - Curriculum

    private var selectedDifficulty: HaruDifficulty {
        HaruDifficulty.allCases[min(max(selectedDifficultyIndex, 0), 2)]
    }

    private var orderedThemes: [SubTheme] {
        Curriculum.themes(with: databaseWords, level: selectedDifficulty)
    }

    private var domains: [String] {
        var result: [String] = []

        for subTheme in orderedThemes {
            if !result.contains(subTheme.domain) {
                result.append(subTheme.domain)
            }
        }

        return result
    }

    // MARK: - Completion

    private func words(
        for subTheme: SubTheme
    ) -> [TopikWord] {
        Curriculum.words(
            in: subTheme.title,
            from: databaseWords,
            level: selectedDifficulty
        )
    }

    private func isThemeComplete(
        _ subTheme: SubTheme
    ) -> Bool {
        let themeWords = words(for: subTheme)

        guard !themeWords.isEmpty else {
            return false
        }

        // Discovering every word completes a theme.
        // Three-star mastery is not required.
        return themeWords.allSatisfy {
            store.hasIntroduced($0)
        }
    }

    private var completedPrefixCount: Int {
        var count = 0

        for subTheme in orderedThemes {
            guard isThemeComplete(subTheme) else {
                break
            }

            count += 1
        }

        return count
    }

    private var maximumIndex: Int {
        max(orderedThemes.count - 1, 0)
    }

    private var targetUnlockedIndex: Int {
        // A previous part is already completed, so all its themes remain accessible.
        if selectedDifficultyIndex < currentDifficultyIndex {
            return maximumIndex
        }

        return min(
            max(highestUnlockedIndex, completedPrefixCount),
            maximumIndex
        )
    }

    private var unlockedIndex: Int {
        min(
            displayedUnlockedIndex,
            maximumIndex
        )
    }

    private var mysteryNodeID: String? {
        let nextIndex = unlockedIndex + 1

        guard nextIndex < orderedThemes.count else {
            return nil
        }

        return orderedThemes[nextIndex].title
    }

    // MARK: - Network Layout

    private var nodes: [JourneyNode] {
        var result: [JourneyNode] = []

        for (domainIndex, domain) in domains.enumerated() {
            let themes = orderedThemes.filter {
                $0.domain == domain
            }

            let column = domainIndex % 3
            let row = domainIndex / 3

            let baseX = CGFloat(column) * 720 + 180
            let baseY = CGFloat(row) * 650 + 300

            for (themeIndex, subTheme) in themes.enumerated() {
                let branch = themeIndex % 3
                let depth = themeIndex / 3

                let x = baseX + CGFloat(depth) * 175

                let yOffsets: [CGFloat] = [
                    -120, 0, 120
                ]

                let y = baseY
                    + yOffsets[branch]
                    + CGFloat(depth % 2) * 30

                result.append(
                    JourneyNode(
                        id: subTheme.title,
                        title: subTheme.name,
                        subtitle: domain,
                        position: CGPoint(x: x, y: y),
                        theme: subTheme
                    )
                )
            }
        }

        return result
    }
    
    // MARK: - Connections

    private var edges: [JourneyEdge] {
        var result: [JourneyEdge] = []

        guard orderedThemes.count > 1 else {
            return result
        }

        for index in 0..<(orderedThemes.count - 1) {
            let current = orderedThemes[index]
            let next = orderedThemes[index + 1]

            result.append(
                JourneyEdge(
                    id: "stage-\(index)",
                    from: current.title,
                    to: next.title
                )
            )
        }

        return result
    }

    // MARK: - Visibility

    private var visibleNodes: [JourneyNode] {
        let visibleIDs = Set(
            orderedThemes
                .prefix(unlockedIndex + 2)
                .map(\.title)
        )

        return nodes.filter {
            visibleIDs.contains($0.id)
        }
    }

    private var visibleEdges: [JourneyEdge] {
        let visibleIDs = Set(
            visibleNodes.map(\.id)
        )

        return edges.filter {
            visibleIDs.contains($0.from) &&
            visibleIDs.contains($0.to)
        }
    }

    // MARK: - Unlock Animation

    private func refreshJourney() {
        guard !databaseWords.isEmpty else {
            return
        }

        let target = targetUnlockedIndex

        guard target > displayedUnlockedIndex,
              !isRevealing else {
            return
        }

        if selectedDifficultyIndex == currentDifficultyIndex {
            highestUnlockedIndex = target
        }
        isRevealing = true

        Task { @MainActor in
            while displayedUnlockedIndex < target {
                let nextIndex = displayedUnlockedIndex + 1
                let nextID = orderedThemes[nextIndex].title

                // Phase 1: draw the connection.
                animatingEdgeIndex = displayedUnlockedIndex
                lineDrawProgress = 0

                withAnimation(.easeInOut(duration: 1.15)) {
                    lineDrawProgress = 1
                }

                try? await Task.sleep(for: .seconds(1.22))

                // Phase 2: reveal the next node.
                glowingNodeID = nextID
                glowStrength = 0

                withAnimation(
                    .spring(
                        response: 0.48,
                        dampingFraction: 0.72
                    )
                ) {
                    displayedUnlockedIndex = nextIndex
                    glowStrength = 1
                }

                try? await Task.sleep(for: .seconds(0.65))

                // Phase 3: fade the glow.
                withAnimation(.easeOut(duration: 0.7)) {
                    glowStrength = 0
                }

                try? await Task.sleep(for: .seconds(0.72))

                animatingEdgeIndex = nil
                glowingNodeID = nil
                lineDrawProgress = 0
            }

            isRevealing = false
            refreshJourney()
        }
    }

    private func initialiseJourney() {
        guard !hasLoadedJourney else {
            refreshJourney()
            return
        }

        hasLoadedJourney = true

        displayedUnlockedIndex = min(
            selectedDifficultyIndex < currentDifficultyIndex
                ? maximumIndex
                : highestUnlockedIndex,
            maximumIndex
        )

        refreshJourney()
    }

    // MARK: - Main View

    var body: some View {
        ZStack {
            background
                .ignoresSafeArea()

            ScrollView([.horizontal, .vertical]) {
                ZStack(alignment: .topLeading) {
                    connectionLayer

                    ForEach(visibleNodes) { node in
                        Group {
                            if node.id == mysteryNodeID {
                                mysteryNodeView
                            } else {
                                nodeView(node)
                                    .overlay {
                                        if glowingNodeID == node.id {
                                            RoundedRectangle(
                                                cornerRadius: 15
                                            )
                                            .stroke(
                                                revealGlowColor.opacity(
                                                    Double(glowStrength) * 0.9
                                                ),
                                                lineWidth: 2
                                            )
                                            .padding(-5)
                                            .shadow(
                                                color: revealGlowColor.opacity(
                                                    Double(glowStrength) * 0.9
                                                ),
                                                radius: 22
                                            )
                                            .allowsHitTesting(false)
                                        }
                                    }
                                    .scaleEffect(
                                        glowingNodeID == node.id
                                            ? 1 + 0.09 * glowStrength
                                            : 1
                                    )
                            }
                        }
                        .id(
                            "\(node.id)-\(node.id == mysteryNodeID ? "mystery" : "revealed")"
                        )
                        .transition(
                            .scale(scale: 0.6)
                                .combined(with: .opacity)
                        )
                        .position(node.position)
                    }
                }
                .frame(
                    width: 2400,
                    height: CGFloat((domains.count + 2) / 3) * 650 + 650,
                    alignment: .topLeading
                )
            }
            .scrollIndicators(.hidden)
            .defaultScrollAnchor(.topLeading)
            .safeAreaInset(edge: .top, spacing: 0) {
                header
                    .padding(.bottom, 14)
                    .frame(maxWidth: .infinity)
                    .background(background)
            }
        }
        .sheet(
            item: $selectedTheme,
            onDismiss: {
                refreshJourney()
                checkChapterCompletion()
            }
        ) { node in
            NavigationStack {
                if let subTheme = node.theme {
                    TopikThemeProgressView(
                        subTheme: subTheme,
                        allWords: databaseWords,
                        difficulty: selectedDifficulty
                    )
                    .toolbar {
                        ToolbarItem(
                            placement: .topBarTrailing
                        ) {
                            Button("Done") {
                                selectedTheme = nil
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            selectedDifficultyIndex = currentDifficultyIndex
            initialiseJourney()
            checkChapterCompletion()
        }
        .sheet(isPresented: $showingChapterComplete) {
            chapterCompletionView
        }
        .onChange(of: currentDifficultyIndex) { _, newIndex in
            hasPresentedChapterComplete = false
            highestUnlockedIndex = 0
            selectedDifficultyIndex = newIndex
            displayedUnlockedIndex = 0
            hasLoadedJourney = false
            initialiseJourney()
        }
        .onChange(of: selectedDifficultyIndex) { _, _ in
            // Browsing a previous part never changes real progression.
            isRevealing = false
            animatingEdgeIndex = nil
            glowingNodeID = nil
            lineDrawProgress = 0
            hasLoadedJourney = false
            displayedUnlockedIndex = 0
            initialiseJourney()
        }
        .onChange(of: databaseWords.count) { _, _ in
            if selectedTheme == nil {
                refreshJourney()
                checkChapterCompletion()
            }
        }
        .onChange(of: store.introducedLearningUnitIDs.count) { _, _ in
            checkChapterCompletion()
        }
    }

    // MARK: - Chapter completion

    private func checkChapterCompletion() {
        guard selectedDifficultyIndex == currentDifficultyIndex,
              !showingChapterComplete,
              !hasPresentedChapterComplete else {
            return
        }

        guard Curriculum.complete(
            level: Curriculum.currentDifficulty,
            words: databaseWords,
            introducedIDs: store.introducedLearningUnitIDs
        ) else {
            return
        }

        hasPresentedChapterComplete = true
        showingChapterComplete = true
    }

    private var chapterCompletionView: some View {
        let finished = Curriculum.currentDifficulty

        return VStack(spacing: 20) {
            Spacer()

            Image(systemName: "sparkle")
                .font(.system(size: 42, weight: .light))
                .foregroundStyle(theme.journeyAccent)

            Text("Part \(finished.part) Complete")
                .font(.largeTitle.weight(.semibold))

            Text(
                "You've discovered all the \(finished.title.lowercased()) vocabulary. A new chapter of your Korean journey awaits."
            )
            .multilineTextAlignment(.center)
            .foregroundStyle(.secondary)

            Spacer()

            Button {
                showingChapterComplete = false

                if finished.next != nil {
                    highestUnlockedIndex = 0
                    displayedUnlockedIndex = 0
                    currentDifficultyIndex = finished.part
                }
            } label: {
                Text(
                    finished.next.map {
                        "Begin Part \($0.part) · \($0.title)"
                    } ?? "Continue Your Journey"
                )
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
            }
            .buttonStyle(.borderedProminent)
            .tint(theme.journeyAccent)
        }
        .padding(30)
        .background(
            theme.backgroundGradient.ignoresSafeArea()
        )
        .presentationDetents([.medium, .large])
    }
    
    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Your Journey")
                        .font(.system(size: 30, weight: .bold, design: .serif))
                        .foregroundStyle(journeyTextColor)

                    Text(selectedDifficultyIndex < currentDifficultyIndex
                        ? "Revisit your completed themes"
                        : "\(max(0, orderedThemes.count - completedPrefixCount)) more themes to \(currentDifficultyIndex == 2 ? "finish Advanced" : "unlock \(HaruDifficulty.allCases[currentDifficultyIndex + 1].title)")")
                        .font(.caption)
                        .foregroundStyle(journeyTextColor.opacity(0.70))

                    Text("Part \(selectedDifficulty.part) · \(selectedDifficulty.title) · \(databaseWords.filter { $0.level == selectedDifficulty.rawValue }.count) words")
                        .font(.subheadline)
                        .foregroundStyle(journeyTextColor.opacity(0.70))
                }

                Spacer()

                Image(systemName: "point.3.connected.trianglepath.dotted")
                    .font(.title2)
                    .foregroundStyle(journeyTextColor.opacity(0.80))
            }

            HStack(spacing: 8) {
                ForEach(HaruDifficulty.allCases) { difficulty in
                    let index = difficulty.part - 1
                    let isUnlocked = index <= currentDifficultyIndex
                    let isSelected = index == selectedDifficultyIndex

                    Button {
                        guard isUnlocked else { return }
                        selectedDifficultyIndex = index
                    } label: {
                        VStack(spacing: 5) {
                            HStack(spacing: 4) {
                                if !isUnlocked {
                                    Image(systemName: "lock.fill")
                                }
                                Text("Part \(difficulty.part)")
                            }
                            .font(.caption2.weight(.semibold))

                            Text(difficulty.title)
                                .font(.caption2)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .foregroundStyle(journeyTextColor.opacity(isUnlocked ? 1 : 0.45))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(isSelected ? chapterAccent.opacity(0.3) : nodeBackgroundColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? chapterAccent : nodeBorderColor, lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(!isUnlocked)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 18)
    }

    // MARK: - Connection Layer

    private var connectionLayer: some View {
        let positions = Dictionary(
            uniqueKeysWithValues: nodes.map {
                ($0.id, $0.position)
            }
        )

        return ZStack(alignment: .topLeading) {
            ForEach(visibleEdges) { edge in
                if let start = positions[edge.from],
                   let end = positions[edge.to] {

                    let path = connectionPath(
                        from: start,
                        to: end
                    )

                    let isActive = animatingEdgeIndex.map {
                        edge.id == "stage-\($0)"
                    } ?? false

                    // Normal connection.
                    path.stroke(
                        isActive
                            ? journeyLineColor.opacity(0.5)
                            : journeyLineColor,
                        style: StrokeStyle(
                            lineWidth: 1.5,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )

                    if isActive {
                        // Soft outer glow.
                        path.trimmedPath(
                            from: 0,
                            to: lineDrawProgress
                        )
                        .stroke(
                            revealGlowColor.opacity(0.38),
                            style: StrokeStyle(
                                lineWidth: 10,
                                lineCap: .round,
                                lineJoin: .round
                            )
                        )
                        .blur(radius: 9)

                        // Bright moving connection.
                        path.trimmedPath(
                            from: 0,
                            to: lineDrawProgress
                        )
                        .stroke(
                            isLightJourney
                                ? chapterAccent
                                : Color.white,
                            style: StrokeStyle(
                                lineWidth: 3,
                                lineCap: .round,
                                lineJoin: .round
                            )
                        )
                        .shadow(
                            color: revealGlowColor.opacity(0.85),
                            radius: 8
                        )
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func connectionPath(
        from start: CGPoint,
        to end: CGPoint
    ) -> Path {
        let horizontal =
            abs(end.x - start.x) >= abs(end.y - start.y)

        let startPoint: CGPoint
        let endPoint: CGPoint

        if horizontal {
            let direction: CGFloat =
                end.x >= start.x ? 1 : -1

            startPoint = CGPoint(
                x: start.x + direction * nodeWidth / 2,
                y: start.y
            )

            endPoint = CGPoint(
                x: end.x - direction * nodeWidth / 2,
                y: end.y
            )
        } else {
            let direction: CGFloat =
                end.y >= start.y ? 1 : -1

            startPoint = CGPoint(
                x: start.x,
                y: start.y + direction * nodeHeight / 2
            )

            endPoint = CGPoint(
                x: end.x,
                y: end.y - direction * nodeHeight / 2
            )
        }

        return Path { path in
            path.move(to: startPoint)

            if horizontal {
                let middleX =
                    (startPoint.x + endPoint.x) / 2

                path.addLine(
                    to: CGPoint(
                        x: middleX,
                        y: startPoint.y
                    )
                )

                path.addLine(
                    to: CGPoint(
                        x: middleX,
                        y: endPoint.y
                    )
                )
            } else {
                let middleY =
                    (startPoint.y + endPoint.y) / 2

                path.addLine(
                    to: CGPoint(
                        x: startPoint.x,
                        y: middleY
                    )
                )

                path.addLine(
                    to: CGPoint(
                        x: endPoint.x,
                        y: middleY
                    )
                )
            }

            path.addLine(to: endPoint)
        }
    }

    // MARK: - Mystery Node

    private var mysteryNodeView: some View {
        VStack(spacing: 7) {
            Image(systemName: "questionmark")
                .font(
                    .system(
                        size: 24,
                        weight: .medium
                    )
                )
                .foregroundStyle(
                    journeyTextColor.opacity(0.85)
                )

            Text("Undiscovered")
                .font(.caption2)
                .foregroundStyle(
                    journeyTextColor.opacity(0.70)
                )
        }
        .frame(
            width: nodeWidth,
            height: nodeHeight
        )
        .background(
            isLightJourney
                ? Color.white.opacity(0.45)
                : Color.white.opacity(0.07)
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 12)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isLightJourney
                        ? theme.journeyAccent.opacity(0.50)
                        : Color.white.opacity(0.4),
                    style: StrokeStyle(
                        lineWidth: 1.5,
                        dash: [5, 4]
                    )
                )
        }
        .accessibilityLabel(
            "Next undiscovered stage"
        )
    }

    // MARK: - Vocabulary Node

    private func nodeView(
        _ node: JourneyNode
    ) -> some View {
        let themeWords = node.theme.map {
            words(for: $0)
        } ?? []

        let discovered = themeWords.filter {
            store.hasIntroduced($0)
        }.count

        let isComplete =
            !themeWords.isEmpty &&
            discovered == themeWords.count

        return Button {
            selectedTheme = node
        } label: {
            VStack(
                alignment: .leading,
                spacing: 6
            ) {
                HStack(spacing: 5) {
                    Text("PART \(selectedDifficulty.part) · \(selectedDifficulty.title.uppercased())")
                        .font(
                            .system(
                                size: 9,
                                weight: .semibold
                            )
                        )
                        .tracking(0.7)
                        .foregroundStyle(
                            journeyTextColor.opacity(0.70)
                        )
                        .lineLimit(1)

                    Spacer(minLength: 0)

                    if isComplete {
                        Image(
                            systemName: "checkmark.circle.fill"
                        )
                        .font(.caption)
                        .foregroundStyle(
                            isLightJourney
                                ? Color(
                                    red: 0.20,
                                    green: 0.48,
                                    blue: 0.32
                                )
                                : Color.green.opacity(0.9)
                        )
                    }
                }

                Text(node.title)
                    .font(
                        .system(
                            size: 14,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(journeyTextColor)
                    .lineLimit(2)

                Text("\(discovered) / \(themeWords.count) words discovered")
                    .font(.system(size: 9))
                    .foregroundStyle(journeyTextColor.opacity(0.72))
                    .lineLimit(1)

                Spacer(minLength: 0)

                if !themeWords.isEmpty {
                    GeometryReader { bar in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(progressTrackColor)

                            Capsule()
                                .fill(progressFillColor)
                                .frame(
                                    width:
                                        bar.size.width
                                        * CGFloat(discovered)
                                        / CGFloat(themeWords.count)
                                )
                        }
                    }
                    .frame(height: 3)
                }
            }
            .padding(12)
            .frame(
                width: nodeWidth,
                height: nodeHeight,
                alignment: .leading
            )
            .background(
                isComplete
                    ? completedNodeBackgroundColor
                    : nodeBackgroundColor
            )
            .clipShape(
                RoundedRectangle(cornerRadius: 12)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isComplete
                            ? (
                                isLightJourney
                                    ? chapterAccent.opacity(0.65)
                                    : Color.white.opacity(0.65)
                            )
                            : nodeBorderColor,
                        lineWidth: isComplete ? 1.5 : 1
                    )
            }
        }
        .buttonStyle(.plain)
    }
}
