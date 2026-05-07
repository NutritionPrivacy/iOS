import UIKit

struct HydrationModel {
    let consumedMl: Int
    let goalMl: Int

    var progress: CGFloat {
        guard goalMl > 0 else { return 0 }
        return min(CGFloat(consumedMl) / CGFloat(goalMl), 1)
    }

    var consumedText: String {
        if consumedMl >= 1000 {
            return String(format: "%.1f L", Double(consumedMl) / 1000)
        }
        return "\(consumedMl) ml"
    }

    var goalText: String {
        if goalMl >= 1000 {
            return String(format: "Goal %.1f L", Double(goalMl) / 1000)
        }
        return "Goal \(goalMl) ml"
    }

    var glassesConsumed: Int { consumedMl / 250 }
    var glassesTotal: Int { max((goalMl + 249) / 250, 1) }
}

private final class HydrationGlassRowView: UIView {
    private let stackView = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        stackView.axis = .horizontal
        stackView.spacing = 6
        stackView.distribution = .fillEqually
        addSubview(stackView)
        stackView.pinEdges(to: self)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func apply(total: Int, filled: Int) {
        stackView.arrangedSubviews.forEach { view in
            stackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        for index in 0..<total {
            let indicator = UIView()
            indicator.backgroundColor = index < filled
                ? UIColor(red: 0.23, green: 0.63, blue: 0.95, alpha: 1)
                : .tertiarySystemFill
            indicator.layer.cornerRadius = 5
            indicator.layer.cornerCurve = .continuous
            indicator.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                indicator.heightAnchor.constraint(equalToConstant: 10)
            ])
            stackView.addArrangedSubview(indicator)
        }
    }
}

final class HydrationCardView: UIView {
    private let iconContainerView = UIView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let amountLabel = UILabel()
    private let goalLabel = UILabel()
    private let glassesView = HydrationGlassRowView()
    private let addButton = UIButton(type: .system)

    var onAddWater: (() -> Void)?

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

        iconContainerView.backgroundColor = UIColor(red: 0.23, green: 0.63, blue: 0.95, alpha: 0.12)
        iconContainerView.layer.cornerRadius = 22
        iconContainerView.layer.cornerCurve = .continuous
        iconContainerView.setSize(width: 44, height: 44)

        iconView.image = UIImage(systemName: "drop.fill")
        iconView.tintColor = UIColor(red: 0.23, green: 0.63, blue: 0.95, alpha: 1)
        iconView.contentMode = .scaleAspectFit
        iconContainerView.addSubview(iconView)
        iconView.center(in: iconContainerView)

        titleLabel.text = "HYDRATION"
        titleLabel.font = .roundedSystemFont(ofSize: 12, weight: .bold)
        titleLabel.textColor = .secondaryLabel

        amountLabel.font = .roundedSystemFont(ofSize: 30, weight: .bold)
        amountLabel.adjustsFontForContentSizeCategory = true

        goalLabel.font = .preferredFont(forTextStyle: .subheadline)
        goalLabel.textColor = .secondaryLabel
        goalLabel.adjustsFontForContentSizeCategory = true

        var buttonConfiguration = UIButton.Configuration.filled()
        buttonConfiguration.title = "Add 250 ml"
        buttonConfiguration.image = UIImage(systemName: "plus")
        buttonConfiguration.imagePadding = 6
        buttonConfiguration.baseForegroundColor = .white
        buttonConfiguration.baseBackgroundColor = UIColor(red: 0.23, green: 0.63, blue: 0.95, alpha: 1)
        buttonConfiguration.cornerStyle = .capsule
        addButton.configuration = buttonConfiguration
        addButton.addTarget(self, action: #selector(didTapAddWater), for: .touchUpInside)

        let headerStack = UIStackView(arrangedSubviews: [iconContainerView, titleLabel, UIView()])
        headerStack.axis = .horizontal
        headerStack.alignment = .center
        headerStack.spacing = 12

        let stack = UIStackView(arrangedSubviews: [headerStack, amountLabel, goalLabel, glassesView, addButton])
        stack.axis = .vertical
        stack.spacing = 14

        addSubview(stack)
        stack.pinEdges(to: self, insets: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20))
    }

    @objc
    private func didTapAddWater() {
        onAddWater?()
    }

    func apply(model: HydrationModel) {
        amountLabel.text = model.consumedText
        goalLabel.text = model.goalText
        glassesView.apply(total: min(model.glassesTotal, 10), filled: min(model.glassesConsumed, 10))
    }
}
