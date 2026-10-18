//
//  HaruTheme.swift
//  Haru
//
//  Created by Ervin Sng on 6/10/26.
//
import SwiftUI

// MARK: - Haru Time Period

enum HaruTimePeriod {
    case morning
    case day
    case evening
    case night

    static var current: HaruTimePeriod {
        let hour = Calendar.current.component(.hour, from: Date())

        switch hour {
        case 5..<10:
            return .morning

        case 10..<17:
            return .day

        case 17..<20:
            return .evening

        default:
            return .night
        }
    }
}


// MARK: - Haru Theme

struct HaruTheme {

    let period: HaruTimePeriod

    init(period: HaruTimePeriod = .current) {
        self.period = period
    }


    // MARK: Background

    var background: Color {
        switch period {
        case .morning:
            return Color(
                red: 0.97,
                green: 0.94,
                blue: 0.88
            )

        case .day:
            return Color(
                red: 0.96,
                green: 0.95,
                blue: 0.91
            )

        case .evening:
            return Color(
                red: 0.94,
                green: 0.89,
                blue: 0.84
            )

        case .night:
            return Color(
                red: 0.08,
                green: 0.13,
                blue: 0.20
            )
        }
    }


    // MARK: Card

    var card: Color {
        switch period {
        case .morning, .day, .evening:
            return Color.white.opacity(0.72)

        case .night:
            return Color(
                red: 0.13,
                green: 0.19,
                blue: 0.27
            )
        }
    }


    // MARK: Primary Text

    var primaryText: Color {
        switch period {
        case .morning, .day, .evening:
            return Color(
                red: 0.15,
                green: 0.16,
                blue: 0.17
            )

        case .night:
            return Color(
                red: 0.94,
                green: 0.94,
                blue: 0.92
            )
        }
    }


    // MARK: Secondary Text

    var secondaryText: Color {
        switch period {
        case .morning, .day, .evening:
            return Color(
                red: 0.42,
                green: 0.41,
                blue: 0.39
            )

        case .night:
            return Color(
                red: 0.70,
                green: 0.74,
                blue: 0.78
            )
        }
    }


    // MARK: Accent

    var accent: Color {
        switch period {
        case .morning:
            return Color(
                red: 0.76,
                green: 0.36,
                blue: 0.20
            )

        case .day:
            return Color(
                red: 0.33,
                green: 0.46,
                blue: 0.50
            )

        case .evening:
            return Color(
                red: 0.72,
                green: 0.31,
                blue: 0.20
            )

        case .night:
            return Color(
                red: 0.91,
                green: 0.46,
                blue: 0.32
            )
        }
    }


    // MARK: Secondary Accent

    var secondaryAccent: Color {
        switch period {
        case .morning, .day:
            return Color(
                red: 0.43,
                green: 0.51,
                blue: 0.39
            )

        case .evening:
            return Color(
                red: 0.50,
                green: 0.43,
                blue: 0.35
            )

        case .night:
            return Color(
                red: 0.40,
                green: 0.50,
                blue: 0.47
            )
        }
    }


    // MARK: Journey Accent

    var journeyAccent: Color {
        switch period {
        case .morning, .day:
            return Color(
                red: 0.20,
                green: 0.34,
                blue: 0.52
            )

        case .evening:
            return Color(
                red: 0.30,
                green: 0.36,
                blue: 0.48
            )

        case .night:
            return Color(
                red: 0.40,
                green: 0.57,
                blue: 0.75
            )
        }
    }


    // MARK: Greeting

    var koreanGreeting: String {
        switch period {
        case .morning:
            return "좋은 아침이에요"

        case .day:
            return "좋은 하루 보내세요"

        case .evening:
            return "좋은 저녁이에요"

        case .night:
            return "편안한 밤 보내세요"
        }
    }

    var englishGreeting: String {
        switch period {
        case .morning:
            return "Good morning."

        case .day:
            return "Have a good day."

        case .evening:
            return "Good evening."

        case .night:
            return "Have a restful night."
        }
    }


    // MARK: Background Gradient

    var backgroundGradient: LinearGradient {
        switch period {

        case .morning:
            return LinearGradient(
                colors: [
                    Color(
                        red: 0.98,
                        green: 0.91,
                        blue: 0.78
                    ),
                    background
                ],
                startPoint: .top,
                endPoint: .bottom
            )

        case .day:
            return LinearGradient(
                colors: [
                    Color(
                        red: 0.91,
                        green: 0.94,
                        blue: 0.92
                    ),
                    background
                ],
                startPoint: .top,
                endPoint: .bottom
            )

        case .evening:
            return LinearGradient(
                colors: [
                    Color(
                        red: 0.92,
                        green: 0.77,
                        blue: 0.66
                    ),
                    background
                ],
                startPoint: .top,
                endPoint: .bottom
            )

        case .night:
            return LinearGradient(
                colors: [
                    Color(
                        red: 0.07,
                        green: 0.13,
                        blue: 0.22
                    ),
                    Color(
                        red: 0.11,
                        green: 0.17,
                        blue: 0.24
                    )
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    // MARK: - Background Artwork

    var backgroundImageName: String {
        switch period {
        case .morning:
            return "home_morning"

        case .day:
            return "home_day"

        case .evening:
            return "home_evening"

        case .night:
            return "home_night"
        }
    }
    
    // MARK: - Journey Background

    var journeyBackground: LinearGradient {
        let colors: [Color]

        switch period {
        case .morning:
            colors = [
                Color(red: 0.96, green: 0.84, blue: 0.73),
                Color(red: 0.88, green: 0.83, blue: 0.80),
                Color(red: 0.78, green: 0.82, blue: 0.85)
            ]

        case .day:
            colors = [
                Color(red: 0.80, green: 0.89, blue: 0.92),
                Color(red: 0.70, green: 0.83, blue: 0.88),
                Color(red: 0.61, green: 0.75, blue: 0.81)
            ]

        case .evening:
            colors = [
                Color(red: 0.91, green: 0.68, blue: 0.59),
                Color(red: 0.72, green: 0.60, blue: 0.69),
                Color(red: 0.47, green: 0.49, blue: 0.65)
            ]

        case .night:
            colors = [
                Color(red: 0.07, green: 0.13, blue: 0.22),
                Color(red: 0.12, green: 0.19, blue: 0.31),
                Color(red: 0.18, green: 0.22, blue: 0.36)
            ]
        }

        return LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

}


