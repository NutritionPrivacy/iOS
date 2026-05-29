import CryptoKit
import Foundation
import SQLiteData

/// Imports product preview release assets into the local SQLite cache.
///
/// The importer always starts with the lightweight `overview.json` manifest.
/// It compares the manifest SHA-256 values with `productPreviewFileImports`,
/// downloads only changed dump files, verifies each downloaded file, and then
/// replaces only the preview rows produced by that file. This keeps app startup
/// cheap after the first import and avoids wiping valid cached data when one
/// dump update is corrupt or temporarily unavailable.
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
        let files = manifest.entries.flatMap(\.files)
        let cachedFileImports = try await cachedFileImportRecords()

        // Remove rows for dump files no longer advertised by the nightly manifest.
        try await removeStaleFileImports(
            cachedFileImports.values,
            currentFileIDs: Set(files.map(\.id))
        )

        // Only files with new or changed SHA-256 values need to be downloaded.
        let filesToImport = files.filter { file in
            cachedFileImports[file.id]?.sha256 != file.normalizedSHA256
        }

        if filesToImport.isEmpty, let cachedSummary = try await cachedSummary(for: files, cachedFileImports: cachedFileImports) {
            reportProgress(
                ProductPreviewImportProgress(
                    phase: .finished,
                    completedBytes: 0,
                    totalBytes: nil,
                    importedProductCount: cachedSummary.importedProductCount,
                    skippedProductCount: cachedSummary.skippedProductCount
                )
            )
            return cachedSummary
        }

        var skippedProductCount = files
            .filter { file in !filesToImport.contains { $0.id == file.id } }
            .reduce(0) { count, file in
                count + (cachedFileImports[file.id]?.skippedProductCount ?? 0)
            }
        var importedFileCount = 0

        for file in filesToImport {
            do {
                let fileSummary = try await importFile(
                    file,
                    reportProgress: reportProgress,
                    existingImportedCount: 0,
                    existingSkippedCount: skippedProductCount
                )
                skippedProductCount += fileSummary.skippedProductCount
                importedFileCount += 1
                try await saveFileImportRecord(file, summary: fileSummary)
            } catch ProductPreviewImportError.checksumMismatch {
                // Keep the previous cache for this file.
                continue
            }
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
                    manifestDigest: manifest.digest,
                    importedAt: importedAt,
                    productCount: summary.importedProductCount,
                    skippedProductCount: summary.skippedProductCount
                )
            } onConflictDoUpdate: { updates, excluded in
                updates.manifestDigest = excluded.manifestDigest
                updates.importedAt = excluded.importedAt
                updates.productCount = excluded.productCount
                updates.skippedProductCount = excluded.skippedProductCount
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

    private func fetchManifest() async throws -> ProductPreviewManifest {
        let data: Data
        if manifestURL.isFileURL {
            data = try Data(contentsOf: manifestURL)
        } else {
            data = try await URLSession.shared.data(from: manifestURL).0
        }
        let entries = try JSONDecoder().decode([ProductPreviewManifestEntry].self, from: data)
        return ProductPreviewManifest(entries: entries)
    }

    private func cachedFileImportRecords() async throws -> [String: ProductPreviewFileImportRecord] {
        try await database.read { db in
            Dictionary(
                uniqueKeysWithValues: try ProductPreviewFileImportRecord.all.fetchAll(db)
                    .map { ($0.id, $0) }
            )
        }
    }

    private func cachedSummary(
        for files: [ProductPreviewManifestFile],
        cachedFileImports: [String: ProductPreviewFileImportRecord]
    ) async throws -> ProductPreviewImportSummary? {
        guard files.allSatisfy({ cachedFileImports[$0.id] != nil }) else { return nil }

        return try await database.read { db in
            let storedProductCount = try ProductPreview.fetchCount(db)
            guard storedProductCount > 0 else { return nil }

            return ProductPreviewImportSummary(
                importedProductCount: storedProductCount,
                skippedProductCount: files.reduce(0) { count, file in
                    count + (cachedFileImports[file.id]?.skippedProductCount ?? 0)
                },
                importedFileCount: 0
            )
        }
    }

    private func removeStaleFileImports(
        _ cachedFileImports: some Sequence<ProductPreviewFileImportRecord>,
        currentFileIDs: Set<String>
    ) async throws {
        try await database.write { db in
            for record in cachedFileImports where !currentFileIDs.contains(record.id) {
                try ProductPreview
                    .where {
                        $0.fileName.eq(record.fileName)
                            && $0.language.eq(record.language)
                            && $0.source.eq(record.source)
                    }
                    .delete()
                    .execute(db)
                try ProductPreviewFileImportRecord.find(record.id).delete().execute(db)
            }
        }
    }

    fileprivate static func digest(_ data: Data) -> String {
        SHA256.hash(data: data)
            .map { String(format: "%02x", $0) }
            .joined()
    }

    private func importFile(
        _ file: ProductPreviewManifestFile,
        reportProgress: @Sendable (ProductPreviewImportProgress) -> Void,
        existingImportedCount: Int,
        existingSkippedCount: Int
    ) async throws -> ProductPreviewImportSummary {
        let fileURL = assetBaseURL.appending(path: file.name)
        let data: Data
        if fileURL.isFileURL {
            data = try Data(contentsOf: fileURL)
        } else {
            data = try await URLSession.shared.data(from: fileURL).0
        }

        guard Self.digest(data) == file.normalizedSHA256 else {
            throw ProductPreviewImportError.checksumMismatch(fileName: file.name)
        }

        // Verify before deleting so a corrupt download never removes good cached rows.
        try await removeCachedPreviews(for: file)
        return try await importFileData(
            data,
            file: file,
            reportProgress: reportProgress,
            existingImportedCount: existingImportedCount,
            existingSkippedCount: existingSkippedCount
        )
    }

    private func removeCachedPreviews(for file: ProductPreviewManifestFile) async throws {
        try await database.write { db in
            try ProductPreview
                .where {
                    $0.fileName.eq(file.name)
                        && $0.language.eq(file.language)
                        && $0.source.eq(file.source)
                }
                .delete()
                .execute(db)
        }
    }

    private func importFileData(
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
            fileName: file.name,
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
                    updates.fileName = excluded.fileName
                    updates.importedAt = excluded.importedAt
                }
                .execute(db)
            }
        }
    }

    private func saveFileImportRecord(
        _ file: ProductPreviewManifestFile,
        summary: ProductPreviewImportSummary
    ) async throws {
        try await database.write { db in
            try ProductPreviewFileImportRecord.insert {
                ProductPreviewFileImportRecord(
                    fileName: file.name,
                    language: file.language,
                    source: file.source,
                    sha256: file.normalizedSHA256,
                    importedAt: importedAt,
                    productCount: summary.importedProductCount,
                    skippedProductCount: summary.skippedProductCount
                )
            } onConflictDoUpdate: { updates, excluded in
                updates.fileName = excluded.fileName
                updates.language = excluded.language
                updates.source = excluded.source
                updates.sha256 = excluded.sha256
                updates.importedAt = excluded.importedAt
                updates.productCount = excluded.productCount
                updates.skippedProductCount = excluded.skippedProductCount
            }
            .execute(db)
        }
    }
}

