import SwiftUI
import UIKit

final class OnboardingCompletionViewController: UIViewController, OnboardingFooterHosting {
    private let viewModel: OnboardingViewModel
    private let rootView = UIView()
    private let checkContainerView = UIView()
    private let checkImageView = UIImageView(image: UIImage(systemName: "checkmark"))
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    let footerView = OnboardingFooterView()

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
        configureContent()
    }

    private func setUpLayout() {
        checkContainerView.translatesAutoresizingMaskIntoConstraints = false
        checkImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        checkContainerView.backgroundColor = OnboardingDesign.iconBackground
        checkContainerView.layer.cornerRadius = 52
        checkImageView.tintColor = OnboardingDesign.green
        checkImageView.contentMode = .scaleAspectFit

        titleLabel.font = .preferredFont(forTextStyle: .title1)
        titleLabel.textColor = OnboardingDesign.ink
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        subtitleLabel.font = .preferredFont(forTextStyle: .subheadline)
        subtitleLabel.textColor = OnboardingDesign.secondaryInk
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        rootView.addSubview(checkContainerView)
        checkContainerView.addSubview(checkImageView)
        rootView.addSubview(titleLabel)
        rootView.addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            checkContainerView.centerXAnchor.constraint(equalTo: rootView.centerXAnchor),
            checkContainerView.centerYAnchor.constraint(equalTo: rootView.centerYAnchor, constant: -84),
            checkContainerView.widthAnchor.constraint(equalToConstant: 104),
            checkContainerView.heightAnchor.constraint(equalToConstant: 104),
            checkImageView.centerXAnchor.constraint(equalTo: checkContainerView.centerXAnchor),
            checkImageView.centerYAnchor.constraint(equalTo: checkContainerView.centerYAnchor),
            checkImageView.widthAnchor.constraint(equalToConstant: 40),
            checkImageView.heightAnchor.constraint(equalToConstant: 40),
            titleLabel.topAnchor.constraint(equalTo: checkContainerView.bottomAnchor, constant: 44),
            titleLabel.leadingAnchor.constraint(equalTo: rootView.leadingAnchor, constant: 32),
            titleLabel.trailingAnchor.constraint(equalTo: rootView.trailingAnchor, constant: -32),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
        ])
    }

    private func configureContent() {
        titleLabel.text = "You’re all set!"
        subtitleLabel.text = "Your personalized plan is ready. Let’s build healthy habits that last a lifetime."
        footerView.primaryButton.configuration?.title = "Go to Dashboard"
        footerView.primaryButton.configuration?.baseBackgroundColor = OnboardingDesign.prominentGreen
        footerView.primaryButton.configuration?.baseForegroundColor = .white
        footerView.primaryButton.addAction(UIAction { [weak self] _ in
            self?.viewModel.dismissOnboarding()
        }, for: .touchUpInside)
    }
}

#if DEBUG
#Preview {
    OnboardingCompletionViewController(
        viewModel: OnboardingPreviewSupport.makeViewModel(currentStep: .completion)
    )
}
#endif
