import SwiftUI
import UIKit

final class WelcomeOnboardingViewController: UIViewController, OnboardingFooterHosting {
    private let viewModel: OnboardingViewModel
    private let step: OnboardingStep = .welcome
    private let rootView = UIView()
    private let iconView = UIImageView(image: UIImage(systemName: "leaf.fill"))
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let pageDots = UIPageControl()
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
        applyModelToView()
    }

    private func setUpLayout() {
        iconView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        pageDots.translatesAutoresizingMaskIntoConstraints = false

        iconView.tintColor = OnboardingDesign.green
        iconView.backgroundColor = OnboardingDesign.cardBackground
        iconView.layer.cornerRadius = 14
        iconView.layer.shadowColor = UIColor.black.cgColor
        iconView.layer.shadowOpacity = 0.08
        iconView.layer.shadowRadius = 14
        iconView.layer.shadowOffset = CGSize(width: 0, height: 6)
        iconView.contentMode = .center

        if let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .title1).withDesign(.rounded)?
            .withSymbolicTraits(.traitBold) {
            titleLabel.font = UIFont(descriptor: descriptor, size: 0)
        } else {
            titleLabel.font = .preferredFont(forTextStyle: .title1)
        }
        titleLabel.textColor = OnboardingDesign.ink
        titleLabel.numberOfLines = 0

        subtitleLabel.font = .preferredFont(forTextStyle: .subheadline)
        subtitleLabel.textColor = OnboardingDesign.secondaryInk
        subtitleLabel.numberOfLines = 0

        pageDots.numberOfPages = 4
        pageDots.currentPage = 0
        pageDots.currentPageIndicatorTintColor = OnboardingDesign.green
        pageDots.pageIndicatorTintColor = OnboardingDesign.progressTrack
        pageDots.isUserInteractionEnabled = false

        rootView.addSubview(iconView)
        rootView.addSubview(titleLabel)
        rootView.addSubview(subtitleLabel)
        rootView.addSubview(pageDots)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: rootView.leadingAnchor, constant: 32),
            iconView.topAnchor.constraint(equalTo: rootView.safeAreaLayoutGuide.topAnchor, constant: 88),
            iconView.widthAnchor.constraint(equalToConstant: 56),
            iconView.heightAnchor.constraint(equalToConstant: 56),
            titleLabel.leadingAnchor.constraint(equalTo: rootView.leadingAnchor, constant: 32),
            titleLabel.trailingAnchor.constraint(equalTo: rootView.trailingAnchor, constant: -32),
            titleLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 28),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 18),
            pageDots.centerXAnchor.constraint(equalTo: rootView.centerXAnchor),
            pageDots.bottomAnchor.constraint(equalTo: rootView.bottomAnchor, constant: -40),
        ])
    }

    private func configureContent() {
        titleLabel.text = "Let’s personalize\nyour experience"
        subtitleLabel.text = "Answer a few quick questions so we can build a plan that works for you."
        footerView.primaryButton.configuration?.title = "Get Started"
        footerView.primaryButton.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.viewModel.navigateNext(from: self.step)
        }, for: .touchUpInside)
    }

    private func applyModelToView() {
        footerView.primaryButton.isEnabled = viewModel.currentStep == step
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
    WelcomeOnboardingViewController(
        viewModel: OnboardingPreviewSupport.makeViewModel(currentStep: .welcome)
    )
}
#endif
