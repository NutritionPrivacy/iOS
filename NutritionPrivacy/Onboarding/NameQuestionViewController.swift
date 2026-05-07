import SwiftUI
import UIKit

final class NameQuestionViewController: UIViewController, OnboardingFooterHosting {
    private enum Design {
        static let background = UIColor.systemBackground
        static let fieldBackground = UIColor(red: 0.04, green: 0.06, blue: 0.07, alpha: 1)
        static let border = UIColor(white: 1, alpha: 0.13)
        static let ink = UIColor(white: 0.97, alpha: 1)
        static let secondaryInk = UIColor(red: 0.76, green: 0.78, blue: 0.86, alpha: 1)
        static let green = UIColor(red: 0.43, green: 0.86, blue: 0.31, alpha: 1)
        static let buttonBackground = UIColor(red: 0.07, green: 0.17, blue: 0.09, alpha: 1)
    }

    private let viewModel: OnboardingViewModel
    private let step: OnboardingStep = .name
    private let rootView = UIView()
    private let headerView = OnboardingHeaderView()
    private let inputContainerView = UIView()
    private let messageLabel = UILabel()
    let footerView = OnboardingFooterView()
    private let inputViewControl = TextQuestionInputView()

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
        headerView.titleLabel.font = .roundedSystemFont(ofSize: 34, weight: .bold)
        headerView.titleLabel.textColor = .label
        headerView.subtitleLabel.font = .roundedSystemFont(ofSize: 22, weight: .regular)
        headerView.subtitleLabel.textColor = .secondaryLabel
        headerView.subtitleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        configureInputAppearance()
        configureFooterAppearance()

        rootView.addSubview(headerView)
        rootView.addSubview(inputContainerView)
        inputContainerView.addSubview(inputViewControl)
        rootView.addSubview(messageLabel)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: rootView.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: rootView.safeAreaLayoutGuide.leadingAnchor, constant: 30),
            headerView.trailingAnchor.constraint(equalTo: rootView.safeAreaLayoutGuide.trailingAnchor, constant: -30),
            inputContainerView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 64),
            inputContainerView.leadingAnchor.constraint(equalTo: rootView.safeAreaLayoutGuide.leadingAnchor, constant: 30),
            inputContainerView.trailingAnchor.constraint(equalTo: rootView.safeAreaLayoutGuide.trailingAnchor, constant: -30),
            inputContainerView.bottomAnchor.constraint(equalTo: messageLabel.topAnchor, constant: -24),
            inputContainerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 80),
            inputViewControl.topAnchor.constraint(equalTo: inputContainerView.topAnchor),
            inputViewControl.leadingAnchor.constraint(equalTo: inputContainerView.leadingAnchor),
            inputViewControl.trailingAnchor.constraint(equalTo: inputContainerView.trailingAnchor),
            inputViewControl.heightAnchor.constraint(equalToConstant: 64),
            messageLabel.leadingAnchor.constraint(equalTo: rootView.safeAreaLayoutGuide.leadingAnchor, constant: 30),
            messageLabel.trailingAnchor.constraint(equalTo: rootView.safeAreaLayoutGuide.trailingAnchor, constant: -30),
            messageLabel.bottomAnchor.constraint(lessThanOrEqualTo: rootView.bottomAnchor, constant: -24),
        ])
    }

    private func configureQuestionContent() {
        headerView.titleLabel.text = "What’s your name?"
        headerView.subtitleLabel.text = "We’ll use this to personalize your experience."
        footerView.primaryButton.configuration?.title = "Continue"

        inputViewControl.setPlaceholder("Enter your name")
        inputViewControl.textField.attributedPlaceholder = NSAttributedString(
            string: "Enter your name",
            attributes: [
                .font: UIFont.roundedSystemFont(ofSize: 20, weight: .regular),
                .foregroundColor: Design.secondaryInk,
            ]
        )
        inputViewControl.onTextChanged = { [weak self] text in
            self?.viewModel.draft.name = text
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
        inputViewControl.setText(viewModel.draft.name)
    }

    private func primaryTapped() {
        viewModel.navigateNext(from: step)
    }

    private func secondaryTapped() {}

    private func configureInputAppearance() {
        inputViewControl.textField.textColor = .label
        inputViewControl.textField.tintColor = Design.green
        inputViewControl.textField.layer.cornerRadius = 15
        inputViewControl.textField.layer.borderWidth = 1
        inputViewControl.textField.layer.borderColor = UIColor.lightGray.cgColor
        inputViewControl.textField.font = .roundedSystemFont(ofSize: 20, weight: .regular)
    }

    private func configureFooterAppearance() {
        footerView.primaryButton.configuration?.cornerStyle = .large
        footerView.primaryButton.configuration?.baseBackgroundColor = .primaryGreen
        footerView.primaryButton.configuration?.baseForegroundColor = .white
        footerView.primaryButton.configuration?.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .roundedSystemFont(ofSize: 18, weight: .semibold)
            return outgoing
        }
        footerView.primaryButton.configuration?.contentInsets = NSDirectionalEdgeInsets(top: 21, leading: 24, bottom: 21, trailing: 24)
        footerView.primaryButton.layer.cornerRadius = 22
        footerView.primaryButton.layer.borderWidth = 1
        footerView.primaryButton.layer.borderColor = Design.green.withAlphaComponent(0.16).cgColor
        footerView.primaryButton.clipsToBounds = true
    }

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
    let viewModel = OnboardingPreviewSupport.makeViewModel(currentStep: .name)
    let flowViewController = OnboardingFlowViewController(
        viewModel: viewModel,
        makeViewController: { step in
            switch step {
            case .name:
                return NameQuestionViewController(viewModel: viewModel)
            default:
                return UIViewController()
            }
        }
    )
    return UINavigationController(rootViewController: flowViewController)
}
#endif
