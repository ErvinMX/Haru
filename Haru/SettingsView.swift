
import SwiftUI

struct SettingsView: View {

    @Environment(\.dismiss) private var dismiss

    @AppStorage("haru.audio.pronunciationEnabled")
    private var pronunciationEnabled = true

    @AppStorage("haru.audio.autoPlayEnabled")
    private var autoPlayEnabled = false

    @AppStorage("haru.audio.speechRate")
    private var speechRate = 0.40

    @AppStorage("haru.audio.speechPitch")
    private var speechPitch = 1.0

    @AppStorage("haru.audio.speechVolume")
    private var speechVolume = 1.0

    @AppStorage("haru.appearance.koreanFontSize")
    private var koreanFontSize = 60.0

    @State private var fontSizeInput = "60"

    @FocusState private var fontSizeFieldFocused: Bool

    @State private var showResetConfirmation = false

    private var theme: HaruTheme {
        HaruTheme()
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?[
            "CFBundleShortVersionString"
        ] as? String ?? "Unknown"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?[
            "CFBundleVersion"
        ] as? String ?? "Unknown"
    }

    var body: some View {
        ZStack {
            theme.backgroundGradient
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header

                    learningSection
                    audioSection
                    appearanceSection
                    dataSection
                    aboutSection

                    Text("A little Korean, at your own pace.")
                        .font(.footnote)
                        .foregroundStyle(theme.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 10)
                        .padding(.bottom, 30)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
        }
        .foregroundStyle(theme.primaryText)
        .navigationBarBackButtonHidden(true)
        .alert(
            "Reset Learning Progress?",
            isPresented: $showResetConfirmation
        ) {
            Button("Cancel", role: .cancel) {}

            Button("Reset Progress", role: .destructive) {
                VocabStore.shared.resetProgress()
                dismiss()
            }
        } message: {
            Text(
                """
                This will erase your discovered words, mastery \
                scores, and Journey progression.

                Your Practice Quiz will be locked again, and \
                you will start from the first theme.

                This action cannot be undone.
                """
            )
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 16) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(width: 42, height: 42)
                    .background(theme.card)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")

            Text("Settings")
                .font(
                    .system(
                        size: 30,
                        weight: .bold,
                        design: .serif
                    )
                )

            Spacer()
        }
        .padding(.bottom, 8)
    }

    // MARK: - Learning

    private var learningSection: some View {
        settingsSection("LEARNING") {
            HStack(spacing: 14) {
                settingIcon("book.closed")

                VStack(alignment: .leading, spacing: 5) {
                    Text("Learning Level")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text(
                        "Part \(Curriculum.currentDifficulty.part) · \(Curriculum.currentDifficulty.title)"
                    )
                    .font(.caption)
                    .foregroundStyle(theme.secondaryText)

                    Text(
                        "New chapters unlock as you discover vocabulary."
                    )
                    .font(.caption2)
                    .foregroundStyle(theme.secondaryText)
                }

                Spacer()
            }
        }
    }
    
    // MARK: - Audio

    private var audioSection: some View {
        settingsSection("AUDIO") {
            VStack(spacing: 18) {
                Toggle(isOn: $pronunciationEnabled) {
                    HStack(spacing: 14) {
                        settingIcon("speaker.wave.2")

                        VStack(alignment: .leading, spacing: 5) {
                            Text("Pronunciation Audio")
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            Text("Enable Korean word playback")
                                .font(.caption)
                                .foregroundStyle(theme.secondaryText)
                        }
                    }
                }
                .tint(theme.accent)

                Divider()
                    .opacity(0.3)

                Toggle(isOn: $autoPlayEnabled) {
                    HStack(spacing: 14) {
                        settingIcon("play.circle")

                        VStack(alignment: .leading, spacing: 5) {
                            Text("Auto-play Pronunciation")
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            Text(
                                "Speak words automatically during learning"
                            )
                            .font(.caption)
                            .foregroundStyle(theme.secondaryText)
                        }
                    }
                }
                .tint(theme.accent)
                .disabled(!pronunciationEnabled)
                .opacity(pronunciationEnabled ? 1 : 0.5)

                Divider()
                    .opacity(0.3)

                VStack(alignment: .leading, spacing: 20) {
                    audioSlider(
                        title: "Speaking Speed",
                        value: $speechRate,
                        range: 0.30...0.60,
                        step: 0.01,
                        formattedValue: String(format: "%.2f", speechRate),
                        lowLabel: "Slower",
                        highLabel: "Faster"
                    )

                    audioSlider(
                        title: "Voice Pitch",
                        value: $speechPitch,
                        range: 0.75...1.25,
                        step: 0.05,
                        formattedValue: String(format: "%.2f", speechPitch),
                        lowLabel: "Lower",
                        highLabel: "Higher"
                    )

                    audioSlider(
                        title: "Voice Volume",
                        value: $speechVolume,
                        range: 0.0...1.0,
                        step: 0.05,
                        formattedValue: "\(Int((speechVolume * 100).rounded()))%",
                        lowLabel: "Quieter",
                        highLabel: "Louder"
                    )

                    Text("Volume is relative to your iPhone's media volume.")
                        .font(.caption2)
                        .foregroundStyle(theme.secondaryText)

                    HStack(spacing: 12) {
                        Button {
                            SpeechManager.shared.speakKorean("안녕하세요. 오늘도 좋은 하루 보내세요.")
                        } label: {
                            Label("Preview Voice", systemImage: "speaker.wave.2")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                        }
                        .buttonStyle(.bordered)
                        .disabled(!pronunciationEnabled)

                        Button("Reset") {
                            speechRate = 0.40
                            speechPitch = 1.0
                            speechVolume = 1.0
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .disabled(!pronunciationEnabled)
                .opacity(pronunciationEnabled ? 1 : 0.5)
            }
        }
    }

    private func audioSlider(
        title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        formattedValue: String,
        lowLabel: String,
        highLabel: String
    ) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Text(formattedValue)
                    .font(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(theme.secondaryText)
            }
            Slider(value: value, in: range, step: step)
                .tint(theme.accent)
            HStack {
                Text(lowLabel)
                Spacer()
                Text(highLabel)
            }
            .font(.caption)
            .foregroundStyle(theme.secondaryText)
        }
    }

    // MARK: - Appearance

    private var appearanceSection: some View {
        settingsSection("APPEARANCE") {
            VStack(alignment: .leading, spacing: 18) {

                HStack(spacing: 14) {
                    settingIcon("textformat.size")

                    VStack(alignment: .leading, spacing: 5) {
                        Text("Korean Word Size")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Text(
                            "Choose a comfortable size for learning"
                        )
                        .font(.caption)
                        .foregroundStyle(theme.secondaryText)
                    }

                    Spacer()
                }

                // MARK: - Live Preview

                VStack(spacing: 10) {
                    Text("PREVIEW")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .tracking(1)
                        .foregroundStyle(theme.secondaryText)

                    Text("안녕하세요")
                        .font(
                            .system(
                                size: CGFloat(koreanFontSize),
                                weight: .bold
                            )
                        )
                        .lineLimit(2)
                        .minimumScaleFactor(0.65)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 110)

                    Text("Hello")
                        .font(.subheadline)
                        .foregroundStyle(theme.secondaryText)
                }
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(
                    theme.accent.opacity(0.07)
                )
                .clipShape(
                    RoundedRectangle(cornerRadius: 16)
                )

                // MARK: - Size Input

                HStack {
                    Text("Font Size")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Spacer()

                    TextField(
                        "60",
                        text: $fontSizeInput
                    )
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .focused($fontSizeFieldFocused)
                    .frame(width: 48)
                    .onSubmit {
                        applyFontSizeInput()
                    }
                    .onChange(of: fontSizeFieldFocused) {
                        _, focused in

                        if !focused {
                            applyFontSizeInput()
                        }
                    }

                    Text("pt")
                        .font(.subheadline)
                        .foregroundStyle(theme.secondaryText)
                }

                Slider(
                    value: $koreanFontSize,
                    in: 32...96,
                    step: 1
                ) { isEditing in
                    if !isEditing {
                        fontSizeInput = String(
                            Int(koreanFontSize)
                        )
                    }
                }
                .tint(theme.accent)

                HStack {
                    Text("32 pt")

                    Spacer()

                    Text("96 pt")
                }
                .font(.caption)
                .foregroundStyle(theme.secondaryText)

                Button {
                    koreanFontSize = 60
                    fontSizeInput = "60"
                    fontSizeFieldFocused = false
                } label: {
                    HStack(spacing: 8) {
                        Image(
                            systemName: "arrow.counterclockwise"
                        )

                        Text("Reset to Default (60 pt)")
                    }
                    .font(.subheadline)
                    .foregroundStyle(theme.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
            }
            .onAppear {
                fontSizeInput = String(
                    Int(koreanFontSize)
                )
            }
            .onChange(of: koreanFontSize) {
                _, newValue in

                if !fontSizeFieldFocused {
                    fontSizeInput = String(
                        Int(newValue)
                    )
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()

                    Button("Done") {
                        applyFontSizeInput()
                        fontSizeFieldFocused = false
                    }
                }
            }
        }
    }

    private func applyFontSizeInput() {
        guard let enteredSize = Double(fontSizeInput) else {
            fontSizeInput = String(
                Int(koreanFontSize)
            )
            return
        }

        let clampedSize = min(
            max(enteredSize.rounded(), 32),
            96
        )

        koreanFontSize = clampedSize
        fontSizeInput = String(Int(clampedSize))
    }

    // MARK: - Data & Privacy

    private var dataSection: some View {
        settingsSection("DATA & PRIVACY") {
            Button {
                showResetConfirmation = true
            } label: {
                HStack(spacing: 14) {
                    Image(
                        systemName: "arrow.counterclockwise"
                    )
                    .font(.system(size: 19))
                    .foregroundStyle(.red)
                    .frame(width: 34, height: 34)

                    VStack(
                        alignment: .leading,
                        spacing: 5
                    ) {
                        Text("Reset Learning Progress")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(theme.primaryText)

                        Text(
                            "Start your Korean journey again"
                        )
                        .font(.caption)
                        .foregroundStyle(theme.secondaryText)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(theme.secondaryText)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                "Reset Learning Progress"
            )
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        settingsSection("ABOUT") {
            VStack(spacing: 18) {

                HStack(spacing: 14) {
                    settingIcon("info.circle")

                    VStack(
                        alignment: .leading,
                        spacing: 5
                    ) {
                        Text("About Haru")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Text(
                            "Learn Korean at your own pace."
                        )
                        .font(.caption)
                        .foregroundStyle(theme.secondaryText)
                    }

                    Spacer()
                }

                Divider()
                    .opacity(0.3)

                HStack(spacing: 14) {
                    settingIcon("number")

                    VStack(
                        alignment: .leading,
                        spacing: 5
                    ) {
                        Text("App Version")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Text(
                            "Version \(appVersion) · Build \(buildNumber)"
                        )
                        .font(.caption)
                        .foregroundStyle(theme.secondaryText)
                    }

                    Spacer()
                }

                Divider()
                    .opacity(0.3)

                HStack(spacing: 14) {
                    settingIcon("hand.raised")

                    VStack(
                        alignment: .leading,
                        spacing: 5
                    ) {
                        Text("Privacy & Data")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Text(
                            "Learning progress and vocabulary"
                        )
                        .font(.caption)
                        .foregroundStyle(theme.secondaryText)

                        Text(
                            "Privacy information will be added before release."
                        )
                        .font(.caption2)
                        .foregroundStyle(theme.secondaryText)
                    }

                    Spacer()
                }
            }
        }
    }

    // MARK: - Reusable Components

    private func settingsSection<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: 12
        ) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .tracking(1)
                .foregroundStyle(theme.secondaryText)
                .padding(.leading, 4)

            content()
                .padding(18)
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
                .background(theme.card)
                .clipShape(
                    RoundedRectangle(cornerRadius: 20)
                )
        }
    }

    private func settingIcon(
        _ symbol: String
    ) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 19))
            .foregroundStyle(theme.accent)
            .frame(width: 34, height: 34)
    }
}