/// Decoded `overview.json` plus a stable digest for aggregate import metadata.
private struct ProductPreviewManifest: Sendable {
    let digest: String
    let entries: [ProductPreviewManifestEntry]

    init(entries: [ProductPreviewManifestEntry]) {
        self.entries = entries
        self.digest = Self.digest(entries)
    }

    /// Stable fingerprint derived from manifest file identities and SHA-256 values.
    ///
    /// This intentionally ignores raw JSON formatting and ordering changes.
    private static func digest(_ entries: [ProductPreviewManifestEntry]) -> String {
        let fingerprint = entries
            .flatMap { entry in
                entry.files.map { file in
                    "\(entry.language.rawValue):\(file.source.rawValue):\(file.name):\(file.sha256.lowercased())"
                }
            }
            .sorted()
            .joined(separator: "\n")
        return ProductPreviewImporter.digest(Data(fingerprint.utf8))
    }
}

/// One language section from `overview.json`.
///
/// The manifest stores language on the section, while individual file entries
/// store source/name/checksum. Decoding copies the section language onto every
/// file so import code can treat files independently.
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

/// One dump file advertised by `overview.json`.
private struct ProductPreviewManifestFile: Decodable, Sendable {
    let name: String
    let sha256: String
    let source: ProductPreviewSource
    fileprivate var language: ProductPreviewLanguage = .english
    fileprivate var id: String {
        ProductPreviewFileImportRecord.makeID(fileName: name, language: language, source: source)
    }
    fileprivate var normalizedSHA256: String {
        sha256.lowercased()
    }

    private enum CodingKeys: CodingKey {
        case name
        case sha256
        case source
    }
}

/// One newline-delimited product row from a preview dump file.
private struct ProductPreviewDumpRecord: Decodable, Sendable {
    let name: String
    let brand: String?
    let barcode: String
    let energy: Int
    let measurement: ProductMeasurement
    let source: ProductPreviewSource
}

/// Recoverable per-file failures.
///
/// A checksum mismatch means the advertised file changed, but the downloaded
/// bytes do not match the manifest. The importer keeps the previous cache for
/// that file.
private enum ProductPreviewImportError: Error, Equatable {
    case checksumMismatch(fileName: String)
}
