import SwiftUI

struct OnboardingView: View {
    let onFinish: () -> Void

    @State private var page = 0
    @State private var showingWidgetGuide = false

    private var theme: HaruTheme { HaruTheme() }

    var body: some View {
        ZStack {
            theme.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 24)

                TabView(selection: $page) {
                    onboardingPage(
                        symbol: "sun.horizon",
                        title: "Welcome to Haru",
                        subtitle: "A little Korean, at your own pace.",
                        detail: "Discover new words when you feel like it. Haru is here to make learning feel calm and enjoyable."
                    )
                    .tag(0)

                    onboardingPage(
                        symbol: "book.closed",
                        title: "Learn, review, grow",
                        subtitle: "Your journey, one word at a time.",
                        detail: "Explore vocabulary by theme, revisit words you've discovered, and see how far you've come."
                    )
                    .tag(1)

                    widgetPage
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { index in
                        Capsule()
                            .fill(index == page ? theme.accent : theme.secondaryText.opacity(0.25))
                            .frame(width: index == page ? 25 : 8, height: 8)
                    }
                }
                .padding(.bottom, 25)

                if page == 2 {
                    Button {
                        showingWidgetGuide = true
                    } label: {
                        Label("Show Me How", systemImage: "square.grid.2x2")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(theme.accent.opacity(0.12))
                            .foregroundStyle(theme.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 12)
                }

                Button {
                    if page < 2 {
                        withAnimation(.easeInOut) { page += 1 }
                    } else {
                        onFinish()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(page == 2 ? "Begin My Journey" : "Continue")
                        Image(systemName: "arrow.right")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                    .background(theme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                }
                .buttonStyle(.plain)

                if page == 2 {
                    Button("Maybe Later") { onFinish() }
                        .font(.subheadline)
                        .foregroundStyle(theme.secondaryText)
                        .padding(.top, 16)
                }
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 30)
        }
        .sheet(isPresented: $showingWidgetGuide) {
            NavigationStack {
                WidgetSetupGuideView()
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showingWidgetGuide = false }
                        }
                    }
            }
        }
    }

    private func onboardingPage(symbol: String, title: String, subtitle: String, detail: String) -> some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: symbol)
                .font(.system(size: 68, weight: .ultraLight))
                .foregroundStyle(theme.accent)
                .frame(height: 100)
            Text(title)
                .font(.system(size: 32, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.primaryText)
                .multilineTextAlignment(.center)
            Text(subtitle)
                .font(.title3)
                .foregroundStyle(theme.primaryText)
                .multilineTextAlignment(.center)
            Text(detail)
                .font(.body)
                .foregroundStyle(theme.secondaryText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 6)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var widgetPage: some View {
        onboardingPage(
            symbol: "rectangle.on.rectangle",
            title: "Korean throughout your day",
            subtitle: "Make room for a little Haru.",
            detail: "Keep vocabulary close with a Home Screen or Lock Screen widget. You can add either one whenever you're ready."
        )
    }
}

struct WidgetSetupGuideView: View {
    private var theme: HaruTheme { HaruTheme() }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Add Haru to your day")
                    .font(.title2.bold())
                    .foregroundStyle(theme.primaryText)

                Text("iOS requires you to add widgets yourself. You can choose the Home Screen, Lock Screen, or both.")
                    .foregroundStyle(theme.secondaryText)

                instructions(
                    title: "Home Screen",
                    symbol: "apps.iphone",
                    steps: [
                        "Touch and hold an empty area on your Home Screen.",
                        "Tap Edit, then Add Widget (or the + button, depending on your iOS version).",
                        "Search for Haru, choose a widget size, and tap Add Widget."
                    ]
                )

                instructions(
                    title: "Lock Screen",
                    symbol: "lock.iphone",
                    steps: [
                        "Touch and hold your Lock Screen, then tap Customize.",
                        "Choose Lock Screen and tap the widget area below the clock.",
                        "Find Haru and select its Lock Screen widget, then tap Done."
                    ]
                )

                Text("If Haru doesn't appear as an option, the corresponding widget may not be included in this build.")
                    .font(.footnote)
                    .foregroundStyle(theme.secondaryText)
            }
            .padding(24)
        }
        .background(theme.backgroundGradient.ignoresSafeArea())
        .navigationTitle("Widget Setup")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func instructions(title: String, symbol: String, steps: [String]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: symbol)
                .font(.headline)
                .foregroundStyle(theme.primaryText)

            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1).")
                        .fontWeight(.semibold)
                        .foregroundStyle(theme.accent)
                    Text(step)
                        .foregroundStyle(theme.primaryText)
                }
                .font(.subheadline)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}
