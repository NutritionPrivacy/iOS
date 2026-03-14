import Foundation

struct CurrentUserState: Identifiable, Hashable, Sendable {
    let id: UUID
    let name: String
    let profile: PersonalProfile
    let goal: CurrentGoalSettings
    let currentWeight: CurrentWeightStatus
    let plan: NutritionPlan
    let preferences: AppPreferencesSummary

    static let singletonID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

    static func fromRecords(
        profile: Profile,
        goalSettings: GoalSettings,
        nutritionPlan: NutritionPlan,
        appPreferences: AppPreferences,
        latestWeightEntry: WeightEntry
    ) -> Self {
        Self(
            id: profile.id,
            name: profile.name,
            profile: PersonalProfile(
                sexForCalculation: profile.sexForCalculation,
                dateOfBirth: profile.dateOfBirth,
                height: BodyHeight(value: profile.heightValue, unit: profile.heightUnit)
            ),
            goal: CurrentGoalSettings(
                goal: goalSettings.goal,
                goalPace: goalSettings.goalPace,
                targetWeight: BodyWeight(
                    value: goalSettings.targetWeightValue,
                    unit: goalSettings.targetWeightUnit
                ),
                activityLevel: goalSettings.activityLevel,
                exerciseFrequency: goalSettings.exerciseFrequency,
                proteinPreference: goalSettings.proteinPreference,
                validSince: goalSettings.validSince
            ),
            currentWeight: CurrentWeightStatus(
                weight: BodyWeight(value: latestWeightEntry.weightValue, unit: latestWeightEntry.weightUnit),
                recordedAt: latestWeightEntry.recordedAt
            ),
            plan: NutritionPlan(
                id: nutritionPlan.id,
                dailyCalorieTarget: nutritionPlan.dailyCalorieTarget,
                proteinGrams: nutritionPlan.proteinGrams,
                carbGrams: nutritionPlan.carbGrams,
                fatGrams: nutritionPlan.fatGrams,
                estimatedWeeklyChange: nutritionPlan.estimatedWeeklyChange,
                generatedAt: nutritionPlan.generatedAt
            ),
            preferences: AppPreferencesSummary(
                weeklyCheckInDay: appPreferences.weeklyCheckInDay,
                completedAt: appPreferences.completedAt
            )
        )
    }

    var planningInput: NutritionPlanningInput {
        NutritionPlanningInput(
            goal: goal.goal,
            goalPace: goal.goalPace,
            sexForCalculation: profile.sexForCalculation,
            dateOfBirth: profile.dateOfBirth,
            height: profile.height,
            currentWeight: currentWeight.weight,
            targetWeight: goal.targetWeight,
            activityLevel: goal.activityLevel,
            exerciseFrequency: goal.exerciseFrequency,
            proteinPreference: goal.proteinPreference
        )
    }

    var nutritionPlan: NutritionPlan {
        plan
    }
}

struct PersonalProfile: Hashable, Sendable {
    let sexForCalculation: SexForCalculation?
    let dateOfBirth: Date
    let height: BodyHeight
}

struct CurrentGoalSettings: Hashable, Sendable {
    let goal: NutritionGoal
    let goalPace: GoalPace
    let targetWeight: BodyWeight
    let activityLevel: ActivityLevel
    let exerciseFrequency: ExerciseFrequency
    let proteinPreference: ProteinPreference
    let validSince: Date
}

struct CurrentWeightStatus: Hashable, Sendable {
    let weight: BodyWeight
    let recordedAt: Date
}

struct AppPreferencesSummary: Hashable, Sendable {
    let weeklyCheckInDay: WeeklyCheckInDay
    let completedAt: Date
}
