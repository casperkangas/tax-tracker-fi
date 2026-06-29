import SwiftData
import SwiftUI

struct ContentView: View {
    // This state variable keeps track of which sidebar item is currently selected.
    // It defaults to showing the transactions list first.
    @State private var selectedTab: SidebarItem? = .transactions

    // We define our sidebar options clearly using an enum
    enum SidebarItem: Hashable {
        case portfolio
        case transactions
        case taxSimulator
    }

    var body: some View {
        // NavigationSplitView creates the native macOS sidebar layout
        NavigationSplitView {
            // The Sidebar panel
            List(selection: $selectedTab) {
                NavigationLink(value: SidebarItem.portfolio) {
                    Label("Portfolio", systemImage: "chart.pie")
                }
                NavigationLink(value: SidebarItem.transactions) {
                    Label("Transactions", systemImage: "list.bullet.rectangle.portrait")
                }
                NavigationLink(value: SidebarItem.taxSimulator) {
                    Label("Tax Simulator", systemImage: "banknote")
                }
            }
            .navigationTitle("Tax Tracker")
            // This modifier ensures the sidebar doesn't get collapsed completely
            .navigationSplitViewColumnWidth(min: 150, ideal: 200, max: 250)

        } detail: {
            // The Main Content panel (changes based on what is selected in the sidebar)
            switch selectedTab {
            case .portfolio:
                Text("Portfolio View (Coming Soon)")
                    .font(.title)
                    .foregroundStyle(.secondary)
            case .transactions:
                TransactionsView()
            case .taxSimulator:
                TaxSimulatorView()
            case nil:
                Text("Select an item from the sidebar")
                    .foregroundStyle(.secondary)
            }
        }
    }
}
