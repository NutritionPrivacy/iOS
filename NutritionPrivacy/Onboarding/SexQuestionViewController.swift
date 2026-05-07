import SwiftUI
import UIKit

final class SexQuestionViewController: UIViewController, OnboardingFooterHosting {
    private let viewModel: OnboardingViewModel
    private let step: OnboardingStep = .sexForCalculation
    private let rootView = UIView()
    private let headerView = OnboardingHeaderView()
    private let contentContainerView = UIView()
    private let messageLabel = UILabel()
    let footerView = OnboardingFooterView()
    private let optionsView = OptionButtonListView<SexForCalculation?>(
        options: [.female, .male, nil],
        minimumRowHeight: 76,
        titleProvider: { option in
            option.map { String(localized: $0.title) } ?? "Prefer not to say"
        },
        imageProvider: { option in
            SexOptionIcon.image(for: option)
        }
    )

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
        headerView.titleLabel.text = "What’s your gender?"
        headerView.subtitleLabel.text = "This helps improve the accuracy of your plan."
        footerView.primaryButton.configuration?.title = "Continue"
        optionsView.onSelection = { [weak self] selection in
            self?.viewModel.draft.sexForCalculation = selection
        }
    }

    private func applySharedModelToView() {
        messageLabel.text = viewModel.errorMessage
        messageLabel.isHidden = (viewModel.errorMessage ?? "").isEmpty
        footerView.primaryButton.isEnabled = viewModel.currentStep == step && viewModel.canContinue
        if viewModel.isSaving {
            footerView.activityIndicator.startAnimating()
        } else {
            footerView.activityIndicator.stopAnimating()
        }
    }

    private func applyModelToView() {
        applySharedModelToView()
        optionsView.setSelectedOption(viewModel.draft.sexForCalculation)
    }

    private func primaryTapped() {
        viewModel.navigateNext(from: step)
    }

    private func secondaryTapped() {
        viewModel.navigateNext(from: step)
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

private enum SexOptionIcon {
    private static let badgeSize = CGSize(width: 40, height: 40)
    private static let symbolGlyphSize = CGSize(width: 22, height: 22)

    static func image(for option: SexForCalculation?) -> UIImage {
        let image: UIImage
        let color: UIColor
        let backgroundColor: UIColor
        let glyphSize: CGSize

        switch option {
        case .some(.female):
            image = UIImage(resource: .Onboarding.femaleSymbol)
            color = UIColor(red: 1.00, green: 0.25, blue: 0.42, alpha: 1.00)
            backgroundColor = UIColor(red: 1.00, green: 0.91, blue: 0.94, alpha: 1.00)
            glyphSize = symbolGlyphSize
        case .some(.male):
            image = UIImage(resource: .Onboarding.maleSymbol)
            color = UIColor(red: 0.22, green: 0.55, blue: 1.00, alpha: 1.00)
            backgroundColor = UIColor(red: 0.91, green: 0.96, blue: 1.00, alpha: 1.00)
            glyphSize = symbolGlyphSize
        case nil:
            image = UIImage(resource: .Onboarding.genderNeutralSymbol)
            color = UIColor(red: 0.25, green: 0.28, blue: 0.33, alpha: 1.00)
            backgroundColor = UIColor(red: 0.96, green: 0.97, blue: 0.98, alpha: 1.00)
            glyphSize = symbolGlyphSize
        }

        let glyph = image
            .withRenderingMode(.alwaysTemplate)
            .scaled(to: glyphSize)
            .withTintColor(color, renderingMode: .alwaysOriginal)

        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        format.opaque = false

        return UIGraphicsImageRenderer(size: badgeSize, format: format).image { _ in
            backgroundColor.setFill()
            UIBezierPath(ovalIn: CGRect(origin: .zero, size: badgeSize)).fill()

            glyph.draw(in: CGRect(
                x: (badgeSize.width - glyphSize.width) / 2,
                y: (badgeSize.height - glyphSize.height) / 2,
                width: glyphSize.width,
                height: glyphSize.height
            ))
        }
    }
}

private extension UIImage {
    func scaled(to size: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        format.opaque = false

        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

#if DEBUG
#Preview {
    UINavigationController(
        rootViewController: OnboardingPreviewSupport.makeFlowViewController(currentStep: .sexForCalculation)
    )
}
#endif
