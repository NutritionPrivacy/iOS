import Observation
import SQLiteData

@MainActor
@Observable
final class AppState {
    var isSetup: Bool {
        profile != nil
    }

    @ObservationIgnored
    @FetchOne
    var profile: Profile?    
}
