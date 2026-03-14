# Money Monitor

See exactly where your money goes. Import your Halifax bank statements, sort your spending into categories, and get a clear picture of your finances — all from your menu bar.

Your data stays on your device. No accounts, no servers, no tracking.

## What you can do

- **Import statements** — Drop in a CSV or PDF from Halifax and you're away
- **Sort your spending** — Categorise a payment once and matching ones are done automatically
- **Track life events** — Tag spending for holidays, birthdays, Christmas, and more with Occasions
- **See the bigger picture** — Interactive charts show you where your money's going each month
- **Export reports** — Download a monthly spending summary as PDF (macOS)
- **Share extension** — Import statements straight from the Files app on iOS
- **Menu bar access** — Quick glance at your spending without leaving what you're doing (macOS)

## Platforms

| Platform | Minimum Version | Notes |
|----------|----------------|-------|
| macOS    | 14.0+          | Menu bar app with resizable popover |
| iOS      | 17.0+          | Full app with share extension |

## Getting started

The project uses [XcodeGen](https://github.com/yonaskolb/XcodeGen) to generate the Xcode project.

```bash
brew install xcodegen
xcodegen generate
open MoneyMonitor.xcodeproj
```

## Project structure

```
Shared/
  Helpers/         CSV and PDF importers, currency formatting
  Model/           SwiftData models (Transaction, Category, Occasion, AppSettings)
iOS/
  App/             iOS app entry point
  Views/           ContentView, TransactionList, CategoryPicker, SpendingChart, Settings
  Resources/       Asset catalogue, entitlements, Info.plist
  ShareExtension/  Import statements from the Files app
macOS/
  App/             macOS app entry point (MenuBarExtra)
  Helpers/         Launch-at-login helper
  Views/           MenuBarView, TransactionList, CategoryPicker, SpendingChart, Settings, About, Onboarding
  Resources/       Asset catalogue, entitlements, Info.plist
Tests/             Unit tests for importers
```

## Built with

- SwiftUI
- SwiftData
- XcodeGen

## Licence

MIT
