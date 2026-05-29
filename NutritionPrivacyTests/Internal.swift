import Testing
import Foundation
import SQLiteData
@testable import NutritionPrivacy
import DependenciesTestSupport

@Suite(
  .dependency(\.continuousClock, ImmediateClock()),
  .dependency(\.date.now, Date(timeIntervalSince1970: 1_234_567_890)),
  .dependency(\.uuid, .incrementing),
  .dependencies {
    try $0.bootstrapDatabase()
  }
)
struct BaseTestSuite {}
