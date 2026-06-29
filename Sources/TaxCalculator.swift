import Foundation

// Represents the optimized tax math for one specific batch of shares
struct TaxOptimizationResult {
    let originalBuyDate: Date
    let sharesSold: Double
    let originalBuyPricePerShare: Double
    let bestMethod: String
    let taxableProfit: Double
}

// Packages the entire sale simulation together
struct TaxSimulationResult {
    let totalSharesSold: Double
    let totalSellingPrice: Double
    let totalTaxableProfit: Double
    let batchResults: [TaxOptimizationResult]
}

// 1. A helper structure to represent a batch of shares you currently own
struct AvailableLot {
    let originalBuyDate: Date
    let buyPricePerShare: Double
    var remainingQuantity: Double
    let feesPerShare: Double
}

class TaxCalculator {

    // 2. A function that reads history and outputs what you currently own
    static func calculateAvailableLots(for assetName: String, from allTransactions: [Transaction])
        -> [AvailableLot]
    {

        // Filter out other stocks and sort chronologically (oldest first)
        let assetTransactions =
            allTransactions
            .filter { $0.assetName == assetName }
            .sorted { $0.date < $1.date }

        var availableLots: [AvailableLot] = []

        for transaction in assetTransactions {
            if transaction.type == .buy {
                // 3. BUY: Add a new lot to our "currently owned" pool
                // We calculate the fee per share so we can deduct it accurately later
                let feesPerShare =
                    transaction.quantity > 0 ? (transaction.fees / transaction.quantity) : 0

                let newLot = AvailableLot(
                    originalBuyDate: transaction.date,
                    buyPricePerShare: transaction.pricePerShare,
                    remainingQuantity: transaction.quantity,
                    feesPerShare: feesPerShare
                )
                availableLots.append(newLot)

            } else if transaction.type == .sell {
                // 4. SELL: Deduct shares from the oldest lots (FIFO)
                var sharesToDeduct = transaction.quantity

                // Keep deducting until the sell order is fulfilled
                while sharesToDeduct > 0 && !availableLots.isEmpty {

                    if availableLots[0].remainingQuantity <= sharesToDeduct {
                        // The oldest lot is entirely consumed by this sale
                        sharesToDeduct -= availableLots[0].remainingQuantity
                        availableLots.removeFirst()  // Remove the empty lot
                    } else {
                        // The oldest lot has enough shares to cover the rest of the sale
                        availableLots[0].remainingQuantity -= sharesToDeduct
                        sharesToDeduct = 0
                    }
                }
            }
        }

        // 5. Return whatever is left after all historical sales are processed
        return availableLots
    }

    // Simulates a prospective sale and finds the most tax-efficient route
    static func simulateSale(
        assetName: String,
        sellQuantity: Double,
        sellPricePerShare: Double,
        sellFees: Double,
        sellDate: Date,
        allTransactions: [Transaction]
    ) -> TaxSimulationResult {

        // 1. Get the current actual holdings using the function we already wrote
        let availableLots = calculateAvailableLots(for: assetName, from: allTransactions)

        var remainingToSell = sellQuantity
        var totalTaxableProfit: Double = 0.0
        var batchResults: [TaxOptimizationResult] = []

        // Calculate the selling fee per share to distribute it evenly across batches
        let sellFeePerShare = sellQuantity > 0 ? (sellFees / sellQuantity) : 0

        // 2. Iterate through the oldest available lots first (FIFO)
        for lot in availableLots {
            if remainingToSell <= 0 { break }

            // Take either the whole lot, or just what we need to finish the sale
            let sharesFromThisLot = min(lot.remainingQuantity, remainingToSell)

            // --- STANDARD METHOD CALCULATION ---
            let sellingPriceForBatch = sharesFromThisLot * sellPricePerShare
            let buyingPriceForBatch = sharesFromThisLot * lot.buyPricePerShare
            let purchaseFeesForBatch = sharesFromThisLot * lot.feesPerShare
            let sellingFeesForBatch = sharesFromThisLot * sellFeePerShare

            let standardProfit =
                sellingPriceForBatch - buyingPriceForBatch - purchaseFeesForBatch
                - sellingFeesForBatch

            // --- HANKINTAMENO-OLETTAMA CALCULATION ---
            // Calculate exactly how many years the shares were held
            let calendar = Calendar.current
            let components = calendar.dateComponents(
                [.year], from: lot.originalBuyDate, to: sellDate)
            let yearsHeld = components.year ?? 0

            // Determine the correct percentage (40% for >= 10 years, 20% for < 10 years)
            let deemedCostPercentage = yearsHeld >= 10 ? 0.40 : 0.20
            let deemedCost = sellingPriceForBatch * deemedCostPercentage

            // Note: Actual purchase/selling fees are ignored in this method by law
            let deemedProfit = sellingPriceForBatch - deemedCost

            // --- OPTIMIZATION ---
            // The app automatically selects the method that results in the lowest taxable profit
            let bestProfit = min(standardProfit, deemedProfit)
            let chosenMethod =
                standardProfit < deemedProfit
                ? "Standard (FIFO)" : "Hankintameno-olettama (\(Int(deemedCostPercentage * 100))%)"

            totalTaxableProfit += bestProfit

            // Record the results for this specific batch
            batchResults.append(
                TaxOptimizationResult(
                    originalBuyDate: lot.originalBuyDate,
                    sharesSold: sharesFromThisLot,
                    originalBuyPricePerShare: lot.buyPricePerShare,
                    bestMethod: chosenMethod,
                    taxableProfit: bestProfit
                ))

            remainingToSell -= sharesFromThisLot
        }

        // 3. Package and return the final data
        let actualSharesSold = sellQuantity - remainingToSell

        return TaxSimulationResult(
            totalSharesSold: actualSharesSold,
            totalSellingPrice: actualSharesSold * sellPricePerShare,
            totalTaxableProfit: totalTaxableProfit,
            batchResults: batchResults
        )
    }

}
