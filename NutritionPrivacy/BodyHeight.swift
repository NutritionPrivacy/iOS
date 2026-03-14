import Foundation

struct BodyHeight: Codable, Hashable, Sendable {
    let value: Double
    let unit: HeightUnit

    var centimeters: Double {
        switch unit {
        case .centimeters:
            return value
        case .inches:
            return value * 2.54
        }
    }

    var formattedDescription: LocalizedStringResource {
        switch unit {
        case .centimeters:
            return "\(Int(value.rounded())) cm"
        case .inches:
            let totalInches = Int(value.rounded())
            let feet = totalInches / 12
            let inches = totalInches % 12
            return "\(feet) ft \(inches) in"
        }
    }
}
