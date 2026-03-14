import Foundation
import SQLiteData

@Table("appPreferences")
struct AppPreferences: Identifiable, Hashable, Sendable {
    let id: UUID
    let weeklyCheckInDay: WeeklyCheckInDay
    let completedAt: Date
}
