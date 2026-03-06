# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Secret Notes is an early-stage iOS app built with **SwiftUI**. It is a private notepad application. The project currently contains the default Xcode template scaffolding with minimal implementation.

- **Bundle ID**: `de.djvlk.Secret-Notes---Private-Notepad`
- **Deployment Target**: iOS 26.2
- **Swift Version**: 5.0
- **No external dependencies** (no SPM, CocoaPods, or Carthage)

## Build

Open `Secret Notes – Private Notepad.xcodeproj` in Xcode and build with Cmd+B, or from CLI:

```bash
xcodebuild -project "Secret Notes – Private Notepad.xcodeproj" -scheme "Secret Notes – Private Notepad" -sdk iphonesimulator build
```

No test targets exist yet.

## Architecture

Simple SwiftUI app structure:

- **Entry point**: `Secret_Notes___Private_NotepadApp.swift` — `@main` App struct with a single `WindowGroup` scene
- **Primary UI**: `ContentView.swift` — main view loaded by the app
- **Assets**: `Assets.xcassets/` — contains AppIcon (1024x1024) and AccentColor

No data persistence, navigation, or state management is implemented yet. No view models or services exist.
