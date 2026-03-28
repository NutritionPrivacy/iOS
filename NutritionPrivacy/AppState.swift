import Observation
import SQLiteData
import Foundation

@MainActor
@Observable
final class AppState {
    var isSetup: Bool {
        profile != nil
    }

    var calorieProgressGaugeModel: CalorieProgressGaugeModel {
        guard let nutritionPlan else {
            return .empty
        }

        let consumedCalories = 0
        let remainingCalories = max(nutritionPlan.dailyCalorieTarget - consumedCalories, 0)
        let calorieTarget = max(nutritionPlan.dailyCalorieTarget, 1)
        let progress = Double(consumedCalories) / Double(calorieTarget)

        return CalorieProgressGaugeModel(
            title: "Remaining",
            highlightedValue: remainingCalories.formatted(.number.grouping(.automatic)),
            detailText: "of \(nutritionPlan.dailyCalorieTarget.formatted(.number.grouping(.automatic))) kcal",
            progress: progress
        )
    }

    @ObservationIgnored
    @FetchOne
    var profile: Profile?

    @ObservationIgnored
    @FetchOne
    var nutritionPlan: NutritionPlan?
}
