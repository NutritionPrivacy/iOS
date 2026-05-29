import Dependencies
import DependenciesTestSupport
import Foundation
import Testing
@testable import NutritionPrivacy

extension BaseTestSuite {
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
        func maintainWeightSkipsTargetWeightQuestionAndUsesCurrentWeight() throws {
            let viewModel = OnboardingViewModel()
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
            let viewModel = OnboardingViewModel()
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
            let viewModel = OnboardingViewModel()
            viewModel.currentStep = .goal
            viewModel.draft.goal = .loseWeight
            
            #expect(viewModel.goNext())
            
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
