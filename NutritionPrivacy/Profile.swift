import Foundation
import SQLiteData

@Table("profiles")
struct Profile: Identifiable, Hashable, Sendable {
    let id: UUID
    let name: String
    let sexForCalculation: SexForCalculation?
    let dateOfBirth: Date
    let heightValue: Double
    let heightUnit: HeightUnit
}
