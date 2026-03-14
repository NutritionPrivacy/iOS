import Foundation
import SQLiteData

enum NutritionGoal: String, CaseIterable, Codable, Hashable, Sendable, QueryBindable {
    case loseWeight
    case maintainWeight
    case gainWeight

    var title: LocalizedStringResource {
        switch self {
        case .loseWeight:
            return "Lose weight"
        case .maintainWeight:
            return "Maintain weight"
        case .gainWeight:
            return "Gain weight"
        }
    }
}

enum GoalPace: String, CaseIterable, Codable, Hashable, Sendable, QueryBindable {
    case conservative
    case moderate
    case aggressive

    var title: LocalizedStringResource {
        switch self {
        case .conservative:
            return "Conservative"
        case .moderate:
            return "Moderate"
        case .aggressive:
            return "Aggressive"
        }
    }
}

enum SexForCalculation: String, CaseIterable, Codable, Hashable, Sendable, QueryBindable {
    case female
    case male

    var title: LocalizedStringResource {
        switch self {
        case .female:
            return "Female"
        case .male:
            return "Male"
        }
    }
}

enum ActivityLevel: String, CaseIterable, Codable, Hashable, Sendable, QueryBindable {
    case sedentary
    case lightlyActive
    case moderatelyActive
    case veryActive
    case extremelyActive

    var title: LocalizedStringResource {
        switch self {
        case .sedentary:
            return "Mostly sedentary"
        case .lightlyActive:
            return "Lightly active"
        case .moderatelyActive:
            return "Moderately active"
        case .veryActive:
            return "Very active"
        case .extremelyActive:
            return "Extremely active"
        }
    }

    var activityFactor: Double {
        switch self {
        case .sedentary:
            return 1.2
        case .lightlyActive:
            return 1.35
        case .moderatelyActive:
            return 1.5
        case .veryActive:
            return 1.65
        case .extremelyActive:
            return 1.8
        }
    }
}

enum ExerciseFrequency: String, CaseIterable, Codable, Hashable, Sendable, QueryBindable {
    case rarely
    case oneToTwo
    case threeToFour
    case fivePlus

    var title: LocalizedStringResource {
        switch self {
        case .rarely:
            return "Rarely"
        case .oneToTwo:
            return "1-2 times/week"
        case .threeToFour:
            return "3-4 times/week"
        case .fivePlus:
            return "5+ times/week"
        }
    }

    var factorAdjustment: Double {
        switch self {
        case .rarely:
            return 0
        case .oneToTwo:
            return 0.05
        case .threeToFour:
            return 0.1
        case .fivePlus:
            return 0.15
        }
    }
}

enum ProteinPreference: String, CaseIterable, Codable, Hashable, Sendable, QueryBindable {
    case balanced
    case higherProtein
    case highestProtein

    var title: LocalizedStringResource {
        switch self {
        case .balanced:
            return "Balanced"
        case .higherProtein:
            return "Higher protein"
        case .highestProtein:
            return "Highest protein"
        }
    }

    var gramsPerKilogram: Double {
        switch self {
        case .balanced:
            return 1.6
        case .higherProtein:
            return 2.0
        case .highestProtein:
            return 2.3
        }
    }
}

enum WeeklyCheckInDay: String, CaseIterable, Codable, Hashable, Sendable, QueryBindable {
    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday
    case sunday

    var title: LocalizedStringResource {
        switch self {
        case .monday:
            return "Monday"
        case .tuesday:
            return "Tuesday"
        case .wednesday:
            return "Wednesday"
        case .thursday:
            return "Thursday"
        case .friday:
            return "Friday"
        case .saturday:
            return "Saturday"
        case .sunday:
            return "Sunday"
        }
    }
}

enum HeightUnit: String, CaseIterable, Codable, Hashable, Sendable, QueryBindable {
    case centimeters
    case inches

    var title: LocalizedStringResource {
        switch self {
        case .centimeters:
            return "cm"
        case .inches:
            return "ft/in"
        }
    }
}

enum WeightUnit: String, CaseIterable, Codable, Hashable, Sendable, QueryBindable {
    case kilograms
    case pounds

    var title: LocalizedStringResource {
        switch self {
        case .kilograms:
            return "kg"
        case .pounds:
            return "lb"
        }
    }
}
