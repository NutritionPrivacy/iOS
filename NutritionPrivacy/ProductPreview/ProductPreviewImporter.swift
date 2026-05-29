import Foundation
import SQLiteData

struct ProductPreviewImporter: Sendable {
    let database: any DatabaseWriter
    let importedAt: Date
    let manifestURL: URL
    let assetBaseURL: URL

    func importProductPreviews(
        reportProgress: @Sendable (ProductPreviewImportProgress) -> Void
    ) async throws -> ProductPreviewImportSummary {
        reportProgress(
            ProductPreviewImportProgress(
                phase: .fetchingManifest,
                completedBytes: 0,
                totalBytes: nil,
                importedProductCount: 0,
                skippedProductCount: 0
            )
        )

        let manifest = try await fetchManifest()
        try await database.write { db in
            try #sql("DELETE FROM \"productPreviewImports\"").execute(db)
            try #sql("DELETE FROM \"productPreviews\"").execute(db)
        }

        var importedProductCount = 0
        var skippedProductCount = 0
        var importedFileCount = 0

        for file in manifest.flatMap(\.files) {
            let fileSummary = try await importFile(
                file,
                reportProgress: reportProgress,
                existingImportedCount: importedProductCount,
                existingSkippedCount: skippedProductCount
            )
            importedProductCount += fileSummary.importedProductCount
            skippedProductCount += fileSummary.skippedProductCount
            importedFileCount += 1
        }

        let storedProductCount = try await database.read { db in
            try ProductPreview.fetchCount(db)
        }
        let summary = ProductPreviewImportSummary(
            importedProductCount: storedProductCount,
            skippedProductCount: skippedProductCount,
            importedFileCount: importedFileCount
        )

        try await database.write { db in
            try ProductPreviewImportRecord.insert {
                ProductPreviewImportRecord(
                    id: "nightly",
                    importedAt: importedAt,
                    productCount: summary.importedProductCount,
                    skippedProductCount: summary.skippedProductCount
                )
            }
            .execute(db)
        }

        reportProgress(
            ProductPreviewImportProgress(
                phase: .finished,
                completedBytes: 0,
                totalBytes: nil,
                importedProductCount: storedProductCount,
                skippedProductCount: skippedProductCount
            )
        )

        return summary
    }

    private func fetchManifest() async throws -> [ProductPreviewManifestEntry] {
        let data: Data
        if manifestURL.isFileURL {
            data = try Data(contentsOf: manifestURL)
        } else {
            data = try await URLSession.shared.data(from: manifestURL).0
        }
        return try JSONDecoder().decode([ProductPreviewManifestEntry].self, from: data)
    }

    private func importFile(
        _ file: ProductPreviewManifestFile,
        reportProgress: @Sendable (ProductPreviewImportProgress) -> Void,
        existingImportedCount: Int,
        existingSkippedCount: Int
    ) async throws -> ProductPreviewImportSummary {
        let fileURL = assetBaseURL.appending(path: file.name)
        if fileURL.isFileURL {
            let data = try Data(contentsOf: fileURL)
            return try await importLocalFileData(
                data,
                file: file,
                reportProgress: reportProgress,
                existingImportedCount: existingImportedCount,
                existingSkippedCount: existingSkippedCount
            )
        }

        let (bytes, response) = try await URLSession.shared.bytes(from: fileURL)
        let totalBytes = (response as? HTTPURLResponse)?.expectedContentLength
        var completedBytes: Int64 = 0
        var batch: [ProductPreview] = []
        var importedProductCount = 0
        var skippedProductCount = 0
        var nextProgressByteCount: Int64 = 512 * 1024

        reportProgress(
            ProductPreviewImportProgress(
                phase: .importingFile(file.name),
                completedBytes: 0,
                totalBytes: totalBytes,
                importedProductCount: existingImportedCount,
                skippedProductCount: existingSkippedCount
            )
        )

        for try await line in bytes.lines {
            completedBytes += Int64(line.utf8.count + 1)
            guard !line.isEmpty else { continue }

            do {
                let preview = try decodePreview(line, file: file)
                batch.append(preview)
                importedProductCount += 1
            } catch {
                skippedProductCount += 1
            }

            if batch.count >= 500 {
                try await insert(batch)
                batch.removeAll(keepingCapacity: true)
            }

            if completedBytes >= nextProgressByteCount {
                reportProgress(
                    ProductPreviewImportProgress(
                        phase: .importingFile(file.name),
                        completedBytes: completedBytes,
                        totalBytes: totalBytes,
                        importedProductCount: existingImportedCount + importedProductCount,
                        skippedProductCount: existingSkippedCount + skippedProductCount
                    )
                )
                nextProgressByteCount = completedBytes + 512 * 1024
            }
        }

        try await insert(batch)
        reportProgress(
            ProductPreviewImportProgress(
                phase: .importingFile(file.name),
                completedBytes: completedBytes,
                totalBytes: totalBytes,
                importedProductCount: existingImportedCount + importedProductCount,
                skippedProductCount: existingSkippedCount + skippedProductCount
            )
        )

        return ProductPreviewImportSummary(
            importedProductCount: importedProductCount,
            skippedProductCount: skippedProductCount,
            importedFileCount: 1
        )
    }

