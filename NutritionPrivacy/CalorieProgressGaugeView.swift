import UIKit

struct CalorieProgressGaugeModel {
    let title: String
    let highlightedValue: String
    let detailText: String
    let progress: CGFloat

    static let empty = CalorieProgressGaugeModel(
        title: "Remaining",
        highlightedValue: "--",
        detailText: "of -- kcal",
        progress: 0
    )
}

final class CalorieProgressGaugeView: UIView {
    private let trackLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    private let detailLabel = UILabel()
    private let contentStack = UIStackView()

    private var currentModel: CalorieProgressGaugeModel = .empty

    override init(frame: CGRect) {
        super.init(frame: frame)

        layer.addSublayer(trackLayer)
        layer.addSublayer(progressLayer)

        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.lineCap = .round

        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineCap = .round
        progressLayer.strokeStart = 0

        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = .secondaryLabel
        titleLabel.textAlignment = .center

        if let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .largeTitle)
            .withDesign(.rounded)?
            .withSymbolicTraits(.traitBold) {
            valueLabel.font = UIFont(descriptor: descriptor, size: 0).withSize(50)
        } else {
            valueLabel.font = .systemFont(ofSize: 50, weight: .bold)
        }
        valueLabel.adjustsFontForContentSizeCategory = true
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.minimumScaleFactor = 0.7
        valueLabel.textAlignment = .center

        detailLabel.font = .preferredFont(forTextStyle: .title3)
        detailLabel.adjustsFontForContentSizeCategory = true
        detailLabel.textColor = .secondaryLabel
        detailLabel.textAlignment = .center

        contentStack.axis = .vertical
        contentStack.alignment = .center
        contentStack.spacing = 6
        contentStack.addArrangedSubview(titleLabel)
        contentStack.addArrangedSubview(valueLabel)
        contentStack.addArrangedSubview(detailLabel)

        addSubview(contentStack)
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            contentStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            contentStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            contentStack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 60),
            contentStack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -60),
            heightAnchor.constraint(greaterThanOrEqualToConstant: 260)
        ])

        apply(model: .empty)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let lineWidth = min(bounds.width, bounds.height) * 0.095
        let radius = (min(bounds.width, bounds.height) - lineWidth) / 2
        let centerPoint = CGPoint(x: bounds.midX, y: bounds.midY)
        let startAngle = CGFloat(-0.5 * .pi)
        let endAngle = CGFloat(1.5 * .pi)
        let gaugePath = UIBezierPath(
            arcCenter: centerPoint,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: true
        )

        trackLayer.frame = bounds
        trackLayer.path = gaugePath.cgPath
        trackLayer.lineWidth = lineWidth

        progressLayer.frame = bounds
        progressLayer.path = gaugePath.cgPath
        progressLayer.lineWidth = lineWidth
    }

    func apply(model: CalorieProgressGaugeModel) {
        currentModel = model

        titleLabel.text = model.title.uppercased()
        valueLabel.text = model.highlightedValue
        detailLabel.text = model.detailText

        trackLayer.strokeColor = UIColor.secondarySystemFill.cgColor
        progressLayer.strokeColor = progressColor(for: model.progress).cgColor
        progressLayer.strokeEnd = max(0, min(model.progress, 1))
    }

    private func progressColor(for progress: CGFloat) -> UIColor {
        switch progress {
        case 0.8...:
            return .systemRed
        case 0.65...:
            return .systemOrange
        default:
            return UIColor(red: 0.08, green: 0.68, blue: 0.28, alpha: 1)
        }
    }
}

#if DEBUG
private final class CalorieProgressGaugePreviewViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        let stackView = UIStackView(arrangedSubviews: previewCards())
        stackView.axis = .vertical
        stackView.spacing = 20

        let scrollView = UIScrollView()
        view.addSubview(scrollView)
        scrollView.pinEdgesToSafeArea(view)

        let contentView = UIView()
        scrollView.addSubview(contentView)
        contentView.pinEdges(to: scrollView.contentLayoutGuide)
        contentView.matchWidth(to: scrollView.frameLayoutGuide)

        contentView.addSubview(stackView)
        stackView.pinEdges(to: contentView, insets: UIEdgeInsets(top: 24, left: 20, bottom: 24, right: 20))
    }

    private func previewCards() -> [UIView] {
        [
            makeCard(model: .empty),
            makeCard(model: CalorieProgressGaugeModel(
                title: "Remaining",
                highlightedValue: "1,420",
                detailText: "of 2,100 kcal",
                progress: 0.32
            )),
            makeCard(model: CalorieProgressGaugeModel(
                title: "Remaining",
                highlightedValue: "340",
                detailText: "of 2,100 kcal",
                progress: 0.72
            )),
            makeCard(model: CalorieProgressGaugeModel(
                title: "Remaining",
                highlightedValue: "120",
                detailText: "of 2,100 kcal",
                progress: 0.94
            ))
        ]
    }

    private func makeCard(model: CalorieProgressGaugeModel) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .secondarySystemBackground
        containerView.layer.cornerRadius = 28
        containerView.layer.cornerCurve = .continuous

        let gaugeView = CalorieProgressGaugeView()
        gaugeView.apply(model: model)

        containerView.addSubview(gaugeView)
        gaugeView.pinEdges(to: containerView, insets: UIEdgeInsets(top: 24, left: 16, bottom: 24, right: 16))

        return containerView
    }
}

#Preview {
    UINavigationController(rootViewController: CalorieProgressGaugePreviewViewController())
}
#endif
