import UIKit

struct MacroProgressModel {
    let name: String
    let consumed: Int
    let goal: Int
    let unit: String
    let color: UIColor

    var progress: CGFloat {
        guard goal > 0 else { return 0 }
        return min(CGFloat(consumed) / CGFloat(goal), 1)
    }

    var progressText: String { "\(consumed)/\(goal)\(unit)" }
}

private final class MacroProgressCardView: UIView {
    private let nameLabel = UILabel()
    private let valueLabel = UILabel()
    private let trackView = UIView()
    private let fillView = UIView()
    private var fillWidthConstraint: NSLayoutConstraint?

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
        layer.cornerRadius = 20
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = UIColor.separator.withAlphaComponent(0.12).cgColor
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 10)
        layer.shadowOpacity = 0.06
        layer.shadowRadius = 24

        nameLabel.font = .roundedSystemFont(ofSize: 12, weight: .bold)
        nameLabel.adjustsFontForContentSizeCategory = true
        nameLabel.textAlignment = .center

        valueLabel.font = .roundedSystemFont(ofSize: 18, weight: .bold)
        valueLabel.adjustsFontForContentSizeCategory = true
        valueLabel.textAlignment = .center

        trackView.backgroundColor = .tertiarySystemFill
        trackView.layer.cornerRadius = 6
        trackView.layer.cornerCurve = .continuous

        fillView.layer.cornerRadius = 6
        fillView.layer.cornerCurve = .continuous
        trackView.addSubview(fillView)

        let stack = UIStackView(arrangedSubviews: [nameLabel, valueLabel, trackView])
        stack.axis = .vertical
        stack.spacing = 12

        addSubview(stack)
        stack.pinEdges(to: self, insets: UIEdgeInsets(top: 16, left: 12, bottom: 16, right: 12))

        fillView.translatesAutoresizingMaskIntoConstraints = false
        let widthConstraint = fillView.widthAnchor.constraint(equalToConstant: 0)
        fillWidthConstraint = widthConstraint
        NSLayoutConstraint.activate([
            trackView.heightAnchor.constraint(equalToConstant: 12),
            fillView.leadingAnchor.constraint(equalTo: trackView.leadingAnchor),
            fillView.topAnchor.constraint(equalTo: trackView.topAnchor),
            fillView.bottomAnchor.constraint(equalTo: trackView.bottomAnchor),
            widthConstraint
        ])
    }

    func apply(model: MacroProgressModel) {
        nameLabel.text = model.name.uppercased()
        nameLabel.textColor = model.color
        valueLabel.text = model.progressText
        valueLabel.textColor = model.color
        fillView.backgroundColor = model.color

        layoutIfNeeded()
        fillWidthConstraint?.constant = trackView.bounds.width * model.progress

        UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.2) {
            self.trackView.layoutIfNeeded()
        }
    }
}

final class MacrosSectionView: UIView {
    private let proteinCard = MacroProgressCardView()
    private let carbsCard = MacroProgressCardView()
    private let fatCard = MacroProgressCardView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        backgroundColor = .clear

        let stack = UIStackView(arrangedSubviews: [proteinCard, carbsCard, fatCard])
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .fill
        stack.distribution = .fillEqually

        addSubview(stack)
        stack.pinEdges(to: self)
    }

    func apply(protein: MacroProgressModel, carbs: MacroProgressModel, fat: MacroProgressModel) {
        proteinCard.apply(model: protein)
        carbsCard.apply(model: carbs)
        fatCard.apply(model: fat)
    }
}
