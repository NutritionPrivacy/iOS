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
    let importedAt: Date

    init(
        barcode: String,
        language: ProductPreviewLanguage,
        name: String,
        brand: String?,
        energy: Int,
        measurement: ProductMeasurement,
        source: ProductPreviewSource,
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

@Table("productPreviewImports")
struct ProductPreviewImportRecord: Identifiable, Hashable, Sendable {
    let id: String
    let manifestDigest: String?
    let importedAt: Date
    let productCount: Int
    let skippedProductCount: Int
}
