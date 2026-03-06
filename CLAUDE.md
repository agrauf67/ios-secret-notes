# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Secret Notes is an iOS clone of the Android app `de.djvlk.secretnotes`. It's a feature-rich encrypted note-taking app built with **SwiftUI** and **SwiftData**.

- **Bundle ID**: `de.djvlk.Secret-Notes---Private-Notepad`
- **Deployment Target**: iOS 26.2
- **Swift Version**: 5.0
- **No external dependencies** — uses only Apple frameworks (SwiftUI, SwiftData, CryptoKit, LocalAuthentication, MultipeerConnectivity, StoreKit, AVFoundation, UserNotifications)

## Build

```bash
xcodebuild -project "Secret Notes – Private Notepad.xcodeproj" -scheme "Secret Notes – Private Notepad" -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

No test targets exist yet.

## Architecture

SwiftUI app with `@Observable` pattern (not MVVM with ViewModels — state is managed via SwiftData `@Query` and `@Environment`).

### Entry Point & Navigation
- `Secret_Notes___Private_NotepadApp.swift` — `@main`, sets up SwiftData container and environment objects (AuthenticationManager, AppSettings, StoreManager)
- `ContentView.swift` — TabView with 7 tabs: Notes, Categories, Folders, Data, Trash, Archive, Settings. Lock screen overlay when locked.

### Data Layer (SwiftData Models in `Models/`)
- `SecretNote` — main entity with title, text, itemsJSON, spreadsheetJSON, audioFilePath, noteType, rating, pin, delete/archive flags, color, reminder, relationships to Category/Folder
- `Category` — many-to-many with SecretNote
- `Folder` — hierarchical (self-referencing parent), one-to-many with SecretNote
- `NoteAttachment` — file attachment metadata
- `NoteHistory` — version snapshots created on each save
- Checklist/Spreadsheet data stored as JSON strings in SecretNote, decoded via computed properties

### Note Types
5 types: TEXT, CHECKLIST, SPREADSHEET, MARKDOWN, AUDIO — each has dedicated editor and display views in `Views/`.

### Security (`Security/`)
- `AuthenticationManager` — PIN (SHA-256 hashed) and biometric (Face ID/Touch ID) auth, auto-lock with configurable timeout
- `EncryptionManager` — AES-GCM encryption with Keychain-stored DEK, format `v1:<b64(nonce)>:<b64(ct+tag)>`
- `LockScreenView` — PIN keypad and biometric unlock UI

### Sync (`Sync/`)
- `DeviceSyncManager` — MultipeerConnectivity P2P sync with MCSession, delta sync via syncId/timestamps

### Key Patterns
- Soft delete: `isDeleted`/`isArchived` flags, filtered via `#Predicate` in `@Query`
- Note content polymorphism: `noteTypeRaw` string + switch statements in edit/detail/list views
- Settings persisted via UserDefaults in `AppSettings` observable
- Color hex strings converted via `Color(hex:)` extension in FolderManagerView

### Localization
English (primary) and German via `Localizable.xcstrings`.
