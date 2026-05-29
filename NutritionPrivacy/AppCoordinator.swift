import CocoaLumberjackSwift
import Dependencies
import UIKit

@MainActor
final class AppCoordinator {
    @Dependency(\.onboardingClient) private var onboardingClient
    @Dependency(\.productPreviewClient) private var productPreviewClient
    private let rootViewController: UINavigationController
    private var onboardingRouter: OnboardingRouter?
    private var productPreviewImportTask: Task<Void, Never>?
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
        startProductPreviewImport()
    }

    private func startProductPreviewImport() {
        guard ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil else { return }

        productPreviewImportTask = Task { [productPreviewClient] in
            do {
                let summary = try await productPreviewClient.importProductPreviews { progress in
                    DDLogInfo("Product preview import progress: \(progress)")
                }
                DDLogInfo("Product preview import completed: \(summary)")
            } catch {
                DDLogError("Product preview import failed: \(error)")
            }
        }
    }
}
