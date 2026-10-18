# Haru (하루)

**A calm, self-paced Korean vocabulary learning app built with SwiftUI.**

Haru is a personal iOS development project exploring how vocabulary learning can feel approachable without streaks, leaderboards, or other pressure-based mechanics. Learners can discover Korean words by theme, practise what they have learned, and revisit vocabulary at their own pace.

> **Project status:** iOS prototype under development. This repository contains the SwiftUI source code; it is not currently distributed through the App Store or TestFlight.

## Features

- **Themed vocabulary learning:** Explore Korean vocabulary organised into topics and learning levels.
- **Learning and review:** Introduce new words, practise with quizzes, and review previously encountered vocabulary.
- **Example sentences:** Study words in context with Korean sentences and English translations.
- **Korean pronunciation:** Hear words and sentences using iOS text-to-speech.
- **Progress tracking:** Track introduced vocabulary and learning progress locally.
- **Journey interface:** Browse vocabulary themes through a Seoul-inspired visual journey.
- **Time-of-day design:** The interface changes its atmosphere between morning, day, evening, and night.
- **iOS widgets (experimental):** A vocabulary review widget is included in the project, but its data-sharing and signing configuration are still being tested.

## Tech stack

| Component | Technology |
| --- | --- |
| iOS app | Swift, SwiftUI |
| Vocabulary data | Supabase |
| Local learning progress | On-device persistence |
| Pronunciation | AVSpeechSynthesizer |
| Widgets | WidgetKit |
| Design | Custom illustrations and time-of-day themes |

## Project structure

The repository includes the iOS app, shared vocabulary and quiz logic, and a widget extension. Key areas include:

- `Haru/` — SwiftUI screens, navigation, settings, and app services
- `Shared/` — Vocabulary models, progress storage, curriculum, and quiz logic
- `VocabWidget/` — Widget implementation
- `Haru.xcodeproj` — Xcode project configuration

## Running locally

Haru is currently a development project rather than a one-click installable release.

1. Clone the repository.
2. Open `Haru.xcodeproj` in a compatible version of Xcode on macOS.
3. Review the Supabase configuration and supply your own project configuration where required. The original hosted vocabulary database is not bundled as a standalone backend.
4. Select an iOS Simulator or a connected iPhone, and configure signing if necessary.
5. Build and run the `Haru` app target.

**Note:** Some features depend on external vocabulary data and iOS capabilities. Widgets in particular may require matching App Group entitlements and an appropriate signing setup. A successful build does not guarantee that every feature works without additional configuration.

## Design philosophy

Haru is designed around a simple idea: language learning should be something users can return to willingly, rather than something they feel pressured to maintain.

The app intentionally avoids XP, competitive leaderboards, and streak-loss penalties. Its visual design draws on quiet, Seoul-inspired scenery, while its learning experience focuses on gradual progress and repetition.

## Future development

Potential next steps include a broader language challenge mode, grammar and contextual lessons, richer word explanations, an AI-powered Korean inquiry page with image text recognition, and learning insights. These are planned ideas, not features of the current release.

A separate web version is also being considered to make Haru easier to share and test across devices.

## Try Haru Web

Launch Haru in your browser: https://haru-web-vod.pages.dev/

Haru was originally developed as a native iOS application using SwiftUI. A web adaptation was created with Claude assistance to make the project accessible without requiring an iPhone or app installation.

The web version is primarily optimised for mobile browsers. Learning progress can be saved locally in your browser or explored in a temporary session without saving.

### Vocabulary Credits

Haru's Korean vocabulary dataset, including English translations and example sentences, was sourced from [FoldAlpha TOPIK Vocabulary](https://topikvocab.foldalpha.com/download/).

The vocabulary content has been adapted for Haru's learning system.

Haru is an independent educational project and is not affiliated with or endorsed by FoldAlpha.

## About

Haru is an independent learning and software-development project. The repository is shared to document its implementation and development process.
