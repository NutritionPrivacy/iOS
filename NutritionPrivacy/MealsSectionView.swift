import UIKit

struct MealEntryModel {
    let id: UUID
    let name: String
    let calories: Int
    let proteinGrams: Double
    let carbGrams: Double
    let fatGrams: Double
    let time: Date

    var timeText: String {
        time.formatted(date: .omitted, time: .shortened)
    }

    var macroText: String {
        "P \(Int(proteinGrams))g  C \(Int(carbGrams))g  F \(Int(fatGrams))g"
    }
}

struct MealsSectionModel {
    let entries: [MealEntryModel]
}

private final class MealRowView: UIView {
    private let titleLabel = UILabel()
    private let macroLabel = UILabel()
    private let caloriesLabel = UILabel()
    private let timeLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        let iconView = UIImageView(image: UIImage(systemName: "fork.knife"))
        iconView.tintColor = UIColor(red: 0.15, green: 0.68, blue: 0.43, alpha: 1)
        iconView.contentMode = .scaleAspectFit
        iconView.setSize(width: 18, height: 18)

        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.adjustsFontForContentSizeCategory = true

        macroLabel.font = .preferredFont(forTextStyle: .subheadline)
        macroLabel.textColor = .secondaryLabel
        macroLabel.adjustsFontForContentSizeCategory = true

        caloriesLabel.font = .roundedSystemFont(ofSize: 16, weight: .bold)
        caloriesLabel.adjustsFontForContentSizeCategory = true
        caloriesLabel.textAlignment = .right

        timeLabel.font = .preferredFont(forTextStyle: .caption1)
        timeLabel.textColor = .secondaryLabel
        timeLabel.adjustsFontForContentSizeCategory = true
        timeLabel.textAlignment = .right

        let leftStack = UIStackView(arrangedSubviews: [titleLabel, macroLabel])
        leftStack.axis = .vertical
        leftStack.spacing = 4

        let rightStack = UIStackView(arrangedSubviews: [caloriesLabel, timeLabel])
        rightStack.axis = .vertical
        rightStack.spacing = 4
        rightStack.alignment = .trailing

        let row = UIStackView(arrangedSubviews: [iconView, leftStack, UIView(), rightStack])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12

        addSubview(row)
        row.pinEdges(to: self)
    }

    func apply(model: MealEntryModel) {
        titleLabel.text = model.name
        macroLabel.text = model.macroText
        caloriesLabel.text = "\(model.calories) kcal"
        timeLabel.text = model.timeText
    }
}

final class MealsSectionView: UIView {
    private let stackView = UIStackView()
    private let emptyStateView = UIView()

    var onAddMeal: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        backgroundColor = .secondarySystemGroupedBackground
        layer.cornerRadius = 24
        layer.cornerCurve = .continuous

        let titleLabel = UILabel()
        titleLabel.text = "TODAY'S MEALS"
        titleLabel.font = .roundedSystemFont(ofSize: 12, weight: .bold)
        titleLabel.textColor = .secondaryLabel

        var addConfiguration = UIButton.Configuration.plain()
        addConfiguration.image = UIImage(systemName: "plus.circle.fill")
        addConfiguration.baseForegroundColor = UIColor(red: 0.15, green: 0.68, blue: 0.43, alpha: 1)
        let addButton = UIButton(configuration: addConfiguration)
        addButton.addTarget(self, action: #selector(didTapAddMeal), for: .touchUpInside)

        let headerStack = UIStackView(arrangedSubviews: [titleLabel, UIView(), addButton])
        headerStack.axis = .horizontal
        headerStack.alignment = .center

        stackView.axis = .vertical
        stackView.spacing = 16

        let emptyIcon = UIImageView(image: UIImage(systemName: "takeoutbag.and.cup.and.straw"))
        emptyIcon.tintColor = .tertiaryLabel
        emptyIcon.contentMode = .scaleAspectFit
        emptyIcon.setSize(width: 28, height: 28)

        let emptyTitleLabel = UILabel()
        emptyTitleLabel.text = "No meals logged yet"
        emptyTitleLabel.font = .preferredFont(forTextStyle: .headline)
        emptyTitleLabel.textColor = .secondaryLabel
        emptyTitleLabel.textAlignment = .center

        let emptySubtitleLabel = UILabel()
        emptySubtitleLabel.text = "Add breakfast, lunch, or dinner to build out today’s overview."
        emptySubtitleLabel.font = .preferredFont(forTextStyle: .subheadline)
        emptySubtitleLabel.textColor = .tertiaryLabel
        emptySubtitleLabel.textAlignment = .center
        emptySubtitleLabel.numberOfLines = 0

        let emptyStack = UIStackView(arrangedSubviews: [emptyIcon, emptyTitleLabel, emptySubtitleLabel])
        emptyStack.axis = .vertical
        emptyStack.spacing = 8
        emptyStack.alignment = .center

        emptyStateView.addSubview(emptyStack)
        emptyStack.pinEdges(to: emptyStateView, insets: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8))

        let containerStack = UIStackView(arrangedSubviews: [headerStack, stackView, emptyStateView])
        containerStack.axis = .vertical
        containerStack.spacing = 16

        addSubview(containerStack)
        containerStack.pinEdges(to: self, insets: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20))
    }

    @objc
    private func didTapAddMeal() {
        onAddMeal?()
    }

    func apply(model: MealsSectionModel) {
        stackView.arrangedSubviews.forEach { view in
            stackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        if model.entries.isEmpty {
            stackView.isHidden = true
            emptyStateView.isHidden = false
            return
        }

        stackView.isHidden = false
        emptyStateView.isHidden = true

        for (index, entry) in model.entries.enumerated() {
            let row = MealRowView()
            row.apply(model: entry)
            stackView.addArrangedSubview(row)

            if index < model.entries.count - 1 {
                let divider = UIView()
                divider.backgroundColor = UIColor.separator.withAlphaComponent(0.35)
                NSLayoutConstraint.activate([
                    divider.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale)
                ])
                stackView.addArrangedSubview(divider)
            }
        }
    }
}
