import Dependencies
import DependenciesMacros
import Foundation

struct ProductPreviewImportProgress: Equatable, Sendable {
    enum Phase: Equatable, Sendable {
        case fetchingManifest
        case importingFile(String)
        case finished
    }

    let phase: Phase
    let completedBytes: Int64
    let totalBytes: Int64?
    let importedProductCount: Int
    let skippedProductCount: Int
}

struct ProductPreviewImportSummary: Equatable, Sendable {
    let importedProductCount: Int
    let skippedProductCount: Int
    let importedFileCount: Int
}

@DependencyClient
struct ProductPreviewClient: Sendable {
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
