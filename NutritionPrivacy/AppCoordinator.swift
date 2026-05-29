import UIKit
import Dependencies

@MainActor
final class AppCoordinator {
    @Dependency(\.onboardingClient) private var onboardingClient
    private let rootViewController: UINavigationController
    private var onboardingRouter: OnboardingRouter?
    private let appState: AppState
    
    init(rootViewController: UINavigationController, appState: AppState) {
        self.rootViewController = rootViewController
        self.appState = appState
        setup()
    }
    
    private func setup() {
        let hasCompletedOnboarding: Bool
        do {
            hasCompletedOnboarding = try onboardingClient.hasCompletedOnboarding()
        } catch {
            
            return
        }
        if !hasCompletedOnboarding {
            let onboardingRouter = OnboardingRouter()
            self.onboardingRouter = onboardingRouter
            rootViewController.present(onboardingRouter.navigationController, animated: false)
        }
        rootViewController.pushViewController(MainViewController(appState: appState), animated: false)
    }
}
