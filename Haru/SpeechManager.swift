
import Foundation
import AVFoundation

final class SpeechManager {

    static let shared = SpeechManager()

    private let synthesizer = AVSpeechSynthesizer()

    private init() {}

    // MARK: - Settings

    private var pronunciationEnabled: Bool {
        let key = "haru.audio.pronunciationEnabled"

        guard UserDefaults.standard.object(forKey: key) != nil else {
            return true
        }

        return UserDefaults.standard.bool(forKey: key)
    }

    // MARK: - Speak Korean

    func speakKorean(_ text: String) {

        // Respect the user's audio preference.
        guard pronunciationEnabled else {
            if synthesizer.isSpeaking {
                synthesizer.stopSpeaking(at: .immediate)
            }
            return
        }

        // Stop the previous word before starting another.
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)

        utterance.voice = AVSpeechSynthesisVoice(
            language: "ko-KR"
        )

        let defaults = UserDefaults.standard
        let rate = defaults.object(forKey: "haru.audio.speechRate") as? Double ?? 0.40
        let pitch = defaults.object(forKey: "haru.audio.speechPitch") as? Double ?? 1.0
        let volume = defaults.object(forKey: "haru.audio.speechVolume") as? Double ?? 1.0

        utterance.rate = Float(min(max(rate, 0.30), 0.60))
        utterance.pitchMultiplier = Float(min(max(pitch, 0.75), 1.25))
        utterance.volume = Float(min(max(volume, 0.0), 1.0))

        synthesizer.speak(utterance)
    }
}
