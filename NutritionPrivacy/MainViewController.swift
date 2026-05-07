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
    private let macrosSection = MacrosSectionView()
    private let mealsSection = MealsSectionView()
    private let hydrationCard = HydrationCardView()

    private let emptyStateView = UIView()
    private let emptyStateIconView = UIImageView()
    private let emptyStateTitleLabel = UILabel()
    private let emptyStateSubtitleLabel = UILabel()

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
        view.backgroundColor = .systemGroupedBackground
        title = "Today"
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.largeTitleDisplayMode = .never

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "gearshape"),
            style: .plain,
            target: self,
            action: #selector(didTapSettings)
        )

        configureLayout()
        connectCallbacks()
    }

    private func applyCardChrome(to view: UIView) {
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.separator.withAlphaComponent(0.12).cgColor
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 10)
        view.layer.shadowOpacity = 0.06
        view.layer.shadowRadius = 24
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
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .automatic
        view.addSubview(scrollView)
        scrollView.pinEdges(to: view)

        scrollView.addSubview(contentView)
        contentView.pinEdges(to: scrollView.contentLayoutGuide)
        contentView.matchWidth(to: scrollView.frameLayoutGuide)

        stackView.axis = .vertical
        stackView.spacing = 18
        contentView.addSubview(stackView)
        stackView.pinEdges(to: contentView, insets: UIEdgeInsets(top: 12, left: 20, bottom: 20, right: 20))

        gaugeContainerView.backgroundColor = .secondarySystemGroupedBackground
        gaugeContainerView.layer.cornerRadius = 28
        gaugeContainerView.layer.cornerCurve = .continuous
        applyCardChrome(to: gaugeContainerView)

        gaugeContainerView.addSubview(gaugeView)
        gaugeView.pinEdges(to: gaugeContainerView, insets: UIEdgeInsets(top: 24, left: 16, bottom: 24, right: 16))

        [hydrationCard, mealsSection].forEach(applyCardChrome)

        emptyStateView.backgroundColor = .secondarySystemGroupedBackground
        emptyStateView.layer.cornerRadius = 24
        emptyStateView.layer.cornerCurve = .continuous
        applyCardChrome(to: emptyStateView)

        emptyStateIconView.image = UIImage(systemName: "sparkles.rectangle.stack")
        emptyStateIconView.tintColor = .secondaryLabel
        emptyStateIconView.contentMode = .scaleAspectFit
        emptyStateIconView.setSize(width: 34, height: 34)

        emptyStateTitleLabel.font = .preferredFont(forTextStyle: .title3)
        emptyStateTitleLabel.adjustsFontForContentSizeCategory = true
        emptyStateTitleLabel.textAlignment = .center
        emptyStateTitleLabel.text = "Finish setup to unlock your dashboard"

        emptyStateSubtitleLabel.font = .preferredFont(forTextStyle: .body)
        emptyStateSubtitleLabel.adjustsFontForContentSizeCategory = true
        emptyStateSubtitleLabel.textColor = .secondaryLabel
        emptyStateSubtitleLabel.textAlignment = .center
        emptyStateSubtitleLabel.numberOfLines = 0
        emptyStateSubtitleLabel.text = "Your calorie target, macro progress, meals, and hydration will appear here after onboarding."

        let emptyStateStack = UIStackView(arrangedSubviews: [emptyStateIconView, emptyStateTitleLabel, emptyStateSubtitleLabel])
        emptyStateStack.axis = .vertical
        emptyStateStack.spacing = 12
        emptyStateStack.alignment = .center
        emptyStateView.addSubview(emptyStateStack)
        emptyStateStack.pinEdges(to: emptyStateView, insets: UIEdgeInsets(top: 24, left: 24, bottom: 24, right: 24))

        stackView.addArrangedSubview(gaugeContainerView)
        stackView.addArrangedSubview(macrosSection)
        stackView.addArrangedSubview(hydrationCard)
        stackView.addArrangedSubview(mealsSection)
        stackView.addArrangedSubview(emptyStateView)
    }

    private func connectCallbacks() {
        hydrationCard.onAddWater = { [weak self] in
            guard let self else { return }
            self.appState.hydrationConsumedMl += 250
            self.applyModelToView()
        }

        mealsSection.onAddMeal = { [weak self] in
            self?.showMealLoggingPlaceholder()
        }
    }

    private func applyModelToView() {
        if appState.isSetup {
            gaugeView.apply(model: appState.calorieProgressGaugeModel)
            let macros = appState.macrosModel
            macrosSection.apply(protein: macros.protein, carbs: macros.carbs, fat: macros.fat)
            hydrationCard.apply(model: appState.hydrationModel)
            mealsSection.apply(model: appState.mealsSectionModel)

            let hasPlan = appState.nutritionPlan != nil
            gaugeContainerView.isHidden = !hasPlan
            macrosSection.isHidden = !hasPlan
            hydrationCard.isHidden = false
            mealsSection.isHidden = false
            emptyStateView.isHidden = hasPlan
        } else {
            gaugeContainerView.isHidden = true
            macrosSection.isHidden = true
            hydrationCard.isHidden = true
            mealsSection.isHidden = true
            emptyStateView.isHidden = false
        }
    }

    private func showMealLoggingPlaceholder() {
        let alert = UIAlertController(
            title: "Meal Logging Coming Soon",
            message: "This overview is ready for today’s meals. The add meal flow can be connected next.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    @objc
    private func didTapSettings() {
    }
}