    private func importLocalFileData(
        _ data: Data,
        file: ProductPreviewManifestFile,
        reportProgress: @Sendable (ProductPreviewImportProgress) -> Void,
        existingImportedCount: Int,
        existingSkippedCount: Int
    ) async throws -> ProductPreviewImportSummary {
        let lines = String(decoding: data, as: UTF8.self).split(separator: "\n", omittingEmptySubsequences: true)
        var batch: [ProductPreview] = []
        var importedProductCount = 0
        var skippedProductCount = 0

        reportProgress(
            ProductPreviewImportProgress(
                phase: .importingFile(file.name),
                completedBytes: 0,
                totalBytes: Int64(data.count),
                importedProductCount: existingImportedCount,
                skippedProductCount: existingSkippedCount
            )
        )

        for line in lines {
            do {
                let preview = try decodePreview(String(line), file: file)
                batch.append(preview)
                importedProductCount += 1
            } catch {
                skippedProductCount += 1
            }
        }

        try await insert(batch)
        reportProgress(
            ProductPreviewImportProgress(
                phase: .importingFile(file.name),
                completedBytes: Int64(data.count),
                totalBytes: Int64(data.count),
                importedProductCount: existingImportedCount + importedProductCount,
                skippedProductCount: existingSkippedCount + skippedProductCount
            )
        )

        return ProductPreviewImportSummary(
            importedProductCount: importedProductCount,
            skippedProductCount: skippedProductCount,
            importedFileCount: 1
        )
    }

    private func decodePreview(_ line: String, file: ProductPreviewManifestFile) throws -> ProductPreview {
        let dumpRecord = try JSONDecoder().decode(ProductPreviewDumpRecord.self, from: Data(line.utf8))
        return ProductPreview(
            barcode: dumpRecord.barcode,
            language: file.language,
            name: dumpRecord.name,
            brand: dumpRecord.brand,
            energy: dumpRecord.energy,
            measurement: dumpRecord.measurement,
            source: dumpRecord.source,
            importedAt: importedAt
        )
    }

    private func insert(_ previews: [ProductPreview]) async throws {
        guard !previews.isEmpty else { return }

        try await database.write { db in
            for preview in previews {
                try ProductPreview.insert {
                    preview
                } onConflictDoUpdate: { updates, excluded in
                    updates.barcode = excluded.barcode
                    updates.language = excluded.language
                    updates.name = excluded.name
                    updates.brand = excluded.brand
                    updates.energy = excluded.energy
                    updates.measurement = excluded.measurement
                    updates.source = excluded.source
                    updates.importedAt = excluded.importedAt
                }
                .execute(db)
            }
        }
    }
}

private struct ProductPreviewManifestEntry: Decodable, Sendable {
    let language: ProductPreviewLanguage
    let files: [ProductPreviewManifestFile]

    private enum CodingKeys: CodingKey {
        case language
        case files
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let language = try container.decode(ProductPreviewLanguage.self, forKey: .language)
        let decodedFiles = try container.decode([ProductPreviewManifestFile].self, forKey: .files)

        self.language = language
        self.files = decodedFiles.map { file in
            var file = file
            file.language = language
            return file
        }
    }
}

private struct ProductPreviewManifestFile: Decodable, Sendable {
    let name: String
    let sha256: String
    let source: ProductPreviewSource
    fileprivate var language: ProductPreviewLanguage = .english

    private enum CodingKeys: CodingKey {
        case name
        case sha256
        case source
    }
}

private struct ProductPreviewDumpRecord: Decodable, Sendable {
    let name: String
    let brand: String?
    let barcode: String
    let energy: Int
    let measurement: ProductMeasurement
    let source: ProductPreviewSource
}
