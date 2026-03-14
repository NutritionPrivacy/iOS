import Dependencies
import Foundation
import SQLiteData

struct OnboardingPersistenceClient: Sendable {
    var loadCompletedProfile: @Sendable () async throws -> CurrentUserState?
    var completeOnboarding: @Sendable (OnboardingDraft) async throws -> CurrentUserState
}

enum OnboardingPersistenceError: Error {
    case incompleteDraft
}

extension OnboardingPersistenceClient {
    static let liveValue = OnboardingPersistenceClient(
        loadCompletedProfile: {
            @Dependency(\.defaultDatabase) var database
            return try database.read { db in
                try loadCompletedProfile(from: db)
            }
        },
        completeOnboarding: { draft in
            @Dependency(\.defaultDatabase) var database
            @Dependency(\.nutritionPlanClient) var nutritionPlanClient

            guard
                let name = draft.trimmedName,
                let weeklyCheckInDay = draft.weeklyCheckInDay,
                let planningInput = draft.planningInput
            else {
                throw OnboardingPersistenceError.incompleteDraft
            }

            let plan = nutritionPlanClient.plan(planningInput)
            let targetWeight = planningInput.targetWeight.converted(to: planningInput.currentWeight.unit)
            let completedAt = Date()
            let profile = Profile(
                id: CurrentUserState.singletonID,
                name: name,
                sexForCalculation: planningInput.sexForCalculation,
                dateOfBirth: planningInput.dateOfBirth,
                heightValue: planningInput.height.value,
                heightUnit: planningInput.height.unit
            )
            let goalSettings = GoalSettings(
                id: CurrentUserState.singletonID,
                goal: planningInput.goal,
                goalPace: planningInput.goalPace,
                targetWeightValue: targetWeight.value,
                targetWeightUnit: planningInput.currentWeight.unit,
                activityLevel: planningInput.activityLevel,
                exerciseFrequency: planningInput.exerciseFrequency,
                proteinPreference: planningInput.proteinPreference,
                validSince: completedAt
            )
            let nutritionPlan = NutritionPlan(
                id: CurrentUserState.singletonID,
                dailyCalorieTarget: plan.dailyCalorieTarget,
                proteinGrams: plan.proteinGrams,
                carbGrams: plan.carbGrams,
                fatGrams: plan.fatGrams,
                estimatedWeeklyChange: plan.estimatedWeeklyChange,
                generatedAt: completedAt
            )
            let appPreferences = AppPreferences(
                id: CurrentUserState.singletonID,
                weeklyCheckInDay: weeklyCheckInDay,
                completedAt: completedAt
            )
            let weightEntry = WeightEntry(
                id: UUID(),
                profileID: CurrentUserState.singletonID,
                weightValue: planningInput.currentWeight.value,
                weightUnit: planningInput.currentWeight.unit,
                recordedAt: completedAt
            )

            try database.write { db in
                try Profile.upsert { profile }.execute(db)
                try GoalSettings.upsert { goalSettings }.execute(db)
                try NutritionPlan.upsert { nutritionPlan }.execute(db)
                try AppPreferences.upsert { appPreferences }.execute(db)
                try WeightEntry.insert { weightEntry }.execute(db)
            }
            return CurrentUserState.fromRecords(
                profile: profile,
                goalSettings: goalSettings,
                nutritionPlan: nutritionPlan,
                appPreferences: appPreferences,
                latestWeightEntry: weightEntry
            )
        }
    )
}

extension DependencyValues {
    var onboardingPersistenceClient: OnboardingPersistenceClient {
        get { self[OnboardingPersistenceClientKey.self] }
        set { self[OnboardingPersistenceClientKey.self] = newValue }
    }
}

private enum OnboardingPersistenceClientKey: DependencyKey {
    static let liveValue = OnboardingPersistenceClient.liveValue
}

private func loadCompletedProfile(from db: Database) throws -> CurrentUserState? {
    guard let profile = try Profile.find(CurrentUserState.singletonID).fetchOne(db) else {
        return nil
    }
    guard
        let goalSettings = try GoalSettings.find(CurrentUserState.singletonID).fetchOne(db),
        let nutritionPlan = try NutritionPlan.find(CurrentUserState.singletonID).fetchOne(db),
        let appPreferences = try AppPreferences.find(CurrentUserState.singletonID).fetchOne(db),
        let latestWeightEntry = try WeightEntry
            .where { $0.profileID.eq(CurrentUserState.singletonID) }
            .order { $0.recordedAt.desc() }
            .fetchOne(db)
    else {
        return nil
    }

    return CurrentUserState.fromRecords(
        profile: profile,
        goalSettings: goalSettings,
        nutritionPlan: nutritionPlan,
        appPreferences: appPreferences,
        latestWeightEntry: latestWeightEntry
    )
}
