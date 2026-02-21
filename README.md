# Expendio

Expendio is a beautifully designed, native macOS personal finance tracker built entirely in SwiftUI and SwiftData. It focuses on a clean, modern aesthetic similar to premium productivity apps, giving you a lightning-fast offline experience to manage your expenses, analyze spending trends, and handle multiple profiles.

## Features

* **Multi-Profile Support:** Manage expenses for different people, projects, or small businesses by creating separate profiles. Each profile features customizable names and colors.
* **Frictionless Expense Tracking:** Quickly log manual expenses, assign them to distinct categories (with native Apple SF Symbol icons), and add optional notes.
* **Rich Dashboard & Reports:**
  * **DashboardView**: See a breakdown of "This Month," "Daily Average," and "Top Category" at a glance. Includes an interactive Area/Line chart for 30-day spending trends and Sector (Pie) charts for category breakdowns.
  * **ReportsView**: Analyze long-term spending across Monthly, Quarterly, and Yearly periods. Switch seamlessly between detailed Bar charts and Line graphs using modern `Swift Charts`.
* **Splitwise Importer:** Effortlessly import your expenses and group balances from Splitwise natively.
* **Data Portability:** Export your entire database (Profiles, Categories, Expenses) to a single JSON file. You can import this JSON file back into the app on another Mac to seamlessly restore or transfer your data.
* **Offline First & Secure:** No `URLSession` API calls or cloud servers are required to run the core app. All data is stored instantly and securely on-device using SwiftData.
* **Optimized Performance:** Uses shared static formatting caches for lightning fast scrolling and chart rendering.

## Requirements

* **OS:** macOS 14.0 (Sonoma) or later
* **Xcode:** 15.0 or later (to build from source)
* **Frameworks:** SwiftUI, SwiftData, Charts, UniformTypeIdentifiers

## Getting Started

1. **Clone the repository:**

   ```bash
   git clone https://github.com/yourusername/Expendio_Mac.git
   ```

2. **Open the project:**
   Navigate into the downloaded folder and open `Expendio.xcodeproj` in Xcode.

   ```bash
   cd Expendio_Mac
   open Expendio.xcodeproj
   ```

3. **Run the App:**
   Ensure your target destination is set to **My Mac** at the top bar of Xcode, and click the Play (▶) button or hit `Cmd + R` (`⌘R`).

## Architecture

Expendio is built using standard Apple paradigms:

* **UI Layer:** SwiftUI. Organized into Views (`DashboardView`, `ReportsView`, `ExpenseListView`) and reusable styling `Components` (`CategoryRow`, `PanelActionButton`).
* **Data Layer:** SwiftData. Models include `Profile`, `Expense`, and `ExpenseCategory`.
* **Theming:** A centralized `AppTheme` struct handles semantic, dynamic color generation and glassmorphic card styling.

## Security & Privacy

Expendio is designed with your privacy in mind:

* **No Telemetry**: No external analytics SDKs are bundled.
* **Sandbox Environment**: Standard macOS App Sandbox restrictions apply. The app only accesses files explicitly exported/imported by the user for data backups.

## Contributing

Contributions, issues, and feature requests are welcome!

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'feat: Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request
