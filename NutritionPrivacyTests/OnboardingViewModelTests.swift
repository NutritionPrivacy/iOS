import Dependencies
import DependenciesTestSupport
import Foundation
import Testing
@testable import NutritionPrivacy

extension BaseTestSuite {
    struct OnboardingViewModelTests {
        @MainActor
        @Test func startsAtWelcomeAndAdvancesToName() throws {
            // GIVEN a fresh onboarding view model that starts on the welcome step.
            let viewModel = OnboardingViewModel()
            #expect(viewModel.currentStep == .welcome)

            // WHEN advancing to the next step.
            #expect(viewModel.goNext())

            // THEN the view model moves to the name step.
            #expect(viewModel.currentStep == .name)
        }
        
        @MainActor
        @Test func finishOnboardingCompletesWithCurrentDraftAndResetsTransientState() throws {
            // GIVEN a completed draft and an onboarding client that captures persisted input.
            let expectedDraft = makeDraft(name: "Taylor")
            let receivedDraft = LockIsolated<OnboardingDraft?>(nil)
            
            let viewModel = withDependencies {
                $0.onboardingClient = OnboardingClient(
                    hasCompletedOnboarding: { false },
                    completeOnboarding: { draft in
                        receivedDraft.setValue(draft)
                    }
                )
            } operation: {
                OnboardingViewModel()
            }
            
            viewModel.draft = expectedDraft
            viewModel.errorMessage = "Old error"

            // WHEN finishing onboarding.
            try viewModel.finishOnboarding()

            // THEN the current draft is persisted and transient saving state is cleared.
            #expect(receivedDraft.value == expectedDraft)
            #expect(viewModel.errorMessage == nil)
            #expect(viewModel.isSaving == false)
        }
        
        @MainActor
        @Test func finishOnboardingPropagatesFailureAndStillResetsSavingState() throws {
            // GIVEN an onboarding client that fails while completing onboarding.
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

            // WHEN finishing onboarding.
            #expect(throws: TestError.self) {
                try viewModel.finishOnboarding()
            }

            // THEN the error is propagated and transient saving state is cleared.
            #expect(viewModel.errorMessage == nil)
            #expect(viewModel.isSaving == false)
        }
        
        @MainActor
        func maintainWeightSkipsTargetWeightQuestionAndUsesCurrentWeight() throws {
            // GIVEN a maintain-weight draft on the goal step.
            let viewModel = OnboardingViewModel()
            viewModel.currentStep = .goal
            viewModel.draft.currentWeight = BodyWeight(value: 72.5, unit: .kilograms)
            viewModel.draft.targetWeight = BodyWeight(value: 65, unit: .kilograms)
            viewModel.draft.goal = .maintainWeight
            viewModel.draft.activityLevel = .moderatelyActive

            // WHEN advancing from the goal step.
            #expect(viewModel.goNext())

            // THEN the target-weight question is skipped and target weight matches current weight.
            #expect(viewModel.currentStep == .planPreview)
            #expect(viewModel.draft.targetWeight == viewModel.draft.currentWeight)
        }
        
        @MainActor
        @Test func sexQuestionRequiresASelectionBeforeAdvancing() throws {
            // GIVEN the onboarding flow is on the sex question without a selection.
            let viewModel = OnboardingViewModel()
            viewModel.currentStep = .sexForCalculation
            #expect(!viewModel.canContinue)

            // WHEN attempting to advance without answering.
            #expect(!viewModel.goNext())

            // THEN the view model stays on the sex question.
            #expect(viewModel.currentStep == .sexForCalculation)

            // WHEN the user explicitly selects no sex for calculation.
            viewModel.draft.hasSelectedSexForCalculation = true
            viewModel.draft.sexForCalculation = nil

            // THEN the view model treats the question as answered and advances.
            #expect(viewModel.canContinue)
            #expect(viewModel.goNext())
            #expect(viewModel.currentStep == .height)
        }
        
        @MainActor
        @Test func nonMaintenanceGoalStillShowsTargetWeightQuestion() throws {
            // GIVEN a non-maintenance goal on the goal step.
            let viewModel = OnboardingViewModel()
            viewModel.currentStep = .goal
            viewModel.draft.goal = .loseWeight

            // WHEN advancing from the goal step.
            #expect(viewModel.goNext())

            // THEN the target-weight question is shown.
            #expect(viewModel.currentStep == .targetWeight)
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
    }
}

private enum TestError: Error {
    case persistenceFailed
}
