#if DEBUG
import Foundation

@MainActor
enum OnboardingPreviewSupport {
    static func makeViewModel(currentStep: OnboardingStep) -> OnboardingViewModel {
        let viewModel = OnboardingViewModel()
        viewModel.currentStep = currentStep
        viewModel.draft = .previewFilled
        viewModel.generatedPlan = NutritionPlan(
            id: UUID(),
            dailyCalorieTarget: 2_050,
            proteinGrams: 140,
            carbGrams: 210,
            fatGrams: 70,
            estimatedWeeklyChange: -0.5,
            generatedAt: .now
        )
        return viewModel
    }
}

private extension OnboardingDraft {
    static var previewFilled: OnboardingDraft {
        var draft = OnboardingDraft()
        draft.name = "Alex"
        draft.sexForCalculation = .male
        draft.dateOfBirth = Calendar.autoupdatingCurrent.date(byAdding: .year, value: -30, to: .now) ?? .now
        draft.height = BodyHeight(value: 178, unit: .centimeters)
        draft.currentWeight = BodyWeight(value: 82, unit: .kilograms)
        draft.goal = .loseWeight
        draft.targetWeight = BodyWeight(value: 75, unit: .kilograms)
        draft.goalPace = .moderate
        draft.activityLevel = .moderatelyActive
        draft.exerciseFrequency = .threeToFour
        draft.proteinPreference = .higherProtein
        return draft
    }
}
#endif
