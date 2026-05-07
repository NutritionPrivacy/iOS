import UIKit

enum OnboardingDesign {
    static let cardBackground = UIColor.secondarySystemBackground
    static let fieldBackground = UIColor.secondarySystemBackground
    static let border = UIColor.separator
    static let progressTrack = UIColor.tertiarySystemFill
    static let ink = UIColor.label
    static let secondaryInk = UIColor.secondaryLabel

    static let green = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.43, green: 0.86, blue: 0.31, alpha: 1)
            : UIColor(red: 0.05, green: 0.55, blue: 0.12, alpha: 1)
    }
    static let prominentGreen = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.29, green: 0.62, blue: 0.23, alpha: 1)
            : UIColor(red: 0.05, green: 0.55, blue: 0.12, alpha: 1)
    }
    static let primaryButtonBackground = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.07, green: 0.17, blue: 0.09, alpha: 1)
            : UIColor(red: 0.93, green: 0.97, blue: 0.93, alpha: 1)
    }
    static let selectedBackground = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.07, green: 0.18, blue: 0.07, alpha: 1)
            : UIColor(red: 0.93, green: 0.98, blue: 0.93, alpha: 1)
    }
    static let iconBackground = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.10, green: 0.18, blue: 0.10, alpha: 1)
            : UIColor(red: 0.93, green: 0.98, blue: 0.93, alpha: 1)
    }
}

