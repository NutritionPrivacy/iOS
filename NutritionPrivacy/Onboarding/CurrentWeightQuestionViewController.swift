import SwiftUI
import UIKit

final class CurrentWeightQuestionViewController: UIViewController, OnboardingFooterHosting {
    private let viewModel: OnboardingViewModel
    private let step: OnboardingStep = .currentWeight
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
        headerView.titleLabel.text = "What is your current weight?"
        headerView.subtitleLabel.text = "We save this as your starting check-in."
        footerView.primaryButton.configuration?.title = "Continue"

        inputViewControl.configure(
            unitTitles: WeightUnit.allCases.map { String(localized: $0.title) },
            onValueChanged: { [weak self] value in
                guard let self else { return }
                self.viewModel.draft.currentWeight = BodyWeight(value: value, unit: self.viewModel.draft.currentWeight.unit)
            },
            onUnitChanged: { [weak self] index in
                guard let self, let unit = WeightUnit.allCases[safe: index] else { return }
                self.viewModel.draft.currentWeight = self.viewModel.draft.currentWeight.converted(to: unit)
            }
        )
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
        inputViewControl.render(
            value: viewModel.draft.currentWeight.value,
            selectedUnitIndex: WeightUnit.allCases.firstIndex(of: viewModel.draft.currentWeight.unit) ?? 0
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
    UINavigationController(rootViewController: CurrentWeightQuestionViewController(
        viewModel: OnboardingPreviewSupport.makeViewModel(currentStep: .currentWeight)
    ))
}
#endif
