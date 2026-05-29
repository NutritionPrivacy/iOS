import Dependencies
import DependenciesTestSupport
import Foundation
import SQLiteData
import Testing
@testable import NutritionPrivacy

@Suite(.dependencies { try $0.bootstrapDatabase() })
struct OnboardingViewModelTests {

    @MainActor
    @Test func startsAtWelcomeAndAdvancesToName() throws {
        let viewModel = makeNavigationViewModel()

        #expect(viewModel.currentStep == .welcome)
        #expect(viewModel.goNext())
        #expect(viewModel.currentStep == .name)
    }

    @MainActor
    @Test func finishOnboardingCompletesWithCurrentDraftAndResetsTransientState() throws {
        let expectedDraft = makeDraft(name: "Taylor")
        let receivedDraft = DraftBox()

        let viewModel = OnboardingViewModel(
            onboardingClient: OnboardingClient(
                hasCompletedOnboarding: { false },
                completeOnboarding: { draft in
                    receivedDraft.value = draft
                }
            ),
            nutritionPlanCalculator: makeNutritionPlanCalculator(),
            now: fixedDate
        )

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

        let viewModel = OnboardingViewModel(
            onboardingClient: OnboardingClient(
                hasCompletedOnboarding: { false },
                completeOnboarding: { _ in
                    throw expectedError
                }
            ),
            nutritionPlanCalculator: makeNutritionPlanCalculator(),
            now: fixedDate
        )

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
    @Test func sexQuestionRequiresASelectionBeforeAdvancing() throws {
        let viewModel = makeNavigationViewModel()
        viewModel.currentStep = .sexForCalculation

        #expect(!viewModel.canContinue)
        #expect(!viewModel.goNext())
        #expect(viewModel.currentStep == .sexForCalculation)

        viewModel.draft.hasSelectedSexForCalculation = true
        viewModel.draft.sexForCalculation = nil

        #expect(viewModel.canContinue)
        #expect(viewModel.goNext())
        #expect(viewModel.currentStep == .height)
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
    OnboardingViewModel(
        onboardingClient: OnboardingClient(
            hasCompletedOnboarding: { false },
            completeOnboarding: { _ in }
        ),
        nutritionPlanCalculator: makeNutritionPlanCalculator(),
        now: fixedDate
    )
}

private let fixedDate = Date(timeIntervalSince1970: 1_742_000_000)

private func makeNutritionPlanCalculator() -> NutritionPlanCalculator {
    NutritionPlanCalculator(
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
}

private final class DraftBox: @unchecked Sendable {
    var value: OnboardingDraft?
}

private enum TestError: Error {
    case persistenceFailed
}
