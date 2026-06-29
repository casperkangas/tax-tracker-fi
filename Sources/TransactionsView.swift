import SwiftData
import SwiftUI

struct TransactionsView: View {
    // 1. Access the database environment
    @Environment(\.modelContext) private var modelContext

    // 2. Fetch all transactions, sorted by newest first
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]

    // 3. NEW: State variable to control the visibility of the Add Transaction sheet
    @State private var isShowingAddSheet = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(transactions) { transaction in
                    // Wrap the row in a NavigationLink
                    NavigationLink(destination: TransactionDetailView(transaction: transaction)) {
                        VStack(alignment: .leading) {
                            HStack {
                                Text(transaction.assetName)
                                    .font(.headline)
                                Spacer()
                                Text(transaction.type.rawValue)
                                    .foregroundStyle(transaction.type == .buy ? .green : .red)
                                    .fontWeight(.bold)
                            }

                            Text(
                                "\(transaction.quantity, specifier: "%.0f") shares @ \(transaction.pricePerShare, specifier: "%.2f") €"
                            )
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                            Text(transaction.date, format: .dateTime.year().month().day())
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete(perform: deleteTransactions)
            }
            .navigationTitle("Transactions")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    // 4. NEW: Update the button action to trigger the sheet
                    Button(action: {
                        isShowingAddSheet = true
                    }) {
                        Label("Add Transaction", systemImage: "plus")
                    }
                }
            }
            // 5. NEW: Attach the sheet modifier directly to the List
            .sheet(isPresented: $isShowingAddSheet) {
                AddTransactionView()
            }
        }
    }

    private func deleteTransactions(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(transactions[index])
        }
    }
}
