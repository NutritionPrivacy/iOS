import Dependencies
import Foundation
import Testing
@testable import NutritionPrivacy

struct OnboardingViewModelTests {

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

private final class DraftBox: @unchecked Sendable {
    var value: OnboardingDraft?
}

private enum TestError: Error {
    case persistenceFailed
}
