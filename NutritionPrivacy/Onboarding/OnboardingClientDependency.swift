import Dependencies
import Foundation
import SQLiteData

struct OnboardingClient: Sendable {
    var hasCompletedOnboarding: @Sendable () throws -> Bool
    var completeOnboarding: @Sendable (_ draft: OnboardingDraft) throws -> Void
}

extension OnboardingClient: DependencyKey {
    static var liveValue: OnboardingClient {
        let client = LiveOnboardingClient()
        
        return OnboardingClient(
            hasCompletedOnboarding: client.hasCompletedOnboarding,
            completeOnboarding: client.completeOnboarding(with:)
        )
    }
}

struct LiveOnboardingClient {
    private let database: any DatabaseWriter
    private let now: Date
    private let nutritionPlanCalculator: NutritionPlanCalculator

    init() {
        @Dependency(\.defaultDatabase) var database
        @Dependency(\.date.now) var now
        @Dependency(\.nutritionPlanCalculator) var nutritionPlanCalculator

        self.init(
            database: database,
            now: now,
            nutritionPlanCalculator: nutritionPlanCalculator
        )
    }

    init(
        database: any DatabaseWriter,
        now: Date,
        nutritionPlanCalculator: NutritionPlanCalculator
    ) {
        self.database = database
        self.now = now
        self.nutritionPlanCalculator = nutritionPlanCalculator
    }
    
    func hasCompletedOnboarding() throws -> Bool {
        try database.read { db in
            try AppPreferences.fetchCount(db) > 0
        }
    }
    
    func completeOnboarding(with draft: OnboardingDraft) throws {
        let completedAt = now
        let profileID = UUID()
        let generatedPlan = try nutritionPlanCalculator.calculate(draft, completedAt)
        let payload = try draft.completedPayload(
            id: profileID,
            completedAt: completedAt,
            nutritionPlan: NutritionPlan(
                id: profileID,
                dailyCalorieTarget: generatedPlan.dailyCalorieTarget,
                proteinGrams: generatedPlan.proteinGrams,
                carbGrams: generatedPlan.carbGrams,
                fatGrams: generatedPlan.fatGrams,
                estimatedWeeklyChange: generatedPlan.estimatedWeeklyChange,
                generatedAt: completedAt
            )
        )
        try database.write { db in
            try Profile.insert { payload.profile }.execute(db)
            try GoalSettings.insert { payload.goalSettings }.execute(db)
            try NutritionPlan.insert { payload.nutritionPlan }.execute(db)
            try AppPreferences.insert { payload.appPreferences }.execute(db)
            try WeightEntry.insert { payload.weightEntry }.execute(db)
        }
    }
}

extension DependencyValues {
    var onboardingClient: OnboardingClient {
        get { self[OnboardingClient.self] }
        set { self[OnboardingClient.self] = newValue }
    }
}
