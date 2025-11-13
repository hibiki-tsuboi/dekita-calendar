# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

- **常に日本語で回答する**

## Project Overview

DekitaCalendar is a native iOS application built with SwiftUI and SwiftData. The project uses Xcode as the primary development environment.

## Architecture

### Data Layer
- **SwiftData**: The app uses SwiftData for persistence with a single `Item` model
- **ModelContainer**: Configured in `DekitaCalendarApp.swift:13-24` with a shared container instance
- **Schema**: Defined with `Schema([Item.self])` and uses persistent storage (`isStoredInMemoryOnly: false`)

### App Structure
- **Entry Point**: `DekitaCalendarApp` (DekitaCalendarApp.swift) - Main app struct with `@main` attribute
- **Main View**: `ContentView` (ContentView.swift) - Uses `NavigationSplitView` with master-detail pattern
- **Data Model**: `Item` (Item.swift) - Simple `@Model` class with a single `timestamp: Date` property

### Key Patterns
- The app follows SwiftUI's data flow with `@Environment(\.modelContext)` for database operations
- `@Query` property wrapper automatically fetches and updates `Item` objects
- Model context injection happens at the root level via `.modelContainer(sharedModelContainer)`

## Development Commands

### Building and Running
```bash
# Open project in Xcode
open DekitaCalendar.xcodeproj

# Build from command line (requires xcodebuild)
xcodebuild -project DekitaCalendar.xcodeproj -scheme DekitaCalendar build

# Run tests (when test targets are added)
xcodebuild test -project DekitaCalendar.xcodeproj -scheme DekitaCalendar -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Code Structure
- All source files are located in `DekitaCalendar/` directory
- Assets and resources in `DekitaCalendar/Assets.xcassets/`
- Swift files use consistent header comments with creation date and author

## Important Notes

- The project currently uses a basic Item model with timestamp - this appears to be template/starter code that will likely be replaced with calendar-specific models
- SwiftData requires iOS 17.0+ minimum deployment target
- The app uses `fatalError` for ModelContainer creation failures (DekitaCalendarApp.swift:22), which is acceptable for critical initialization failures