final class OnboardingHeaderView: UIView {
    private let mascotImageView = UIImageView()
    let titleLabel = UILabel()
    let subtitleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        if let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .title1).withDesign(.rounded)?
            .withSymbolicTraits(.traitBold) {
            titleLabel.font = UIFont(descriptor: descriptor, size: 0)
        } else {
            titleLabel.font = .preferredFont(forTextStyle: .title1)
        }
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = 0
        titleLabel.textColor = OnboardingDesign.ink

        subtitleLabel.font = .preferredFont(forTextStyle: .subheadline)
        subtitleLabel.adjustsFontForContentSizeCategory = true
        subtitleLabel.textColor = OnboardingDesign.secondaryInk
        subtitleLabel.numberOfLines = 0

        mascotImageView.contentMode = .scaleAspectFit
        mascotImageView.clipsToBounds = true
        mascotImageView.isHidden = true

        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel, mascotImageView])
        stack.axis = .vertical
        stack.spacing = 8
        addSubview(stack)
        stack.pinEdges(to: self)

        mascotImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mascotImageView.heightAnchor.constraint(lessThanOrEqualToConstant: 140),
        ])
    }

    func setMascotImage(_ image: UIImage?) {
        mascotImageView.image = image
        mascotImageView.isHidden = image == nil
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class OnboardingFooterView: UIView {
    let secondaryButton = UIButton(type: .system)
    let primaryButton = UIButton(type: .system)
    let activityIndicator = UIActivityIndicatorView(style: .medium)

    override init(frame: CGRect) {
        super.init(frame: frame)

        secondaryButton.isHidden = true

        secondaryButton.configuration = .plain()
        primaryButton.configuration = .filled()
        primaryButton.configuration?.cornerStyle = .capsule
        primaryButton.configuration?.buttonSize = .large
        primaryButton.configuration?.baseBackgroundColor = OnboardingDesign.primaryButtonBackground
        primaryButton.configuration?.baseForegroundColor = OnboardingDesign.green
        primaryButton.titleLabel?.font = .preferredFont(forTextStyle: .body)
        primaryButton.configuration?.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 24, bottom: 16, trailing: 24)
        secondaryButton.configuration?.cornerStyle = .capsule
        secondaryButton.configuration?.buttonSize = .large
        secondaryButton.configuration?.baseForegroundColor = .secondaryLabel

        primaryButton.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false

        addSubview(primaryButton)
        addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            primaryButton.topAnchor.constraint(equalTo: topAnchor),
            primaryButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            primaryButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            primaryButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: primaryButton.centerYAnchor),
            activityIndicator.trailingAnchor.constraint(equalTo: primaryButton.trailingAnchor, constant: -20),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class OptionButtonListView<Option: Hashable>: UIView {
    private let stack = UIStackView()
    private var buttons: [Option: UIButton] = [:]
    private let titleProvider: (Option) -> String
    private let subtitleProvider: (Option) -> String?
    private let imageProvider: (Option) -> UIImage?
    private var selectedOption: Option?

    var onSelection: ((Option) -> Void)?

    init(
        options: [Option],
        titleProvider: @escaping (Option) -> String,
        subtitleProvider: @escaping (Option) -> String? = { _ in nil },
        imageProvider: @escaping (Option) -> UIImage? = { _ in nil }
    ) {
        self.titleProvider = titleProvider
        self.subtitleProvider = subtitleProvider
        self.imageProvider = imageProvider
        super.init(frame: .zero)

        stack.axis = .vertical
        stack.spacing = 10
        addSubview(stack)
        stack.pinEdges(to: self)

        for option in options {
            let button = UIButton(type: .system)
            var configuration = UIButton.Configuration.filled()
            configuration.cornerStyle = .large
            configuration.baseBackgroundColor = OnboardingDesign.cardBackground
            configuration.baseForegroundColor = OnboardingDesign.ink
            configuration.title = titleProvider(option)
            configuration.subtitle = subtitleProvider(option)
            configuration.image = imageProvider(option)
            configuration.imagePadding = 14
            configuration.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16)
            configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = UIFont.preferredFont(forTextStyle: .subheadline)
                return outgoing
            }
            configuration.subtitleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = UIFont.preferredFont(forTextStyle: .caption1)
                outgoing.foregroundColor = OnboardingDesign.secondaryInk
                return outgoing
            }
            button.configuration = configuration
            button.contentHorizontalAlignment = .leading
            button.layer.cornerRadius = 12
            button.layer.borderWidth = 1
            button.layer.borderColor = OnboardingDesign.border.resolvedColor(with: traitCollection).cgColor
            button.layer.shadowColor = UIColor.black.cgColor
            button.layer.shadowOpacity = 0.04
            button.layer.shadowRadius = 8
            button.layer.shadowOffset = CGSize(width: 0, height: 3)
            button.addAction(UIAction { [weak self] _ in
                self?.onSelection?(option)
            }, for: .touchUpInside)
            buttons[option] = button
            stack.addArrangedSubview(button)
        }
    }

    func setSelectedOption(_ selectedOption: Option?) {
        self.selectedOption = selectedOption
        updateButtonAppearance()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateButtonAppearance()
    }

    private func updateButtonAppearance() {
        for (option, button) in buttons {
            let isSelected = option == selectedOption
            button.configuration?.baseBackgroundColor = isSelected ? OnboardingDesign.selectedBackground : OnboardingDesign.cardBackground
            button.configuration?.baseForegroundColor = OnboardingDesign.ink
            button.configuration?.image = isSelected ? UIImage(systemName: "checkmark.circle.fill") : imageProvider(option)
            button.layer.borderColor = (isSelected ? OnboardingDesign.green : OnboardingDesign.border)
                .resolvedColor(with: traitCollection)
                .cgColor
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class NumericQuestionInputView: UIView {
    private let valueLabel = UILabel()
    private let unitLabel = UILabel()
    let unitControl = UISegmentedControl()
    private let rulerView = RulerScaleView()
    var onValueChanged: ((Double) -> Void)?
    var onUnitChanged: ((Int) -> Void)?
    private var currentValue = 0.0

    override init(frame: CGRect) {
        super.init(frame: frame)

        if let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .largeTitle).withDesign(.rounded)?
            .withSymbolicTraits(.traitBold) {
            valueLabel.font = UIFont(descriptor: descriptor, size: 0)
        } else {
            valueLabel.font = .systemFont(ofSize: 34, weight: .bold)
        }
        valueLabel.textColor = OnboardingDesign.green
        valueLabel.textAlignment = .right

        unitLabel.font = .preferredFont(forTextStyle: .subheadline)
        unitLabel.textColor = OnboardingDesign.secondaryInk

        let valueStack = UIStackView(arrangedSubviews: [valueLabel, unitLabel])
        valueStack.axis = .horizontal
        valueStack.alignment = .lastBaseline
        valueStack.spacing = 6

        let stack = UIStackView(arrangedSubviews: [unitControl, valueStack, rulerView])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 28
        addSubview(stack)
        stack.pinEdges(to: self)

        unitControl.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.86).isActive = true
        rulerView.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        rulerView.heightAnchor.constraint(equalToConstant: 58).isActive = true

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(didPanRuler(_:)))
        rulerView.addGestureRecognizer(panGesture)
    }

    func setUnitTitles(_ titles: [String]) {
        unitControl.removeAllSegments()
        for (index, title) in titles.enumerated() {
            unitControl.insertSegment(withTitle: title, at: index, animated: false)
        }
        unitControl.addAction(UIAction { [weak self] _ in
            self?.unitDidChange()
        }, for: .valueChanged)
    }

    func configure(
        placeholder: String,
        unitTitles: [String],
        onValueChanged: @escaping (Double) -> Void,
        onUnitChanged: @escaping (Int) -> Void
    ) {
        setUnitTitles(unitTitles)
        self.onValueChanged = onValueChanged
        self.onUnitChanged = onUnitChanged
    }

    func render(value: Double, selectedUnitIndex: Int) {
        currentValue = value
        unitControl.selectedSegmentIndex = selectedUnitIndex
        let rounded = Int(value.rounded())
        valueLabel.text = "\(rounded)"
        unitLabel.text = unitControl.titleForSegment(at: selectedUnitIndex) ?? ""
        rulerView.render(centerValue: rounded)
    }

    private func unitDidChange() {
        onUnitChanged?(unitControl.selectedSegmentIndex)
    }

    @objc private func didPanRuler(_ recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: rulerView)
        guard abs(translation.x) >= 10 else { return }
        recognizer.setTranslation(.zero, in: rulerView)
        currentValue = max(1, currentValue - Double(translation.x / 10).rounded())
        onValueChanged?(currentValue)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class WeightPickerInputView: UIView {
    private let valueLabel = UILabel()
    private let unitLabel = UILabel()
    let unitControl = UISegmentedControl()
    private let rulerView = RulerScaleView()
    var onValueChanged: ((Double) -> Void)?
    var onUnitChanged: ((Int) -> Void)?

    private var selectedUnitIndex = 0
    private var currentValue = 0.0

    override init(frame: CGRect) {
        super.init(frame: frame)

        if let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .largeTitle).withDesign(.rounded)?
            .withSymbolicTraits(.traitBold) {
            valueLabel.font = UIFont(descriptor: descriptor, size: 0)
        } else {
            valueLabel.font = .systemFont(ofSize: 34, weight: .bold)
        }
        valueLabel.textColor = OnboardingDesign.green
        valueLabel.textAlignment = .right
        unitLabel.font = .preferredFont(forTextStyle: .subheadline)
        unitLabel.textColor = OnboardingDesign.secondaryInk

        let valueStack = UIStackView(arrangedSubviews: [valueLabel, unitLabel])
        valueStack.axis = .horizontal
        valueStack.alignment = .lastBaseline
        valueStack.spacing = 6

        let contentStack = UIStackView(arrangedSubviews: [unitControl, valueStack, rulerView])
        contentStack.axis = .vertical
        contentStack.alignment = .center
        contentStack.spacing = 28
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor),
            unitControl.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.86),
            rulerView.widthAnchor.constraint(equalTo: widthAnchor),
            rulerView.heightAnchor.constraint(equalToConstant: 58),
        ])

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(didPanRuler(_:)))
        rulerView.addGestureRecognizer(panGesture)
    }

    func configure(
        unitTitles: [String],
        onValueChanged: @escaping (Double) -> Void,
        onUnitChanged: @escaping (Int) -> Void
    ) {
        unitControl.removeAllSegments()
        for (index, title) in unitTitles.enumerated() {
            unitControl.insertSegment(withTitle: title, at: index, animated: false)
        }
        unitControl.addAction(UIAction { [weak self] _ in
            self?.unitDidChange()
        }, for: .valueChanged)
        self.onValueChanged = onValueChanged
        self.onUnitChanged = onUnitChanged
    }

    func render(value: Double, selectedUnitIndex: Int) {
        let clampedUnitIndex = max(0, min(selectedUnitIndex, WeightUnit.allCases.count - 1))
        self.selectedUnitIndex = clampedUnitIndex
        self.currentValue = value
        unitControl.selectedSegmentIndex = clampedUnitIndex
        let rounded = Int(value.rounded())
        valueLabel.text = "\(rounded)"
        unitLabel.text = unitControl.titleForSegment(at: clampedUnitIndex) ?? ""
        rulerView.render(centerValue: rounded)
    }

    private func unitDidChange() {
        selectedUnitIndex = unitControl.selectedSegmentIndex
        onUnitChanged?(selectedUnitIndex)
    }

    @objc private func didPanRuler(_ recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: rulerView)
        guard abs(translation.x) >= 10 else { return }
        recognizer.setTranslation(.zero, in: rulerView)
        currentValue = max(1, currentValue - Double(translation.x / 10).rounded())
        onValueChanged?(currentValue)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class TextQuestionInputView: UIView {
    let textField = UITextField()
    var onTextChanged: ((String) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)

        textField.borderStyle = .none
        textField.backgroundColor = OnboardingDesign.fieldBackground
        textField.textColor = OnboardingDesign.ink
        textField.tintColor = OnboardingDesign.green
        textField.layer.cornerRadius = 16
        textField.font = .preferredFont(forTextStyle: .title2)
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 50))
        textField.leftView = paddingView
        textField.leftViewMode = .always
        textField.rightView = paddingView
        textField.rightViewMode = .always
        
        textField.addAction(UIAction { [weak self] _ in
            self?.textDidChange()
        }, for: .editingChanged)
        addSubview(textField)
        textField.pinEdges(to: self)
    }

    func setPlaceholder(_ placeholder: String) {
        textField.placeholder = placeholder
    }

    func setText(_ text: String) {
        if textField.text != text {
            textField.text = text
        }
    }

    private func textDidChange() {
        onTextChanged?(textField.text ?? "")
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class DateQuestionInputView: UIView {
    let datePicker = UIDatePicker()
    var onDateChanged: ((Date) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)

        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .compact
        datePicker.maximumDate = .now
        datePicker.backgroundColor = OnboardingDesign.fieldBackground
        datePicker.tintColor = OnboardingDesign.green
        datePicker.layer.cornerRadius = 10
        datePicker.layer.borderWidth = 1
        datePicker.layer.borderColor = OnboardingDesign.border.resolvedColor(with: traitCollection).cgColor
        datePicker.addAction(UIAction { [weak self] _ in
            self?.dateDidChange()
        }, for: .valueChanged)

        addSubview(datePicker)
        datePicker.pinEdges(to: self, insets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0))
        datePicker.heightAnchor.constraint(equalToConstant: 52).isActive = true
    }

    func setDate(_ date: Date) {
        datePicker.date = date
    }

    private func dateDidChange() {
        onDateChanged?(datePicker.date)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class RulerScaleView: UIView {
    private var centerValue = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = true
    }

    func render(centerValue: Int) {
        self.centerValue = centerValue
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        let centerX = rect.midX
        let bottom = rect.maxY - 10
        let spacing: CGFloat = 10

        context.setLineCap(.round)
        for offset in -12...12 {
            let value = centerValue + offset
            let x = centerX + CGFloat(offset) * spacing
            let isMajor = value % 10 == 0
            let isMid = value % 5 == 0
            let isCenter = offset == 0
            let height: CGFloat = isCenter ? 34 : (isMajor ? 26 : (isMid ? 18 : 10))
            let color = isCenter ? OnboardingDesign.green : OnboardingDesign.secondaryInk.withAlphaComponent(isMajor ? 0.75 : 0.38)
            context.setStrokeColor(color.cgColor)
            context.setLineWidth(isCenter ? 2 : 1)
            context.move(to: CGPoint(x: x, y: bottom))
            context.addLine(to: CGPoint(x: x, y: bottom - height))
            context.strokePath()

            guard isMajor else { continue }
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.preferredFont(forTextStyle: .caption2),
                .foregroundColor: isCenter ? OnboardingDesign.green : OnboardingDesign.secondaryInk,
            ]
            let string = "\(value)" as NSString
            let size = string.size(withAttributes: attributes)
            string.draw(
                at: CGPoint(x: x - size.width / 2, y: 0),
                withAttributes: attributes
            )
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class TargetWeightDialView: UIView {
    private let valueLabel = UILabel()
    private let unitLabel = UILabel()
    private let captionLabel = UILabel()
    private let deltaLabel = UILabel()
    private let rulerView = RulerScaleView()
    var onValueChanged: ((Double) -> Void)?
    private var currentValue = 0.0
    private var startingValue = 0.0

    override init(frame: CGRect) {
        super.init(frame: frame)

        captionLabel.text = "Target weight"
        captionLabel.font = .preferredFont(forTextStyle: .caption2)
        captionLabel.textColor = OnboardingDesign.secondaryInk

        if let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .largeTitle).withDesign(.rounded)?
            .withSymbolicTraits(.traitBold) {
            valueLabel.font = UIFont(descriptor: descriptor, size: 0)
        } else {
            valueLabel.font = .systemFont(ofSize: 34, weight: .bold)
        }
        valueLabel.textColor = OnboardingDesign.ink
        valueLabel.textAlignment = .right

        unitLabel.font = .preferredFont(forTextStyle: .subheadline)
        unitLabel.textColor = OnboardingDesign.secondaryInk

        deltaLabel.font = .preferredFont(forTextStyle: .caption1)
        deltaLabel.textColor = OnboardingDesign.green
        deltaLabel.backgroundColor = OnboardingDesign.selectedBackground
        deltaLabel.textAlignment = .center
        deltaLabel.layer.cornerRadius = 14
        deltaLabel.clipsToBounds = true

        let valueStack = UIStackView(arrangedSubviews: [valueLabel, unitLabel])
        valueStack.axis = .horizontal
        valueStack.alignment = .lastBaseline
        valueStack.spacing = 5

        let contentStack = UIStackView(arrangedSubviews: [captionLabel, valueStack, deltaLabel, rulerView])
        contentStack.axis = .vertical
        contentStack.alignment = .center
        contentStack.spacing = 12
        addSubview(contentStack)
        contentStack.pinEdges(to: self)

        deltaLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 56).isActive = true
        deltaLabel.heightAnchor.constraint(equalToConstant: 28).isActive = true
        rulerView.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        rulerView.heightAnchor.constraint(equalToConstant: 58).isActive = true

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(didPanRuler(_:)))
        addGestureRecognizer(panGesture)
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        let diameter = min(rect.width * 0.68, 180)
        let origin = CGPoint(x: rect.midX - diameter / 2, y: 0)
        let circleRect = CGRect(origin: origin, size: CGSize(width: diameter, height: diameter))
        context.setLineWidth(7)
        context.setLineCap(.round)
        context.setStrokeColor(OnboardingDesign.green.withAlphaComponent(0.25).cgColor)
        context.addArc(center: CGPoint(x: circleRect.midX, y: circleRect.midY), radius: diameter / 2, startAngle: .pi * 0.78, endAngle: .pi * 2.22, clockwise: false)
        context.strokePath()
        context.setStrokeColor(OnboardingDesign.green.cgColor)
        context.addArc(center: CGPoint(x: circleRect.midX, y: circleRect.midY), radius: diameter / 2, startAngle: .pi * 0.78, endAngle: .pi * 1.92, clockwise: false)
        context.strokePath()
    }

    func render(value: Double, unitTitle: String, startingValue: Double) {
        currentValue = value
        self.startingValue = startingValue
        let rounded = Int(value.rounded())
        valueLabel.text = "\(rounded)"
        unitLabel.text = unitTitle
        let delta = Int((value - startingValue).rounded())
        deltaLabel.text = delta == 0 ? "0 \(unitTitle)" : "\(delta > 0 ? "+" : "")\(delta) \(unitTitle)"
        rulerView.render(centerValue: rounded)
        setNeedsDisplay()
    }

    @objc private func didPanRuler(_ recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: self)
        guard abs(translation.x) >= 10 else { return }
        recognizer.setTranslation(.zero, in: self)
        currentValue = max(1, currentValue - Double(translation.x / 10).rounded())
        onValueChanged?(currentValue)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class SummaryRowView: UIView {
    private let iconView = UIImageView()
    let titleLabel = UILabel()
    let valueLabel = UILabel()

    init(title: String, systemImageName: String) {
        super.init(frame: .zero)
        iconView.image = UIImage(systemName: systemImageName)
        iconView.tintColor = OnboardingDesign.green
        iconView.contentMode = .scaleAspectFit
        iconView.backgroundColor = OnboardingDesign.iconBackground
        iconView.layer.cornerRadius = 8

        titleLabel.text = title
        titleLabel.font = .preferredFont(forTextStyle: .caption1)
        titleLabel.textColor = OnboardingDesign.ink
        valueLabel.font = .preferredFont(forTextStyle: .caption1)
        valueLabel.textAlignment = .right
        valueLabel.numberOfLines = 0
        valueLabel.textColor = OnboardingDesign.secondaryInk

        let stack = UIStackView(arrangedSubviews: [iconView, titleLabel, UIView(), valueLabel])
        stack.axis = .horizontal
        stack.spacing = 10
        stack.alignment = .center
        addSubview(stack)
        stack.pinEdges(to: self, insets: UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12))

        iconView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class PlanPreviewContentView: UIView {
    private let goalRow = SummaryRowView(title: "Goal", systemImageName: "bag")
    private let calorieRow = SummaryRowView(title: "Daily calorie target", systemImageName: "flame")
    private let targetWeightRow = SummaryRowView(title: "Target weight", systemImageName: "arrow.triangle.2.circlepath")
    private let paceRow = SummaryRowView(title: "Weekly pace", systemImageName: "arrow.triangle.2.circlepath")
    private let activityRow = SummaryRowView(title: "Activity level", systemImageName: "figure.walk")
    private let mealsRow = SummaryRowView(title: "Meals per day", systemImageName: "square.grid.2x2")

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = OnboardingDesign.cardBackground
        layer.cornerRadius = 12
        layer.borderWidth = 1
        layer.borderColor = OnboardingDesign.border.resolvedColor(with: traitCollection).cgColor
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.04
        layer.shadowRadius = 10
        layer.shadowOffset = CGSize(width: 0, height: 4)

        let stack = UIStackView(arrangedSubviews: [goalRow, calorieRow, targetWeightRow, paceRow, activityRow, mealsRow])
        stack.axis = .vertical
        stack.spacing = 0
        addSubview(stack)
        stack.pinEdges(to: self)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.borderColor = OnboardingDesign.border.resolvedColor(with: traitCollection).cgColor
    }

    func render(generatedPlan: NutritionPlan?, draft: OnboardingDraft) {
        goalRow.valueLabel.text = draft.goal.map { String(localized: $0.title) } ?? "Unavailable"
        calorieRow.valueLabel.text = generatedPlan.map { "\($0.dailyCalorieTarget) cal" } ?? "Unavailable"
        targetWeightRow.valueLabel.text = String(localized: draft.targetWeight.formattedDescription)
        if let weeklyChange = generatedPlan?.estimatedWeeklyChange {
            paceRow.valueLabel.text = String(format: "%.1f kg per week", abs(weeklyChange))
        } else {
            paceRow.valueLabel.text = "Unavailable"
        }
        activityRow.valueLabel.text = draft.activityLevel.map { String(localized: $0.title) } ?? "Unavailable"
        mealsRow.valueLabel.text = "3 meals"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
