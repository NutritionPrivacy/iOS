import Dependencies
import Foundation

struct NutritionPlanCalculator: Sendable {
    var calculate: @Sendable (_ draft: OnboardingDraft, _ generatedAt: Date) throws -> NutritionPlan
}

extension NutritionPlanCalculator: DependencyKey {
    static var liveValue: NutritionPlanCalculator {
        NutritionPlanCalculator(calculate: { draft, generatedAt in
            let inputs = try PlanInputs(draft: draft, generatedAt: generatedAt)
            let calorieTarget = calorieTarget(for: inputs)
            let proteinGrams = proteinGrams(for: inputs)
            let fatGrams = fatGrams(for: inputs, calorieTarget: calorieTarget)
            let carbGrams = carbGrams(
                calorieTarget: calorieTarget,
                proteinGrams: proteinGrams,
                fatGrams: fatGrams
            )
            let estimatedWeeklyChange = estimatedWeeklyChange(for: inputs)

            return NutritionPlan(
                id: UUID(),
                dailyCalorieTarget: calorieTarget,
                proteinGrams: proteinGrams,
                carbGrams: carbGrams,
                fatGrams: fatGrams,
                estimatedWeeklyChange: estimatedWeeklyChange,
                generatedAt: generatedAt
            )
        })
    }

    private struct PlanInputs {
        let goal: NutritionGoal
        let goalPace: GoalPace
        let activityLevel: ActivityLevel
        let exerciseFrequency: ExerciseFrequency
        let proteinPreference: ProteinPreference
        let age: Int
        let heightInCentimeters: Double
        let weightInKilograms: Double
        let targetWeightInKilograms: Double
        let sexForCalculation: SexForCalculation?

        init(draft: OnboardingDraft, generatedAt: Date) throws {
            guard
                let goal = draft.goal,
                let activityLevel = draft.activityLevel
            else {
                throw OnboardingPersistenceError.incompleteDraft
            }

            self.goal = goal
            self.goalPace = draft.goalPaceOrDefault
            self.activityLevel = activityLevel
            self.exerciseFrequency = draft.exerciseFrequencyOrDefault
            self.proteinPreference = draft.proteinPreferenceOrDefault
            self.age = NutritionPlanCalculator.age(from: draft.dateOfBirth, at: generatedAt)
            self.heightInCentimeters = draft.height.centimeters
            self.weightInKilograms = draft.currentWeight.kilograms
            self.targetWeightInKilograms = draft.targetWeight.kilograms
            self.sexForCalculation = draft.sexForCalculation
        }
    }

    private nonisolated static func age(from dateOfBirth: Date, at generatedAt: Date) -> Int {
        max(18, Calendar.autoupdatingCurrent.dateComponents([.year], from: dateOfBirth, to: generatedAt).year ?? 30)
    }

    private nonisolated static func calorieTarget(for inputs: PlanInputs) -> Int {
        let maintenanceCalories = maintenanceCalories(for: inputs)
        let paceAdjustment = paceAdjustment(for: inputs.goalPace)

        return switch inputs.goal {
        case .loseWeight:
            Int(max(1_200, maintenanceCalories - paceAdjustment).rounded())
        case .maintainWeight:
            Int(maintenanceCalories.rounded())
        case .gainWeight:
            Int((maintenanceCalories + paceAdjustment).rounded())
        }
    }

    private nonisolated static func maintenanceCalories(for inputs: PlanInputs) -> Double {
        basalMetabolicRate(for: inputs) * (inputs.activityLevel.activityFactor + inputs.exerciseFrequency.factorAdjustment)
    }

    private nonisolated static func basalMetabolicRate(for inputs: PlanInputs) -> Double {
        (10 * inputs.weightInKilograms)
        + (6.25 * inputs.heightInCentimeters)
        - (5 * Double(inputs.age))
        + sexAdjustment(for: inputs.sexForCalculation)
    }

    private nonisolated static func sexAdjustment(for sexForCalculation: SexForCalculation?) -> Double {
        switch sexForCalculation {
        case .female:
            -161
        case .male:
            5
        case nil:
            -78
        }
    }

    private nonisolated static func paceAdjustment(for goalPace: GoalPace) -> Double {
        switch goalPace {
        case .conservative:
            250
        case .moderate:
            450
        case .aggressive:
            650
        }
    }

    private nonisolated static func proteinGrams(for inputs: PlanInputs) -> Int {
        Int((inputs.targetWeightInKilograms * inputs.proteinPreference.gramsPerKilogram).rounded())
    }

    private nonisolated static func fatGrams(for inputs: PlanInputs, calorieTarget: Int) -> Int {
        Int(max(35, (Double(calorieTarget) * fatRatio(for: inputs.goal) / 9).rounded()))
    }

    private nonisolated static func fatRatio(for goal: NutritionGoal) -> Double {
        switch goal {
        case .loseWeight:
            0.28
        case .maintainWeight:
            0.30
        case .gainWeight:
            0.27
        }
    }

    private nonisolated static func carbGrams(calorieTarget: Int, proteinGrams: Int, fatGrams: Int) -> Int {
        let proteinCalories = proteinGrams * 4
        let fatCalories = fatGrams * 9
        let carbCalories = max(0, calorieTarget - proteinCalories - fatCalories)
        return Int((Double(carbCalories) / 4).rounded())
    }

    private nonisolated static func estimatedWeeklyChange(for inputs: PlanInputs) -> Double {
        let magnitude = weeklyChangeMagnitude(for: inputs.goalPace)
        return switch inputs.goal {
        case .loseWeight:
            -magnitude
        case .maintainWeight:
            0
        case .gainWeight:
            magnitude
        }
    }

    private nonisolated static func weeklyChangeMagnitude(for goalPace: GoalPace) -> Double {
        switch goalPace {
        case .conservative:
            0.25
        case .moderate:
            0.5
        case .aggressive:
            0.75
        }
    }
}

extension DependencyValues {
    var nutritionPlanCalculator: NutritionPlanCalculator {
        get { self[NutritionPlanCalculator.self] }
        set { self[NutritionPlanCalculator.self] = newValue }
    }
}
