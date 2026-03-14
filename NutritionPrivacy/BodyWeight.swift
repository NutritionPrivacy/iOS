import Foundation

struct BodyWeight: Codable, Hashable, Sendable {
    let value: Double
    let unit: WeightUnit

    var kilograms: Double {
        switch unit {
        case .kilograms:
            return value
        case .pounds:
            return value * 0.45359237
        }
    }

    func converted(to targetUnit: WeightUnit) -> BodyWeight {
        switch targetUnit {
        case .kilograms:
            return BodyWeight(value: kilograms, unit: .kilograms)
        case .pounds:
            return BodyWeight(value: kilograms / 0.45359237, unit: .pounds)
        }
    }

    var formattedDescription: LocalizedStringResource {
        switch unit {
        case .kilograms:
            return "\(String(format: "%.1f", value)) kg"
        case .pounds:
            return "\(String(format: "%.1f", value)) lb"
        }
    }
}
