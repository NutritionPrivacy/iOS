import SwiftUI
import UIKit

final class TargetWeightQuestionViewController: UIViewController, OnboardingFooterHosting {
    private let viewModel: OnboardingViewModel
    private let step: OnboardingStep = .targetWeight
    private let rootView = UIView()
    private let headerView = OnboardingHeaderView()
    private let inputContainerView = UIView()
    private let messageLabel = UILabel()
    let footerView = OnboardingFooterView()
    private let inputViewControl = WeightPickerInputView()

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
            inputContainerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 320),
            inputViewControl.centerYAnchor.constraint(equalTo: inputContainerView.centerYAnchor),
            inputViewControl.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor),
            inputViewControl.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor),
            inputViewControl.topAnchor.constraint(greaterThanOrEqualTo: inputContainerView.topAnchor),
            inputViewControl.bottomAnchor.constraint(lessThanOrEqualTo: inputContainerView.bottomAnchor),
            messageLabel.leadingAnchor.constraint(equalTo: rootView.leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(equalTo: rootView.trailingAnchor, constant: -20),
            messageLabel.bottomAnchor.constraint(lessThanOrEqualTo: rootView.bottomAnchor, constant: -24),
        ])
    }

    private func configureQuestionContent() {
        headerView.titleLabel.text = "What’s your target\nweight?"
        headerView.subtitleLabel.text = "Set a realistic goal you’d like to achieve."
        footerView.primaryButton.configuration?.title = "Continue"

        syncTargetWeightUnit()
        inputViewControl.configure(
            unitTitles: [String(localized: viewModel.draft.currentWeight.unit.title)],
            onValueChanged: { [weak self] value in
                guard let self else { return }
                self.viewModel.draft.targetWeight = BodyWeight(value: value, unit: self.viewModel.draft.currentWeight.unit)
            },
            onUnitChanged: { _ in }
        )
    }

    private func syncTargetWeightUnit() {
        let currentWeightUnit = viewModel.draft.currentWeight.unit
        guard viewModel.draft.targetWeight.unit != currentWeightUnit else { return }
        viewModel.draft.targetWeight = viewModel.draft.targetWeight.converted(to: currentWeightUnit)
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
        syncTargetWeightUnit()
        inputViewControl.render(
            value: viewModel.draft.targetWeight.value,
            selectedUnitIndex: 0
        )
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
    UINavigationController(rootViewController: TargetWeightQuestionViewController(
        viewModel: OnboardingPreviewSupport.makeViewModel(currentStep: .targetWeight)
    ))
}
#endif
