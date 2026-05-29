import Dependencies
import DependenciesMacros
import Foundation

/// Progress emitted while refreshing the local product preview cache.
struct ProductPreviewImportProgress: Equatable, Sendable {
    enum Phase: Equatable, Sendable {
        /// The lightweight nightly manifest (`overview.json`) is being loaded.
        case fetchingManifest
        /// A changed preview dump is being downloaded, verified, and decoded.
        case importingFile(String)
        /// The import finished, possibly without downloading any dump files.
        case finished
    }

    let phase: Phase
    let completedBytes: Int64
    let totalBytes: Int64?
    let importedProductCount: Int
    let skippedProductCount: Int
}

/// Aggregate result of one product preview refresh attempt.
struct ProductPreviewImportSummary: Equatable, Sendable {
    /// Number of preview rows currently available in the cache after the import.
    let importedProductCount: Int
    /// Number of malformed rows skipped while decoding changed files.
    let skippedProductCount: Int
    /// Number of dump files actually downloaded and imported.
    let importedFileCount: Int
}

/// Dependency boundary for the product preview feature.
///
/// Product previews are compact product records from the nightly
/// `NutritionPrivacy/product-previews` release. The client keeps those records
/// available locally so UI flows can search or resolve basic product metadata
/// without depending on a full product-detail fetch.
///
/// The live implementation performs a best-effort cache refresh from the
/// release manifest and persists decoded rows in SQLite.
@DependencyClient
struct ProductPreviewClient: Sendable {
    /// Refreshes the local preview cache and reports coarse import progress.
    ///
    /// Callers should treat this as a background maintenance task. Existing
    /// cached previews remain usable when individual dump files cannot be
    /// refreshed.
    var importProductPreviews: @Sendable (
        _ reportProgress: @Sendable (ProductPreviewImportProgress) -> Void
    ) async throws -> ProductPreviewImportSummary
}

extension ProductPreviewClient: DependencyKey {
    static let testValue = ProductPreviewClient()
    static let liveValue = Self.live(
        manifestURL: URL(string: "https://github.com/NutritionPrivacy/product-previews/releases/download/nightly/overview.json")!,
        assetBaseURL: URL(string: "https://github.com/NutritionPrivacy/product-previews/releases/download/nightly/")!
    )

    static func live(manifestURL: URL, assetBaseURL: URL) -> Self {
        Self(
            importProductPreviews: { reportProgress in
                @Dependency(\.defaultDatabase) var database
                @Dependency(\.date.now) var now

                let importer = ProductPreviewImporter(
                    database: database,
                    importedAt: now,
                    manifestURL: manifestURL,
                    assetBaseURL: assetBaseURL
                )
                return try await importer.importProductPreviews(reportProgress: reportProgress)
            }
        )
    }
}

extension DependencyValues {
    var productPreviewClient: ProductPreviewClient {
        get { self[ProductPreviewClient.self] }
        set { self[ProductPreviewClient.self] = newValue }
    }
}
