import Dependencies
import Foundation
import SQLiteData

extension DependencyValues {
    mutating func bootstrapDatabase() throws {
        let databaseURL = try FileManager.default
            .url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            .appendingPathComponent("NutritionPrivacy.sqlite")

        let database = try SQLiteData.defaultDatabase(path: databaseURL.path)
        var migrator = DatabaseMigrator()
#if DEBUG
        migrator.eraseDatabaseOnSchemaChange = true
#endif
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
        try migrator.migrate(database)
        defaultDatabase = database
    }
}
