import UIKit
import Dependencies

@MainActor
final class MainViewController: UIViewController {
    private let appState: AppState
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()
    private let gaugeContainerView = UIView()
    private let gaugeView = CalorieProgressGaugeView()
    private let emptyStateLabel = UILabel()

    init(appState: AppState) {
        self.appState = appState
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Today"

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "gearshape"),
            style: .plain,
            target: self,
            action: #selector(didTapSettings)
        )

        configureLayout()
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

    private func configureLayout() {
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)
        scrollView.pinEdgesToSafeArea(view)

        scrollView.addSubview(contentView)
        contentView.pinEdges(to: scrollView.contentLayoutGuide)
        contentView.matchWidth(to: scrollView.frameLayoutGuide)

        stackView.axis = .vertical
        stackView.spacing = 24
        contentView.addSubview(stackView)
        stackView.pinEdges(to: contentView, insets: UIEdgeInsets(top: 24, left: 20, bottom: 32, right: 20))

        gaugeContainerView.backgroundColor = .secondarySystemBackground
        gaugeContainerView.layer.cornerRadius = 28
        gaugeContainerView.layer.cornerCurve = .continuous

        gaugeContainerView.addSubview(gaugeView)
        gaugeView.pinEdges(to: gaugeContainerView, insets: UIEdgeInsets(top: 24, left: 16, bottom: 24, right: 16))

        emptyStateLabel.font = .preferredFont(forTextStyle: .body)
        emptyStateLabel.adjustsFontForContentSizeCategory = true
        emptyStateLabel.textColor = .secondaryLabel
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.numberOfLines = 0
        emptyStateLabel.text = "Complete onboarding to see your calorie target progress."

        stackView.addArrangedSubview(gaugeContainerView)
        stackView.addArrangedSubview(emptyStateLabel)
    }

    private func applyModelToView() {
        if appState.isSetup {
            gaugeView.apply(model: appState.calorieProgressGaugeModel)
            gaugeContainerView.isHidden = appState.nutritionPlan == nil
            emptyStateLabel.isHidden = appState.nutritionPlan != nil
        } else {
            gaugeContainerView.isHidden = true
            emptyStateLabel.isHidden = false
        }
    }

    @objc
    private func didTapSettings() {
    }
}
