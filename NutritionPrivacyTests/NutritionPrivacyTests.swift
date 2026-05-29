import Dependencies
import Foundation
import SQLiteData
import Testing
import DependenciesTestSupport
@testable import NutritionPrivacy

@Suite(.dependencies { try $0.bootstrapDatabase() })
struct NutritionPrivacyTests {
    @Dependency(\.defaultDatabase)
    private var database

    @Dependency(\.nutritionPlanCalculator)
    private var nutritionPlanCalculator
    
    private static let fixedDate = Date(timeIntervalSince1970: 1_742_000_000)
    
    @Test(
        .dependency(\.date.now, fixedDate),
        .dependency(\.nutritionPlanCalculator, .liveValue)
    ) func completeOnboardingPersistsExpectedRecords() throws {
        let fixedDate = Date(timeIntervalSince1970: 1_742_000_000)
        let draft = makeDraft(name: "Taylor")

        let client = LiveOnboardingClient()
        try client.completeOnboarding(with: draft)
        let expectedPlan = try nutritionPlanCalculator.calculate(draft, fixedDate)

        try database.read { db in
            let fetchedProfile = try Profile.fetchOne(db)
            let fetchedGoalSettings = try GoalSettings.fetchOne(db)
            let fetchedNutritionPlan = try NutritionPlan.fetchOne(db)
            let fetchedAppPreferences = try AppPreferences.fetchOne(db)
            let fetchedWeightEntry = try WeightEntry.fetchOne(db)

            let profile = try #require(fetchedProfile)
            let goalSettings = try #require(fetchedGoalSettings)
            let nutritionPlan = try #require(fetchedNutritionPlan)
            let appPreferences = try #require(fetchedAppPreferences)
            let weightEntry = try #require(fetchedWeightEntry)

            #expect(profile.name == draft.name)
            #expect(profile.sexForCalculation == draft.sexForCalculation)
            #expect(profile.dateOfBirth == draft.dateOfBirth)
            #expect(profile.heightValue == draft.height.value)
            #expect(profile.heightUnit == draft.height.unit)

            #expect(goalSettings.id == profile.id)
            #expect(goalSettings.goal == draft.goal)
            #expect(goalSettings.goalPace == draft.goalPace)
            #expect(goalSettings.targetWeightValue == draft.targetWeight.value)
            #expect(goalSettings.targetWeightUnit == draft.targetWeight.unit)
            #expect(goalSettings.activityLevel == draft.activityLevel)
            #expect(goalSettings.exerciseFrequency == draft.exerciseFrequency)
            #expect(goalSettings.proteinPreference == draft.proteinPreference)
            #expect(goalSettings.validSince == fixedDate)

            #expect(nutritionPlan.id == profile.id)
            #expect(nutritionPlan.dailyCalorieTarget == expectedPlan.dailyCalorieTarget)
            #expect(nutritionPlan.proteinGrams == expectedPlan.proteinGrams)
            #expect(nutritionPlan.carbGrams == expectedPlan.carbGrams)
            #expect(nutritionPlan.fatGrams == expectedPlan.fatGrams)
            #expect(nutritionPlan.estimatedWeeklyChange == expectedPlan.estimatedWeeklyChange)
            #expect(nutritionPlan.generatedAt == fixedDate)

            #expect(appPreferences.id == profile.id)
            #expect(appPreferences.weeklyCheckInDay == draft.weeklyCheckInDay)
            #expect(appPreferences.completedAt == fixedDate)

            #expect(weightEntry.profileID == profile.id)
            #expect(weightEntry.weightValue == draft.currentWeight.value)
            #expect(weightEntry.weightUnit == draft.currentWeight.unit)
            #expect(weightEntry.recordedAt == fixedDate)
        }
    }
}

private func makeDraft(name: String) -> OnboardingDraft {
    var draft = OnboardingDraft()
    draft.name = name
    draft.sexForCalculation = .female
    draft.dateOfBirth = Date(timeIntervalSince1970: 820_454_400)
    draft.height = BodyHeight(value: 168, unit: .centimeters)
    draft.currentWeight = BodyWeight(value: 72.5, unit: .kilograms)
    draft.goal = .maintainWeight
    draft.targetWeight = BodyWeight(value: 68, unit: .kilograms)
    draft.goalPace = .moderate
    draft.activityLevel = .moderatelyActive
    draft.exerciseFrequency = .threeToFour
    draft.proteinPreference = .higherProtein
    return draft
}
