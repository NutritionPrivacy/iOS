import SwiftUI
import UIKit

final class DateOfBirthQuestionViewController: UIViewController, OnboardingFooterHosting {
    private let viewModel: OnboardingViewModel
    private let step: OnboardingStep = .dateOfBirth
    private let rootView = UIView()
    private let headerView = OnboardingHeaderView()
    private let inputContainerView = UIView()
    private let messageLabel = UILabel()
    let footerView = OnboardingFooterView()
    private let inputViewControl = DateQuestionInputView()

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
        inputContainerView.translatesAutoresizingMaskIntoConstraints = false
        inputViewControl.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.font = .preferredFont(forTextStyle: .footnote)
        messageLabel.textColor = .systemRed
        messageLabel.numberOfLines = 0

        rootView.addSubview(headerView)
        rootView.addSubview(inputContainerView)
        inputContainerView.addSubview(inputViewControl)
        rootView.addSubview(messageLabel)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: rootView.topAnchor, constant: 24),
            headerView.leadingAnchor.constraint(equalTo: rootView.leadingAnchor, constant: 20),
            headerView.trailingAnchor.constraint(equalTo: rootView.trailingAnchor, constant: -20),
            inputContainerView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 24),
            inputContainerView.leadingAnchor.constraint(equalTo: rootView.leadingAnchor, constant: 20),
            inputContainerView.trailingAnchor.constraint(equalTo: rootView.trailingAnchor, constant: -20),
            inputContainerView.bottomAnchor.constraint(equalTo: messageLabel.topAnchor, constant: -24),
            inputContainerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 160),
            inputViewControl.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor),
            inputViewControl.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor),
            inputViewControl.centerYAnchor.constraint(equalTo: inputContainerView.centerYAnchor),
            inputViewControl.topAnchor.constraint(greaterThanOrEqualTo: inputContainerView.topAnchor),
            inputViewControl.bottomAnchor.constraint(lessThanOrEqualTo: inputContainerView.bottomAnchor),
            messageLabel.leadingAnchor.constraint(equalTo: rootView.leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(equalTo: rootView.trailingAnchor, constant: -20),
            messageLabel.bottomAnchor.constraint(lessThanOrEqualTo: rootView.bottomAnchor, constant: -24),
        ])
    }

    private func configureQuestionContent() {
        headerView.titleLabel.text = "What’s your date\nof birth?"
        headerView.subtitleLabel.text = "This helps us calculate your calorie needs."
        footerView.primaryButton.configuration?.title = "Continue"
        footerView.primaryButton.configuration?.baseBackgroundColor = .primaryGreen
        footerView.primaryButton.configuration?.baseForegroundColor = .white

        inputViewControl.onDateChanged = { [weak self] date in
            self?.viewModel.draft.dateOfBirth = date
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
        inputViewControl.setDate(viewModel.draft.dateOfBirth)
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
    UINavigationController(
        rootViewController: OnboardingPreviewSupport.makeFlowViewController(currentStep: .dateOfBirth)
    )
}
#endif
