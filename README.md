# Money Monitor

A personal finance app for macOS and iOS that helps you track and categorise your spending. Import bank statements, assign categories to transactions, and visualise where your money goes with interactive charts.

## Features

- **Statement import** - Import Halifax bank statements in CSV or PDF format
- **Auto-categorisation** - Transactions are automatically categorised based on description matching
- **Spending charts** - Interactive pie charts showing spending breakdown by category
- **Occasion tracking** - Tag transactions with occasions like holidays, birthdays, or weddings
- **PDF reports** - Export monthly spending summaries as PDF (macOS)
- **iOS share extension** - Import statements directly from the Files app on iOS
- **macOS menu bar** - Lives in your menu bar for quick access without cluttering the dock

## Platforms

| Platform | Minimum Version | Notes |
|----------|----------------|-------|
| macOS    | 14.0+          | Menu bar app with resizable popover |
| iOS      | 17.0+          | Full app with share extension |

## Building

The project uses [XcodeGen](https://github.com/yonaskolb/XcodeGen) to generate the Xcode project.

```bash
# Install XcodeGen if you haven't already
brew install xcodegen

# Generate the Xcode project
xcodegen generate

# Open in Xcode
open MoneyMonitor.xcodeproj
```

## Project Structure

```
Shared/          Helpers and models shared across platforms
  Helpers/       CSV and PDF importers
  Model/         SwiftData models (Transaction, Category, Occasion)
iOS/             iOS app and share extension
macOS/           macOS menu bar app
Tests/           Unit tests for importers
```

## Tech Stack

- SwiftUI
- SwiftData
- XcodeGen

## License

MIT
