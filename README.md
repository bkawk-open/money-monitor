# Money Monitor

A personal finance app for macOS and iOS designed for Halifax bank customers. Import your bank statements, categorise transactions, and visualise where your money goes with interactive charts.

## Features

- **Statement import** — Import Halifax bank statements in CSV or PDF format
- **Auto-categorisation** — Assign a category once and all matching transactions are categorised automatically
- **14 default categories** — Housing, Bills & Utilities, Supermarkets, Transport, Shopping, Eating Out, Subscriptions, Travel, Health & Fitness, Entertainment, Financial, Transfers, Gambling, and Other
- **Occasion tracking** — Tag spending for holidays, birthdays, weddings, Christmas, and 11 other life events
- **Spending charts** — Interactive donut chart with hover details and category breakdown
- **PDF reports** — Export monthly spending summaries as PDF (macOS)
- **Customisable menu bar icon** — Colour donut chart by default, with a monochrome option in settings
- **Help & FAQ** — Built-in knowledge base and contact form for feedback
- **iOS share extension** — Import statements directly from the Files app
- **macOS menu bar app** — Quick access without cluttering the dock
- **Data stays on device** — No servers, no accounts, no tracking

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
Shared/
  Helpers/         CSV and PDF importers
  Model/           SwiftData models (Transaction, Category, Occasion, AppSettings)
iOS/
  App/             iOS app entry point
  Views/           ContentView, TransactionList, CategoryPicker, SpendingChart, Settings
  Resources/       Asset catalogue, entitlements, Info.plist
  ShareExtension/  Share extension for importing from Files app
macOS/
  App/             macOS app entry point (MenuBarExtra)
  Helpers/         Launch-at-login helper
  Views/           MenuBarView, TransactionList, CategoryPicker, SpendingChart, Settings, About, Onboarding
  Resources/       Asset catalogue (app icon + menu bar icons), entitlements, Info.plist
Tests/             Unit tests for importers
```

## Tech Stack

- SwiftUI
- SwiftData
- XcodeGen

## Licence

MIT
