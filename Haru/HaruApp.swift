//
//  HaruApp.swift
//  Haru
//
//  Created by Ervin Sng on 6/9/26.
//

import SwiftUI

@main
struct HaruApp: App {
    @AppStorage("haru.onboarding.completed") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                ContentView()
            } else {
                OnboardingView {
                    hasCompletedOnboarding = true
                }
            }
        }
    }
}
