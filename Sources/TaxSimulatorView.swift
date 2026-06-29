import SwiftData
import SwiftUI

struct TaxSimulatorView: View {
    // 1. Fetch all transactions to feed into the tax engine
    @Query(sort: \Transaction.date, order: .forward) private var transactions: [Transaction]

    // 2. State variables for the user's simulation inputs
    @State private var selectedAsset: String = ""
    @State private var sellQuantity: Double = 0.0
    @State private var sellPricePerShare: Double = 0.0
    @State private var sellFees: Double = 0.0
    @State private var sellDate: Date = Date()

    // 3. State variable to hold the result of the simulation
    @State private var simulationResult: TaxSimulationResult? = nil

    // 4. A computed property to find all unique asset names in the portfolio
    var uniqueAssets: [String] {
        let assets = transactions.map { $0.assetName }
        return Array(Set(assets)).sorted()
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Simulation Parameters") {
                    // Picker dynamically lists only the assets you actually own
                    Picker("Select Asset", selection: $selectedAsset) {
                        Text("Select an asset").tag("")
                        ForEach(uniqueAssets, id: \.self) { asset in
                            Text(asset).tag(asset)
                        }
                    }

                    TextField("Quantity to Sell", value: $sellQuantity, format: .number)
                    TextField(
                        "Estimated Price per Share (€)", value: $sellPricePerShare, format: .number)
                    TextField("Estimated Selling Fees (€)", value: $sellFees, format: .number)
                    DatePicker(
                        "Planned Sell Date", selection: $sellDate, displayedComponents: .date)
                }

                Section {
                    Button("Run Simulation") {
                        runSimulation()
                    }
                    // Prevent running the simulation if no asset is selected or quantity is 0
                    .disabled(selectedAsset.isEmpty || sellQuantity <= 0)
                }

                // 5. Only show the results section if a simulation has been run
                if let result = simulationResult {
                    Section("Simulation Results") {
                        HStack {
                            Text("Total Taxable Profit")
                                .fontWeight(.bold)
                            Spacer()
                            Text("\(result.totalTaxableProfit, specifier: "%.2f") €")
                                .fontWeight(.bold)
                                // Red for profit (taxes owed), Green for loss
                                .foregroundStyle(result.totalTaxableProfit > 0 ? .red : .green)
                        }

                        // 6. Display the breakdown for every batch of shares sold
                        ForEach(result.batchResults, id: \.originalBuyDate) { batch in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(
                                    "Shares from \(batch.originalBuyDate, format: .dateTime.year().month().day())"
                                )
                                .font(.subheadline)
                                .fontWeight(.semibold)

                                Text("Sold: \(batch.sharesSold, specifier: "%.4f")")
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
            .formStyle(.grouped)
            .navigationTitle("Tax Simulator")
        }
    }

    // 7. The function that connects the UI to your TaxCalculator engine
    private func runSimulation() {
        simulationResult = TaxCalculator.simulateSale(
            assetName: selectedAsset,
            sellQuantity: sellQuantity,
            sellPricePerShare: sellPricePerShare,
            sellFees: sellFees,
            sellDate: sellDate,
            allTransactions: transactions
        )
    }
}
