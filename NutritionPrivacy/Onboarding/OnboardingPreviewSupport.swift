#if DEBUG
import Foundation
import UIKit

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

    static func makeFlowViewController(currentStep: OnboardingStep) -> UIViewController {
        let viewModel = makeViewModel(currentStep: currentStep)
        return OnboardingFlowViewController(viewModel: viewModel) { step in
            makeQuestionViewController(for: step, viewModel: viewModel)
        }
    }

    private static func makeQuestionViewController(
        for step: OnboardingStep,
        viewModel: OnboardingViewModel
    ) -> UIViewController {
        switch step {
        case .welcome:
            return WelcomeOnboardingViewController(viewModel: viewModel)
        case .name:
            return NameQuestionViewController(viewModel: viewModel)
        case .sexForCalculation:
            return SexQuestionViewController(viewModel: viewModel)
        case .dateOfBirth:
            return DateOfBirthQuestionViewController(viewModel: viewModel)
        case .height:
            return HeightQuestionViewController(viewModel: viewModel)
        case .currentWeight:
            return CurrentWeightQuestionViewController(viewModel: viewModel)
        case .goal:
            return GoalQuestionViewController(viewModel: viewModel)
        case .targetWeight:
            return TargetWeightQuestionViewController(viewModel: viewModel)
        case .goalPace:
            return GoalPaceQuestionViewController(viewModel: viewModel)
        case .activityLevel:
            return ActivityLevelQuestionViewController(viewModel: viewModel)
        case .exerciseFrequency:
            return ExerciseFrequencyQuestionViewController(viewModel: viewModel)
        case .proteinPreference:
            return ProteinPreferenceQuestionViewController(viewModel: viewModel)
        case .planPreview:
            return PlanPreviewViewController(viewModel: viewModel)
        case .completion:
            return OnboardingCompletionViewController(viewModel: viewModel)
        }
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
