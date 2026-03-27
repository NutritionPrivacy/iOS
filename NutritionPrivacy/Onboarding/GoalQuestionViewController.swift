import SwiftUI
import UIKit

final class GoalQuestionViewController: UIViewController, OnboardingFooterHosting {
    private let viewModel: OnboardingViewModel
    private let step: OnboardingStep = .goal
    private let rootView = UIView()
    private let headerView = OnboardingHeaderView()
    private let contentContainerView = UIView()
    private let messageLabel = UILabel()
    let footerView = OnboardingFooterView()
    private let optionsView = OptionButtonListView(options: NutritionGoal.allCases) { String(localized: $0.title) }

    init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        rootView.backgroundColor = .systemBackground
        view = rootView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpLayout()
        footerView.primaryButton.addAction(UIAction { [weak self] _ in
            self?.primaryTapped()
        }, for: .touchUpInside)
        footerView.secondaryButton.addAction(UIAction { [weak self] _ in
            self?.secondaryTapped()
        }, for: .touchUpInside)

        configureQuestionContent()
        applyModelToView()
    }

    private func setUpLayout() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        contentContainerView.translatesAutoresizingMaskIntoConstraints = false
        optionsView.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.font = .preferredFont(forTextStyle: .footnote)
        messageLabel.textColor = .systemRed
        messageLabel.numberOfLines = 0

        rootView.addSubview(headerView)
        rootView.addSubview(contentContainerView)
        contentContainerView.addSubview(optionsView)
        rootView.addSubview(messageLabel)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: rootView.topAnchor, constant: 24),
            headerView.leadingAnchor.constraint(equalTo: rootView.leadingAnchor, constant: 20),
            headerView.trailingAnchor.constraint(equalTo: rootView.trailingAnchor, constant: -20),
            contentContainerView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 24),
            contentContainerView.leadingAnchor.constraint(equalTo: rootView.leadingAnchor, constant: 20),
            contentContainerView.trailingAnchor.constraint(equalTo: rootView.trailingAnchor, constant: -20),
            contentContainerView.bottomAnchor.constraint(equalTo: messageLabel.topAnchor, constant: -24),
            contentContainerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 260),
            optionsView.centerYAnchor.constraint(equalTo: contentContainerView.centerYAnchor),
            optionsView.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor),
            optionsView.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor),
            optionsView.topAnchor.constraint(greaterThanOrEqualTo: contentContainerView.topAnchor),
            optionsView.bottomAnchor.constraint(lessThanOrEqualTo: contentContainerView.bottomAnchor),
            messageLabel.leadingAnchor.constraint(equalTo: rootView.leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(equalTo: rootView.trailingAnchor, constant: -20),
            messageLabel.bottomAnchor.constraint(lessThanOrEqualTo: rootView.bottomAnchor, constant: -24),
        ])
    }

    private func configureQuestionContent() {
        headerView.titleLabel.text = "What is your goal?"
        headerView.subtitleLabel.text = "This sets the direction for your calorie target."
        footerView.primaryButton.configuration?.title = "Continue"
        optionsView.onSelection = { [weak self] selection in
            self?.viewModel.draft.goal = selection
        }
    }

    private func applySharedModelToView() {
        messageLabel.text = viewModel.errorMessage
        messageLabel.isHidden = (viewModel.errorMessage ?? "").isEmpty
        footerView.primaryButton.isEnabled = viewModel.currentStep == step && viewModel.canContinue
        footerView.secondaryButton.isHidden = true
        if viewModel.isSaving {
            footerView.activityIndicator.startAnimating()
        } else {
            footerView.activityIndicator.stopAnimating()
        }
    }

    private func applyModelToView() {
        applySharedModelToView()
        optionsView.setSelectedOption(viewModel.draft.goal)
    }

    private func primaryTapped() {
        viewModel.navigateNext(from: step)
    }

    private func secondaryTapped() {}

    @available(iOS 26.0, *)
    override func updateProperties() {
        super.updateProperties()
        applyModelToView()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if #available(iOS 26.0, *) { return }
        applyModelToView()
    }
}

#if DEBUG
#Preview {
    UINavigationController(rootViewController: GoalQuestionViewController(
        viewModel: OnboardingPreviewSupport.makeViewModel(currentStep: .goal)
    ))
}
#endif
