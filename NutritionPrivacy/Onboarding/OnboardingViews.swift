import UIKit

final class OnboardingHeaderView: UIView {
    private let mascotImageView = UIImageView()
    let titleLabel = UILabel()
    let subtitleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        if let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .largeTitle).withDesign(.rounded)?
            .withSymbolicTraits(.traitBold) {
            titleLabel.font = UIFont(descriptor: descriptor, size: 0)
        } else {
            titleLabel.font = .preferredFont(forTextStyle: .largeTitle)
        }
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = 0

        subtitleLabel.font = .preferredFont(forTextStyle: .body)
        subtitleLabel.adjustsFontForContentSizeCategory = true
        subtitleLabel.textColor = .secondaryLabel
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

    var onSelection: ((Option) -> Void)?

    init(options: [Option], titleProvider: @escaping (Option) -> String) {
        self.titleProvider = titleProvider
        super.init(frame: .zero)

        stack.axis = .vertical
        stack.spacing = 12
        addSubview(stack)
        stack.pinEdges(to: self)

        for option in options {
            let button = UIButton(type: .system)
            button.configuration = .filled()
            button.configuration?.cornerStyle = .large
            button.configuration?.baseBackgroundColor = .secondarySystemBackground
            button.configuration?.baseForegroundColor = .label
            button.configuration?.title = titleProvider(option)
            button.configuration?.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = UIFont.preferredFont(forTextStyle: .headline)
                return outgoing
            }
            button.configuration?.contentInsets = NSDirectionalEdgeInsets(top: 18, leading: 20, bottom: 18, trailing: 20)
            button.contentHorizontalAlignment = .center
            button.addAction(UIAction { [weak self] _ in
                self?.onSelection?(option)
            }, for: .touchUpInside)
            buttons[option] = button
            stack.addArrangedSubview(button)
        }
    }

    func setSelectedOption(_ selectedOption: Option?) {
        for (option, button) in buttons {
            let isSelected = option == selectedOption
            button.configuration?.baseBackgroundColor = isSelected ? .systemBlue : .secondarySystemBackground
            button.configuration?.baseForegroundColor = isSelected ? .white : .label
            button.configuration?.image = nil
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class NumericQuestionInputView: UIView, UITextFieldDelegate {
    let textField = UITextField()
    let unitControl = UISegmentedControl()
    var onValueChanged: ((Double) -> Void)?
    var onUnitChanged: ((Int) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)

        textField.borderStyle = .none
        textField.backgroundColor = .secondarySystemBackground
        textField.layer.cornerRadius = 16
        if let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .largeTitle).withDesign(.rounded)?
            .withSymbolicTraits(.traitBold) {
            textField.font = UIFont(descriptor: descriptor, size: 0)
        } else {
            textField.font = .systemFont(ofSize: 34, weight: .bold)
        }
        textField.textAlignment = .center
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 60))
        textField.leftView = paddingView
        textField.leftViewMode = .always
        textField.rightView = paddingView
        textField.rightViewMode = .always
        
        textField.keyboardType = .decimalPad
        textField.delegate = self
        textField.addAction(UIAction { [weak self] _ in
            self?.textDidChange()
        }, for: .editingChanged)

        let stack = UIStackView(arrangedSubviews: [textField, unitControl])
        stack.axis = .vertical
        stack.spacing = 12
        addSubview(stack)
        stack.pinEdges(to: self)
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
        textField.placeholder = placeholder
        setUnitTitles(unitTitles)
        self.onValueChanged = onValueChanged
        self.onUnitChanged = onUnitChanged
    }

    func render(value: Double, selectedUnitIndex: Int) {
        textField.text = String(format: "%.1f", value)
        unitControl.selectedSegmentIndex = selectedUnitIndex
    }

    private func textDidChange() {
        let normalized = textField.text?.replacingOccurrences(of: ",", with: ".") ?? ""
        if let value = Double(normalized) {
            onValueChanged?(value)
        }
    }

    private func unitDidChange() {
        onUnitChanged?(unitControl.selectedSegmentIndex)
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let allowed = CharacterSet(charactersIn: "0123456789.,")
        return string.unicodeScalars.allSatisfy(allowed.contains)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class WeightPickerInputView: UIView, UIPickerViewDataSource, UIPickerViewDelegate {
    let pickerView = UIPickerView()
    let unitControl = UISegmentedControl()
    var onValueChanged: ((Double) -> Void)?
    var onUnitChanged: ((Int) -> Void)?

    private var selectedUnitIndex = 0
    private let kilogramValues = Array(stride(from: 30.0, through: 250.0, by: 1.0))
    private let poundValues = Array(stride(from: 66.0, through: 550.0, by: 1.0))

    override init(frame: CGRect) {
        super.init(frame: frame)

        pickerView.dataSource = self
        pickerView.delegate = self

        let contentStack = UIStackView(arrangedSubviews: [pickerView, unitControl])
        contentStack.axis = .vertical
        contentStack.spacing = 12
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
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
        let didChangeUnit = self.selectedUnitIndex != clampedUnitIndex
        self.selectedUnitIndex = clampedUnitIndex
        unitControl.selectedSegmentIndex = clampedUnitIndex
        if didChangeUnit {
            pickerView.reloadAllComponents()
        }

        let values = valuesForSelectedUnit()
        let targetRow = nearestRow(to: value, in: values)
        if pickerView.selectedRow(inComponent: 0) != targetRow {
            pickerView.selectRow(targetRow, inComponent: 0, animated: false)
        }
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        valuesForSelectedUnit().count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let values = valuesForSelectedUnit()
        guard let value = values[safe: row] else { return nil }
        let unitTitle = WeightUnit.allCases[safe: selectedUnitIndex].map { String(localized: $0.title) } ?? ""
        return "\(Int(value)) \(unitTitle)"
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let values = valuesForSelectedUnit()
        guard let value = values[safe: row] else { return }
        onValueChanged?(value)
    }

    private func unitDidChange() {
        selectedUnitIndex = unitControl.selectedSegmentIndex
        pickerView.reloadAllComponents()
        onUnitChanged?(selectedUnitIndex)
    }

    private func valuesForSelectedUnit() -> [Double] {
        let unit = WeightUnit.allCases[safe: selectedUnitIndex] ?? .kilograms
        switch unit {
        case .kilograms:
            return kilogramValues
        case .pounds:
            return poundValues
        }
    }

    private func nearestRow(to value: Double, in values: [Double]) -> Int {
        guard let firstValue = values.first, let lastValue = values.last else { return 0 }
        let clampedValue = min(max(value, firstValue), lastValue)
        return values.enumerated().min { lhs, rhs in
            abs(lhs.element - clampedValue) < abs(rhs.element - clampedValue)
        }?.offset ?? 0
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
        textField.backgroundColor = .secondarySystemBackground
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
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.maximumDate = .now
        datePicker.addAction(UIAction { [weak self] _ in
            self?.dateDidChange()
        }, for: .valueChanged)

        addSubview(datePicker)
        datePicker.pinEdges(to: self)
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

final class SummaryRowView: UIView {
    let titleLabel = UILabel()
    let valueLabel = UILabel()

    init(title: String) {
        super.init(frame: .zero)
        titleLabel.text = title
        titleLabel.font = .preferredFont(forTextStyle: .body)
        valueLabel.font = .preferredFont(forTextStyle: .body)
        valueLabel.textAlignment = .right
        valueLabel.numberOfLines = 0
        valueLabel.textColor = .secondaryLabel

        let stack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .top
        addSubview(stack)
        stack.pinEdges(to: self)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class PlanPreviewContentView: UIView {
    private let calorieRow = SummaryRowView(title: "Calories")
    private let macrosRow = SummaryRowView(title: "Macros")
    private let weightRow = SummaryRowView(title: "Start / target")
    private let changeRow = SummaryRowView(title: "Estimated change")

    override init(frame: CGRect) {
        super.init(frame: frame)

        let stack = UIStackView(arrangedSubviews: [calorieRow, macrosRow, weightRow, changeRow])
        stack.axis = .vertical
        stack.spacing = 12
        addSubview(stack)
        stack.pinEdges(to: self)
    }

    func render(generatedPlan: NutritionPlan?, draft: OnboardingDraft) {
        calorieRow.valueLabel.text = generatedPlan.map { String(localized: $0.calorieSummary) } ?? "Unavailable"
        macrosRow.valueLabel.text = generatedPlan.map { String(localized: $0.macroSummary) } ?? "Unavailable"
        weightRow.valueLabel.text = "\(String(localized: draft.currentWeight.formattedDescription)) -> \(String(localized: draft.targetWeight.formattedDescription))"
        if let weeklyChange = generatedPlan?.estimatedWeeklyChange {
            changeRow.valueLabel.text = String(format: "%.2f kg/week", weeklyChange)
        } else {
            changeRow.valueLabel.text = "Unavailable"
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
