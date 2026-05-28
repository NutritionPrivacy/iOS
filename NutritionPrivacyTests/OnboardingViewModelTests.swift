import Dependencies
import Foundation
import Testing
@testable import NutritionPrivacy

struct OnboardingViewModelTests {

    @MainActor
    @Test func startsAtWelcomeAndAdvancesToName() throws {
        let viewModel = OnboardingViewModel()

        #expect(viewModel.currentStep == .welcome)
        #expect(viewModel.goNext())
        #expect(viewModel.currentStep == .name)
    }

    @MainActor
    @Test func finishOnboardingCompletesWithCurrentDraftAndResetsTransientState() throws {
        let expectedDraft = makeDraft(name: "Taylor")
        let receivedDraft = DraftBox()

        let viewModel = withDependencies {
            $0.onboardingClient = OnboardingClient(
                hasCompletedOnboarding: { false },
                completeOnboarding: { draft in
                    receivedDraft.value = draft
                }
            )
        } operation: {
            OnboardingViewModel()
        }

        viewModel.draft = expectedDraft
        viewModel.errorMessage = "Old error"

        try viewModel.finishOnboarding()

        #expect(receivedDraft.value == expectedDraft)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.isSaving == false)
    }

    @MainActor
    @Test func finishOnboardingPropagatesFailureAndStillResetsSavingState() throws {
        let expectedError = TestError.persistenceFailed

        let viewModel = withDependencies {
            $0.onboardingClient = OnboardingClient(
                hasCompletedOnboarding: { false },
                completeOnboarding: { _ in
                    throw expectedError
                }
            )
        } operation: {
            OnboardingViewModel()
        }

        viewModel.errorMessage = "Old error"

        #expect(throws: TestError.self) {
            try viewModel.finishOnboarding()
        }

        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.isSaving == false)
    }

    @MainActor
    @Test func maintainWeightSkipsTargetWeightQuestionAndUsesCurrentWeight() throws {
        let viewModel = makeNavigationViewModel()
        viewModel.currentStep = .goal
        viewModel.draft.currentWeight = BodyWeight(value: 72.5, unit: .kilograms)
        viewModel.draft.targetWeight = BodyWeight(value: 65, unit: .kilograms)
        viewModel.draft.goal = .maintainWeight
        viewModel.draft.activityLevel = .moderatelyActive

        #expect(viewModel.goNext())

        #expect(viewModel.currentStep == .planPreview)
        #expect(viewModel.draft.targetWeight == viewModel.draft.currentWeight)
    }

    @MainActor
    @Test func nonMaintenanceGoalStillShowsTargetWeightQuestion() throws {
        let viewModel = makeNavigationViewModel()
        viewModel.currentStep = .goal
        viewModel.draft.goal = .loseWeight

        #expect(viewModel.goNext())

        #expect(viewModel.currentStep == .targetWeight)
    }
}

private func makeDraft(name: String) -> OnboardingDraft {
    var draft = OnboardingDraft()
    draft.name = name
    draft.sexForCalculation = .female
    draft.dateOfBirth = Calendar.autoupdatingCurrent.date(byAdding: .year, value: -28, to: .now) ?? .now
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

@MainActor
private func makeNavigationViewModel() -> OnboardingViewModel {
    withDependencies {
        $0.nutritionPlanCalculator = NutritionPlanCalculator(
            calculate: { _, generatedAt in
                NutritionPlan(
                    id: UUID(),
                    dailyCalorieTarget: 2_000,
                    proteinGrams: 140,
                    carbGrams: 210,
                    fatGrams: 67,
                    estimatedWeeklyChange: 0,
                    generatedAt: generatedAt
                )
            }
        )
    } operation: {
        OnboardingViewModel()
    }
}

private final class DraftBox: @unchecked Sendable {
    var value: OnboardingDraft?
}

private enum TestError: Error {
    case persistenceFailed
}
