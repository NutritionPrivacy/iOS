import Foundation
import SQLiteData

@Table("nutritionPlans")
struct NutritionPlan: Codable, Hashable, Sendable {
    let id: UUID = UUID()
    let dailyCalorieTarget: Int
    let proteinGrams: Int
    let carbGrams: Int
    let fatGrams: Int
    let estimatedWeeklyChange: Double
    let generatedAt: Date = Date()

    var calorieSummary: LocalizedStringResource { "\(dailyCalorieTarget) kcal/day" }
    var macroSummary: LocalizedStringResource {
        "Protein \(proteinGrams)g • Carbs \(carbGrams)g • Fat \(fatGrams)g"
    }
}
