import Dependencies
import Foundation
import SQLiteData
import Testing
@testable import NutritionPrivacy

struct NutritionPrivacyTests {

    @Test func completeOnboardingPersistsExpectedRecords() throws {
        let fixedDate = Date(timeIntervalSince1970: 1_742_000_000)
        let draft = makeDraft(name: "Taylor")
        let database = try makeTestDatabase()

        try withDependencies {
            $0.defaultDatabase = database
            $0.date.now = fixedDate
        } operation: {
            try OnboardingClient.liveValue.completeOnboarding(draft)
        }

        let expectedPlan = try NutritionPlanCalculator.liveValue.calculate(draft, fixedDate)

        try database.read { db in
            let profile = try #require(Profile.fetchOne(db))
            let goalSettings = try #require(GoalSettings.fetchOne(db))
            let nutritionPlan = try #require(NutritionPlan.fetchOne(db))
            let appPreferences = try #require(AppPreferences.fetchOne(db))
            let weightEntry = try #require(WeightEntry.fetchOne(db))

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

private func makeTestDatabase() throws -> any DatabaseWriter {
    let database = try defaultDatabase()

    try database.write { db in
        var migrator = DatabaseMigrator()
        migrator.registerMigration("Create onboarding persistence tables") { db in
            try #sql(
                """
                CREATE TABLE "profiles" (
                  "id" TEXT PRIMARY KEY NOT NULL,
                  "name" TEXT NOT NULL,
                  "sexForCalculation" TEXT,
                  "dateOfBirth" TEXT NOT NULL,
                  "heightValue" REAL NOT NULL,
                  "heightUnit" TEXT NOT NULL
                ) STRICT
                """
            )
            .execute(db)

            try #sql(
                """
                CREATE TABLE "goalSettings" (
                  "id" TEXT PRIMARY KEY NOT NULL REFERENCES "profiles"("id") ON DELETE CASCADE,
                  "goal" TEXT NOT NULL,
                  "goalPace" TEXT NOT NULL,
                  "targetWeightValue" REAL NOT NULL,
                  "targetWeightUnit" TEXT NOT NULL,
                  "activityLevel" TEXT NOT NULL,
                  "exerciseFrequency" TEXT NOT NULL,
                  "proteinPreference" TEXT NOT NULL,
                  "validSince" TEXT NOT NULL
                ) STRICT
                """
            )
            .execute(db)

            try #sql(
                """
                CREATE TABLE "nutritionPlans" (
                  "id" TEXT PRIMARY KEY NOT NULL REFERENCES "profiles"("id") ON DELETE CASCADE,
                  "dailyCalorieTarget" INTEGER NOT NULL,
                  "proteinGrams" INTEGER NOT NULL,
                  "carbGrams" INTEGER NOT NULL,
                  "fatGrams" INTEGER NOT NULL,
                  "estimatedWeeklyChange" REAL NOT NULL,
                  "generatedAt" TEXT NOT NULL
                ) STRICT
                """
            )
            .execute(db)

            try #sql(
                """
                CREATE TABLE "appPreferences" (
                  "id" TEXT PRIMARY KEY NOT NULL REFERENCES "profiles"("id") ON DELETE CASCADE,
                  "weeklyCheckInDay" TEXT NOT NULL,
                  "completedAt" TEXT NOT NULL
                ) STRICT
                """
            )
            .execute(db)

            try #sql(
                """
                CREATE TABLE "weightEntries" (
                  "id" TEXT PRIMARY KEY NOT NULL,
                  "profileID" TEXT NOT NULL REFERENCES "profiles"("id") ON DELETE CASCADE,
                  "weightValue" REAL NOT NULL,
                  "weightUnit" TEXT NOT NULL,
                  "recordedAt" TEXT NOT NULL
                ) STRICT
                """
            )
            .execute(db)
        }
        migrator.registerMigration("Create onboarding persistence indexes") { db in
            try #sql(
                """
                CREATE INDEX IF NOT EXISTS "idx_weightEntries_profileID_recordedAt"
                ON "weightEntries"("profileID", "recordedAt" DESC)
                """
            )
            .execute(db)
        }
        try migrator.migrate(db)
    }

    return database
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
