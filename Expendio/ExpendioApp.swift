import SwiftUI
import SwiftData

@main
struct ExpendioApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 1100, minHeight: 700)
                .preferredColorScheme(.dark)
                .background(AppTheme.background)
        }
        .modelContainer(for: [Expense.self, ExpenseCategory.self, Profile.self])
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1300, height: 850)
    }
}
