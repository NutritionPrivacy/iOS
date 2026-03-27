import CocoaLumberjackSwift
import Dependencies
import Observation
import UIKit

@MainActor
@Observable
final class OnboardingViewModel {
    @ObservationIgnored @Dependency(\.onboardingClient) private var onboardingClient
    @ObservationIgnored @Dependency(\.nutritionPlanCalculator) private var nutritionPlanCalculator
    @ObservationIgnored @Dependency(\.date.now) private var now

    var currentStep: OnboardingStep = .name
    var draft = OnboardingDraft()
    var generatedPlan: NutritionPlan?
    var errorMessage: String?
    var isSaving = false
    @ObservationIgnored weak var router: OnboardingRouting?

    var canContinue: Bool {
        draft.canContinue(from: currentStep)
    }

    var progressValue: Float {
        Float(currentStep.progressIndex) / Float(currentStep.progressTotal)
    }

    func goNext() -> Bool {
        errorMessage = nil

        guard canContinue else {
            DDLogInfo("Onboarding blocked from advancing at step=\(currentStep)")
            return false
        }

        guard let next = currentStep.next else {
            DDLogInfo("Onboarding already at last step=\(currentStep)")
            return false
        }

        if next == .planPreview {
            do {
                generatedPlan = try nutritionPlanCalculator.calculate(draft, now)
                DDLogInfo("Generated onboarding plan for preview")
            } catch {
                errorMessage = error.localizedDescription
                DDLogError("Failed to generate onboarding plan: \(error)")
                return false
            }
        }

        let previous = currentStep
        currentStep = next
        DDLogInfo("Onboarding advanced from step=\(previous) to step=\(next)")
        return true
    }

    func goBack() -> Bool {
        errorMessage = nil
        guard let previous = currentStep.previous else {
            DDLogInfo("Onboarding already at first step=\(currentStep)")
            return false
        }

        let from = currentStep
        currentStep = previous
        DDLogInfo("Onboarding moved back from step=\(from) to step=\(previous)")
        return true
    }

    func finishOnboarding() throws {
        errorMessage = nil
        isSaving = true
        DDLogInfo("Finishing onboarding")
        defer { isSaving = false }

        do {
            try onboardingClient.completeOnboarding(draft)
            DDLogInfo("Onboarding completed successfully")
        } catch {
            DDLogError("Failed to complete onboarding: \(error)")
            throw error
        }
        router?.finishOnboarding()
    }

    func navigateNext(from step: OnboardingStep) {
        router?.showNextStep(from: step)
    }

    func navigateBack(from step: OnboardingStep) {
        router?.showPreviousStep(from: step)
    }
}

@MainActor
protocol OnboardingRouting: AnyObject {
    func showNextStep(from step: OnboardingStep)
    func showPreviousStep(from step: OnboardingStep)
    func finishOnboarding()
}

@MainActor
protocol OnboardingFooterHosting: AnyObject {
    var footerView: OnboardingFooterView { get }
}

@MainActor
final class OnboardingFlowViewController: UIViewController {
    private let viewModel: OnboardingViewModel
    private let makeViewController: (OnboardingStep) -> UIViewController
    private let pageViewController: UIPageViewController
    private let progressView = UIProgressView(progressViewStyle: .default)
    private let footerContainerView = UIView()
    private let footerSeparatorView = UIView()
    private weak var hostedFooterView: OnboardingFooterView?
    private var viewControllersByStep: [OnboardingStep: UIViewController] = [:]

    init(
        viewModel: OnboardingViewModel,
        makeViewController: @escaping (OnboardingStep) -> UIViewController
    ) {
        self.viewModel = viewModel
        self.makeViewController = makeViewController
        self.pageViewController = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal
        )
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.hidesBackButton = true

        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.trackTintColor = .systemGray5
        progressView.progressTintColor = .systemBlue
        progressView.layer.cornerRadius = 4
        progressView.clipsToBounds = true
        progressView.transform = CGAffineTransform(scaleX: 1.0, y: 1.5)
        view.addSubview(progressView)

        footerContainerView.translatesAutoresizingMaskIntoConstraints = false
        footerContainerView.backgroundColor = .secondarySystemBackground.withAlphaComponent(0.96)
        view.addSubview(footerContainerView)

