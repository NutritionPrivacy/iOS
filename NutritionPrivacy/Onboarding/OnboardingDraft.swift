import Foundation

enum OnboardingStep: Int, CaseIterable, Hashable, Sendable {
    case welcome
    case name
    case dateOfBirth
    case sexForCalculation
    case height
    case currentWeight
    case activityLevel
    case goal
    case targetWeight
    case planPreview
    case completion

    // Still supported by persistence/calculation, but no longer shown in the visual onboarding flow.
    case goalPace
    case exerciseFrequency
    case proteinPreference

    static let questionSteps: [OnboardingStep] = [
        .name,
        .dateOfBirth,
        .sexForCalculation,
        .height,
        .currentWeight,
        .activityLevel,
        .goal,
        .targetWeight,
        .planPreview,
    ]

    static let flowSteps: [OnboardingStep] = [
        .welcome,
        .name,
        .dateOfBirth,
        .sexForCalculation,
        .height,
        .currentWeight,
        .activityLevel,
        .goal,
        .targetWeight,
        .planPreview,
        .completion,
    ]

    var previous: OnboardingStep? {
        guard let index = Self.flowSteps.firstIndex(of: self), index > 0 else {
            return nil
        }
        return Self.flowSteps[index - 1]
    }

    var next: OnboardingStep? {
        guard let index = Self.flowSteps.firstIndex(of: self), index < Self.flowSteps.count - 1 else {
            return nil
        }
        return Self.flowSteps[index + 1]
    }

    var progressIndex: Int {
        switch self {
        case .welcome:
            return 0
        case .completion:
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
    var hasSelectedSexForCalculation = false
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

    var questionSteps: [OnboardingStep] {
        guard goal == .maintainWeight else {
            return OnboardingStep.questionSteps
        }

        return OnboardingStep.questionSteps.filter { $0 != .targetWeight }
    }

    var flowSteps: [OnboardingStep] {
        guard goal == .maintainWeight else {
            return OnboardingStep.flowSteps
        }

        return OnboardingStep.flowSteps.filter { $0 != .targetWeight }
    }

    func previousStep(before step: OnboardingStep) -> OnboardingStep? {
        guard let index = flowSteps.firstIndex(of: step), index > 0 else {
            return nil
        }
        return flowSteps[index - 1]
    }

    func nextStep(after step: OnboardingStep) -> OnboardingStep? {
        guard let index = flowSteps.firstIndex(of: step), index < flowSteps.count - 1 else {
            return nil
        }
        return flowSteps[index + 1]
    }

    func progressIndex(for step: OnboardingStep) -> Int {
        switch step {
        case .welcome:
            return 0
        case .completion:
            return questionSteps.count
        default:
            return (questionSteps.firstIndex(of: step) ?? 0) + 1
        }
    }

    var progressTotal: Int {
        questionSteps.count
    }

    func canContinue(from step: OnboardingStep) -> Bool {
        switch step {
        case .welcome:
            return true
        case .name:
            return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .sexForCalculation:
            return hasSelectedSexForCalculation
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
        case .completion:
            return true
        }
    }

    mutating func alignTargetWeightForSelectedGoal() {
        guard goal == .maintainWeight else { return }
        targetWeight = currentWeight
    }

    var goalPaceOrDefault: GoalPace {
        goalPace ?? .moderate
    }

    var exerciseFrequencyOrDefault: ExerciseFrequency {
        exerciseFrequency ?? .threeToFour
    }

    var proteinPreferenceOrDefault: ProteinPreference {
        proteinPreference ?? .higherProtein
    }

    func completedPayload(
        id: UUID,
        completedAt: Date,
        nutritionPlan: NutritionPlan
    ) throws -> CompletedOnboardingPayload {
        guard
            let goal,
            let activityLevel
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
                goalPace: goalPaceOrDefault,
                targetWeightValue: targetWeight.value,
                targetWeightUnit: targetWeight.unit,
                activityLevel: activityLevel,
                exerciseFrequency: exerciseFrequencyOrDefault,
                proteinPreference: proteinPreferenceOrDefault,
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
