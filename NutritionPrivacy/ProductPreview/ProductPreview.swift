import Foundation
import SQLiteData

enum ProductPreviewLanguage: String, Codable, Hashable, Sendable, QueryBindable {
    case english
    case german
}

enum ProductPreviewSource: Int, Codable, Hashable, Sendable, QueryBindable {
    case openFoodFacts
    case nutritionPrivacy
}

enum ProductMeasurement: Int, Codable, Hashable, Sendable, QueryBindable {
    case volume
    case weight
    case unknown
}

/// Search-ready product metadata imported from the preview dumps.
///
/// Preview rows intentionally contain only the fields needed for lightweight
/// product lookup.
@Table("productPreviews")
struct ProductPreview: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let barcode: String
    let language: ProductPreviewLanguage
    let name: String
    let brand: String?
    let energy: Int
    let measurement: ProductMeasurement
    let source: ProductPreviewSource
    /// Manifest dump file that produced this row. Used to replace only changed files.
    let fileName: String
    let importedAt: Date

    init(
        barcode: String,
        language: ProductPreviewLanguage,
        name: String,
        brand: String?,
        energy: Int,
        measurement: ProductMeasurement,
        source: ProductPreviewSource,
        fileName: String,
        importedAt: Date
    ) {
        self.id = Self.makeID(barcode: barcode, language: language, source: source)
        self.barcode = barcode
        self.language = language
        self.name = name
        self.brand = brand
        self.energy = energy
        self.measurement = measurement
        self.source = source
        self.fileName = fileName
        self.importedAt = importedAt
    }

    static func makeID(
        barcode: String,
        language: ProductPreviewLanguage,
        source: ProductPreviewSource
    ) -> String {
        "\(language.rawValue):\(source.rawValue):\(barcode)"
    }
}

/// Aggregate metadata for the most recent product preview refresh.
@Table("productPreviewImports")
struct ProductPreviewImportRecord: Identifiable, Hashable, Sendable {
    let id: String
    /// Digest of the current manifest file identities and checksums.
    let manifestDigest: String?
    let importedAt: Date
    let productCount: Int
    let skippedProductCount: Int
}

/// Per-dump cache metadata from `overview.json`.
///
/// The importer compares these stored checksums to the manifest before deciding
/// whether a dump file needs to be downloaded.
@Table("productPreviewFileImports")
struct ProductPreviewFileImportRecord: Identifiable, Hashable, Sendable {
    let id: String
    let fileName: String
    let language: ProductPreviewLanguage
    let source: ProductPreviewSource
    let sha256: String
    let importedAt: Date
    let productCount: Int
    let skippedProductCount: Int

    init(
        fileName: String,
        language: ProductPreviewLanguage,
        source: ProductPreviewSource,
        sha256: String,
        importedAt: Date,
        productCount: Int,
        skippedProductCount: Int
    ) {
        self.id = Self.makeID(fileName: fileName, language: language, source: source)
        self.fileName = fileName
        self.language = language
        self.source = source
        self.sha256 = sha256
        self.importedAt = importedAt
        self.productCount = productCount
        self.skippedProductCount = skippedProductCount
    }

    static func makeID(
        fileName: String,
        language: ProductPreviewLanguage,
        source: ProductPreviewSource
    ) -> String {
        "\(language.rawValue):\(source.rawValue):\(fileName)"
    }
}
