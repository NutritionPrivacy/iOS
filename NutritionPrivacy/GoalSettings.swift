import Foundation
import SQLiteData

@Table("goalSettings")
struct GoalSettings: Identifiable, Hashable, Sendable {
    let id: UUID
    let goal: NutritionGoal
    let goalPace: GoalPace
    let targetWeightValue: Double
    let targetWeightUnit: WeightUnit
    let activityLevel: ActivityLevel
    let exerciseFrequency: ExerciseFrequency
    let proteinPreference: ProteinPreference
    let validSince: Date
}
