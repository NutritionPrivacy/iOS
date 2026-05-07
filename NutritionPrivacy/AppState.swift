import Observation
import SQLiteData
import Foundation
import UIKit

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

    var macrosModel: (protein: MacroProgressModel, carbs: MacroProgressModel, fat: MacroProgressModel) {
        let proteinGoal = nutritionPlan?.proteinGrams ?? 0
        let carbGoal = nutritionPlan?.carbGrams ?? 0
        let fatGoal = nutritionPlan?.fatGrams ?? 0

        let consumedProtein = 0
        let consumedCarbs = 0
        let consumedFat = 0

        return (
            protein: MacroProgressModel(
                name: "Protein",
                consumed: consumedProtein,
                goal: proteinGoal,
                unit: "g",
                color: UIColor(red: 0.28, green: 0.55, blue: 0.98, alpha: 1)
            ),
            carbs: MacroProgressModel(
                name: "Carbs",
                consumed: consumedCarbs,
                goal: carbGoal,
                unit: "g",
                color: UIColor(red: 0.96, green: 0.66, blue: 0.19, alpha: 1)
            ),
            fat: MacroProgressModel(
                name: "Fat",
                consumed: consumedFat,
                goal: fatGoal,
                unit: "g",
                color: UIColor(red: 0.96, green: 0.39, blue: 0.47, alpha: 1)
            )
        )
    }

    var hydrationConsumedMl: Int = 0
    let hydrationGoalMl: Int = 2500

    var hydrationModel: HydrationModel {
        HydrationModel(consumedMl: hydrationConsumedMl, goalMl: hydrationGoalMl)
    }

    var mealsSectionModel: MealsSectionModel {
        MealsSectionModel(entries: [])
    }

    @ObservationIgnored
    @FetchOne
    var profile: Profile?

    @ObservationIgnored
    @FetchOne
    var nutritionPlan: NutritionPlan?
}