        footerSeparatorView.translatesAutoresizingMaskIntoConstraints = false
        footerSeparatorView.backgroundColor = .separator
        footerContainerView.addSubview(footerSeparatorView)

        addChild(pageViewController)
        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pageViewController.view)
        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            footerContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            footerContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            footerContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            footerSeparatorView.topAnchor.constraint(equalTo: footerContainerView.topAnchor),
            footerSeparatorView.leadingAnchor.constraint(equalTo: footerContainerView.leadingAnchor),
            footerSeparatorView.trailingAnchor.constraint(equalTo: footerContainerView.trailingAnchor),
            footerSeparatorView.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale),
            pageViewController.view.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 12),
            pageViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pageViewController.view.bottomAnchor.constraint(equalTo: footerContainerView.topAnchor),
        ])
        pageViewController.didMove(toParent: self)

        if let scrollView = pageViewController.view.subviews.compactMap({ $0 as? UIScrollView }).first {
            scrollView.isScrollEnabled = false
        }

        show(step: viewModel.currentStep, direction: .forward, animated: false)
    }

    func show(step: OnboardingStep, direction: UIPageViewController.NavigationDirection, animated: Bool) {
        let viewController = viewController(for: step)
        pageViewController.setViewControllers([viewController], direction: direction, animated: animated)
        progressView.setProgress(viewModel.progressValue, animated: animated)
        hostFooterIfNeeded(for: viewController)
        updateNavigationItems(for: step)
    }

    private func viewController(for step: OnboardingStep) -> UIViewController {
        if let viewController = viewControllersByStep[step] {
            return viewController
        }

        let viewController = makeViewController(step)
        viewControllersByStep[step] = viewController
        return viewController
    }

    private func hostFooterIfNeeded(for viewController: UIViewController) {
        guard let footerHost = viewController as? OnboardingFooterHosting else {
            hostedFooterView?.removeFromSuperview()
            hostedFooterView = nil
            return
        }

        let footerView = footerHost.footerView
        guard hostedFooterView !== footerView else { return }

        hostedFooterView?.removeFromSuperview()
        footerView.removeFromSuperview()
        footerView.translatesAutoresizingMaskIntoConstraints = false
        footerContainerView.addSubview(footerView)
        NSLayoutConstraint.activate([
            footerView.topAnchor.constraint(equalTo: footerContainerView.topAnchor, constant: 12),
            footerView.leadingAnchor.constraint(equalTo: footerContainerView.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            footerView.trailingAnchor.constraint(equalTo: footerContainerView.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            footerView.bottomAnchor.constraint(equalTo: footerContainerView.safeAreaLayoutGuide.bottomAnchor, constant: -12),
        ])
        hostedFooterView = footerView
    }

    private func updateNavigationItems(for step: OnboardingStep) {
        if step.previous != nil {
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                image: UIImage(systemName: "chevron.left"),
                primaryAction: UIAction { [weak self] _ in
                    guard let self else { return }
                    self.viewModel.navigateBack(from: self.viewModel.currentStep)
                }
            )
        } else {
            navigationItem.leftBarButtonItem = nil
        }
    }
}

@MainActor
final class OnboardingRouter: OnboardingRouting {
    let navigationController: UINavigationController
    let viewModel: OnboardingViewModel
    private lazy var onboardingViewController = OnboardingFlowViewController(
        viewModel: viewModel,
        makeViewController: makeViewController(for:)
    )

    init() {
        self.viewModel = OnboardingViewModel()
        self.navigationController = UINavigationController()
        viewModel.router = self
        navigationController.setViewControllers([onboardingViewController], animated: false)
    }

    func showNextStep(from step: OnboardingStep) {
        guard viewModel.currentStep == step, viewModel.goNext(), let nextStep = viewModel.currentStep as OnboardingStep? else {
            return
        }
        onboardingViewController.show(step: nextStep, direction: .forward, animated: true)
    }

    func showPreviousStep(from step: OnboardingStep) {
        guard viewModel.currentStep == step, viewModel.goBack() else {
            return
        }
        onboardingViewController.show(step: viewModel.currentStep, direction: .reverse, animated: true)
    }
    
    func finishOnboarding() {
        onboardingViewController.dismiss(animated: true)
    }

    private func makeViewController(for step: OnboardingStep) -> UIViewController {
        switch step {
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
        }
    }
}
