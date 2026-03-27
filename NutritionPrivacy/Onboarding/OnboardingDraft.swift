import Foundation

enum OnboardingStep: Int, CaseIterable, Hashable, Sendable {
    case name
    case sexForCalculation
    case dateOfBirth
    case height
    case currentWeight
    case goal
    case targetWeight
    case goalPace
    case activityLevel
    case exerciseFrequency
    case proteinPreference
    case planPreview

    static let questionSteps: [OnboardingStep] = [
        .name,
        .sexForCalculation,
        .dateOfBirth,
        .height,
        .currentWeight,
        .goal,
        .targetWeight,
        .goalPace,
        .activityLevel,
        .exerciseFrequency,
        .proteinPreference,
    ]

    var previous: OnboardingStep? {
        guard let index = Self.allCases.firstIndex(of: self), index > 0 else {
            return nil
        }
        return Self.allCases[index - 1]
    }

    var next: OnboardingStep? {
        guard let index = Self.allCases.firstIndex(of: self), index < Self.allCases.count - 1 else {
            return nil
        }
        return Self.allCases[index + 1]
    }

    var progressIndex: Int {
        switch self {
        case .planPreview:
            return Self.questionSteps.count
        default:
            return (Self.questionSteps.firstIndex(of: self) ?? 0) + 1
        }
    }

    var progressTotal: Int {
        Self.questionSteps.count
    }
}

struct OnboardingDraft: Hashable, Sendable {
    var name = ""
    var sexForCalculation: SexForCalculation?
    var dateOfBirth = Calendar.autoupdatingCurrent.date(byAdding: .year, value: -30, to: .now) ?? .now
    var height = BodyHeight(value: 170, unit: .centimeters)
    var currentWeight = BodyWeight(value: 70, unit: .kilograms)
    var goal: NutritionGoal?
    var targetWeight = BodyWeight(value: 65, unit: .kilograms)
    var goalPace: GoalPace?
    var activityLevel: ActivityLevel?
    var exerciseFrequency: ExerciseFrequency?
    var proteinPreference: ProteinPreference?
    var weeklyCheckInDay: WeeklyCheckInDay = .monday

    func canContinue(from step: OnboardingStep) -> Bool {
        switch step {
        case .name:
            return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .sexForCalculation:
            return true
        case .dateOfBirth:
            return true
        case .height:
            return height.value > 0
        case .currentWeight:
            return currentWeight.value > 0
        case .goal:
            return goal != nil
        case .targetWeight:
            return targetWeight.value > 0
        case .goalPace:
            return goalPace != nil
        case .activityLevel:
            return activityLevel != nil
        case .exerciseFrequency:
            return exerciseFrequency != nil
        case .proteinPreference:
            return proteinPreference != nil
        case .planPreview:
            return true
        }
    }

    func completedPayload(
        id: UUID,
        completedAt: Date,
        nutritionPlan: NutritionPlan
    ) throws -> CompletedOnboardingPayload {
        guard
            let goal,
            let goalPace,
            let activityLevel,
            let exerciseFrequency,
            let proteinPreference
        else {
            throw OnboardingPersistenceError.incompleteDraft
        }

        return CompletedOnboardingPayload(
            profile: Profile(
                id: id,
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                sexForCalculation: sexForCalculation,
                dateOfBirth: dateOfBirth,
                heightValue: height.value,
                heightUnit: height.unit
            ),
            goalSettings: GoalSettings(
                id: id,
                goal: goal,
                goalPace: goalPace,
                targetWeightValue: targetWeight.value,
                targetWeightUnit: targetWeight.unit,
                activityLevel: activityLevel,
                exerciseFrequency: exerciseFrequency,
                proteinPreference: proteinPreference,
                validSince: completedAt
            ),
            nutritionPlan: nutritionPlan,
            appPreferences: AppPreferences(
                id: id,
                weeklyCheckInDay: weeklyCheckInDay,
                completedAt: completedAt
            ),
            weightEntry: WeightEntry(
                id: UUID(),
                profileID: id,
                weightValue: currentWeight.value,
                weightUnit: currentWeight.unit,
                recordedAt: completedAt
            )
        )
    }
}

struct CompletedOnboardingPayload: Sendable {
    let profile: Profile
    let goalSettings: GoalSettings
    let nutritionPlan: NutritionPlan
    let appPreferences: AppPreferences
    let weightEntry: WeightEntry
}

enum OnboardingPersistenceError: LocalizedError {
    case incompleteDraft

    var errorDescription: String? {
        switch self {
        case .incompleteDraft:
            return "Please complete the remaining onboarding answers."
        }
    }
}
