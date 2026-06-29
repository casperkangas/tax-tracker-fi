import SwiftData
import SwiftUI

struct TransactionDetailView: View {
    // 1. The specific transaction we clicked on
    let transaction: Transaction

    // 2. Fetch all transactions to reconstruct history
    @Query(sort: \Transaction.date, order: .forward) private var allTransactions: [Transaction]

    // 3. A computed property to run the historical audit on-the-fly
    var auditResult: TaxSimulationResult? {
        // We only calculate taxes for sales
        guard transaction.type == .sell else { return nil }

        // Filter history to ONLY include transactions for this asset that happened BEFORE this sale
        let pastTransactions = allTransactions.filter {
            $0.assetName == transaction.assetName && $0.date <= transaction.date
                && $0.id != transaction.id  // Exclude the sell transaction itself from the history pool
        }

        // Run the engine exactly as it would have looked on the day of the sale
        return TaxCalculator.simulateSale(
            assetName: transaction.assetName,
            sellQuantity: transaction.quantity,
            sellPricePerShare: transaction.pricePerShare,
            sellFees: transaction.fees,
            sellDate: transaction.date,
            allTransactions: pastTransactions
        )
    }

    var body: some View {
        List {
            Section("Transaction Details") {
                LabeledContent("Asset", value: transaction.assetName)
                LabeledContent("Type", value: transaction.type.rawValue)
                LabeledContent(
                    "Date", value: transaction.date.formatted(date: .long, time: .omitted))

                // Using .formatted ensures clean display with exactly 0 or 2 decimals
                LabeledContent(
                    "Quantity",
                    value:
                        "\(transaction.quantity.formatted(.number.precision(.fractionLength(0)))) shares"
                )
                LabeledContent(
                    "Price per Share",
                    value:
                        "\(transaction.pricePerShare.formatted(.number.precision(.fractionLength(2)))) €"
                )
                LabeledContent(
                    "Fees",
                    value: "\(transaction.fees.formatted(.number.precision(.fractionLength(2)))) €")
                LabeledContent(
                    "Total Value",
                    value:
                        "\((transaction.quantity * transaction.pricePerShare).formatted(.number.precision(.fractionLength(2)))) €"
                )
            }

            // 4. Only show the tax breakdown if this was a sell event
            if let result = auditResult {
                Section("Tax Calculation Audit") {
                    HStack {
                        Text("Total Taxable Profit")
                            .fontWeight(.bold)
                        Spacer()
                        Text("\(result.totalTaxableProfit, specifier: "%.2f") €")
                            .fontWeight(.bold)
                            .foregroundStyle(result.totalTaxableProfit > 0 ? .red : .green)
                    }

                    ForEach(result.batchResults, id: \.originalBuyDate) { batch in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(
                                "Shares from \(batch.originalBuyDate, format: .dateTime.year().month().day())"
                            )
                            .font(.subheadline)
                            .fontWeight(.semibold)

                            Text("Sold: \(batch.sharesSold, specifier: "%.0f")")
                                .font(.caption)

                            Text("Method: \(batch.bestMethod)")
                                .font(.caption)
                                .foregroundStyle(.blue)

                            Text("Taxable Profit: \(batch.taxableProfit, specifier: "%.2f") €")
                                .font(.caption)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Audit: \(transaction.assetName)")
    }
}
