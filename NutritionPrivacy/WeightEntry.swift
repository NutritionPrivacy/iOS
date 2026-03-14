import Foundation
import SQLiteData

@Table("weightEntries")
struct WeightEntry: Identifiable, Hashable, Sendable {
    let id: UUID
    let profileID: UUID
    let weightValue: Double
    let weightUnit: WeightUnit
    let recordedAt: Date
}
