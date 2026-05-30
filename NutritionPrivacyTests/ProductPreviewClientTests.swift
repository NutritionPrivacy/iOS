import CryptoKit
import Dependencies
import DependenciesTestSupport
import Foundation
import SQLiteData
import Testing
@testable import NutritionPrivacy

extension BaseTestSuite {
    struct ProductPreviewClientTests {
        @Dependency(\.defaultDatabase)
        private var database

        @Test(.dependency(\.date.now, Date(timeIntervalSince1970: 1_800_000_000)))
        func importProductPreviewsStoresDumpAndReportsProgress() async throws {
            // GIVEN a manifest and dump file with duplicate product rows.
            let directory = FileManager.default.temporaryDirectory
                .appending(path: UUID().uuidString, directoryHint: .isDirectory)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: directory) }

            let manifestURL = directory.appending(path: "overview.json")
            let dumpURL = directory.appending(path: "products.json")

            let dumpData = Data(
                """
                {"source":0,"energy":42,"barcode":"123456789","measurement":1,"name":"Oats","brand":"Acme"}
                {"source":0,"energy":15,"barcode":"987654321","measurement":0,"name":"Almond drink"}
                {"source":0,"energy":45,"barcode":"123456789","measurement":1,"name":"Rolled oats","brand":"Acme"}

                """.utf8
            )
            try Data(
                """
                [{"language":"english","files":[{"source":0,"name":"products.json","sha256":"\(sha256(dumpData))"}]}]
                """.utf8
            )
            .write(to: manifestURL)
            try dumpData.write(to: dumpURL)

            let client = ProductPreviewClient.live(manifestURL: manifestURL, assetBaseURL: directory)
            let progressEvents = LockIsolated<[ProductPreviewImportProgress]>([])

            // WHEN importing product previews from the local release assets.
            let summary = try await client.importProductPreviews { progress in
                progressEvents.withValue { $0.append(progress) }
            }

            // THEN the import summary and progress events report the completed import.
            #expect(summary.importedProductCount == 2)
            #expect(summary.skippedProductCount == 0)
            #expect(summary.importedFileCount == 1)
            #expect(progressEvents.value.first?.phase == .fetchingManifest)
            #expect(progressEvents.value.last?.phase == .finished)

            // THEN the latest rows and import metadata are persisted.
            try await database.read { db in
                let previews = try ProductPreview.all.fetchAll(db)
                let importRecord = try ProductPreviewImportRecord.fetchOne(db)
                let fileImportRecord = try ProductPreviewFileImportRecord.fetchOne(db)

                #expect(previews.count == 2)
                #expect(previews.map(\.name).sorted() == ["Almond drink", "Rolled oats"])
                #expect(previews.allSatisfy { $0.language == .english })
                #expect(previews.allSatisfy { $0.source == .openFoodFacts })
                #expect(previews.allSatisfy { $0.fileName == "products.json" })
                #expect(previews.first { $0.barcode == "123456789" }?.energy == 45)

                let record = try #require(importRecord)
                #expect(record.id == "nightly")
                #expect(record.manifestDigest != nil)
                #expect(record.productCount == 2)
                #expect(record.skippedProductCount == 0)

                let fileRecord = try #require(fileImportRecord)
                #expect(fileRecord.fileName == "products.json")
                #expect(fileRecord.productCount == 3)
                #expect(fileRecord.skippedProductCount == 0)
            }
        }

        @Test(.dependency(\.date.now, Date(timeIntervalSince1970: 1_800_000_000)))
        func importProductPreviewsSkipsDumpWhenManifestIsUnchanged() async throws {
            // GIVEN an already-imported manifest and dump file.
            let directory = FileManager.default.temporaryDirectory
                .appending(path: UUID().uuidString, directoryHint: .isDirectory)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: directory) }

            let manifestURL = directory.appending(path: "overview.json")
            let dumpURL = directory.appending(path: "products.json")

            let firstDumpData = Data(
                """
                {"source":0,"energy":42,"barcode":"123456789","measurement":1,"name":"Oats","brand":"Acme"}

                """.utf8
            )
            try Data(
                """
                [{"language":"english","files":[{"source":0,"name":"products.json","sha256":"\(sha256(firstDumpData))"}]}]
                """.utf8
            )
            .write(to: manifestURL)
            try firstDumpData.write(to: dumpURL)

            let client = ProductPreviewClient.live(manifestURL: manifestURL, assetBaseURL: directory)
            _ = try await client.importProductPreviews { _ in }

            // GIVEN the dump file changes without a matching manifest checksum change.
            try Data(
                """
                {"source":0,"energy":50,"barcode":"123456789","measurement":1,"name":"Changed oats","brand":"Acme"}

                """.utf8
            )
            .write(to: dumpURL)

            let progressEvents = LockIsolated<[ProductPreviewImportProgress]>([])

            // WHEN importing product previews again.
            let summary = try await client.importProductPreviews { progress in
                progressEvents.withValue { $0.append(progress) }
            }

            // THEN no dump file is re-imported.
            #expect(summary.importedProductCount == 1)
            #expect(summary.importedFileCount == 0)
            #expect(progressEvents.value.map(\.phase) == [.fetchingManifest, .finished])

            // THEN the cached preview remains unchanged.
            try await database.read { db in
                let preview = try #require(try ProductPreview.fetchOne(db))
                #expect(preview.name == "Oats")
                #expect(preview.energy == 42)
            }
        }

        @Test(.dependency(\.date.now, Date(timeIntervalSince1970: 1_800_000_000)))
        func importProductPreviewsDownloadsOnlyChangedFiles() async throws {
            // GIVEN previously imported English and German dump files.
            let directory = FileManager.default.temporaryDirectory
                .appending(path: UUID().uuidString, directoryHint: .isDirectory)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: directory) }

            let manifestURL = directory.appending(path: "overview.json")
            let englishDumpURL = directory.appending(path: "english.json")
            let germanDumpURL = directory.appending(path: "german.json")

            let firstEnglishDumpData = Data(
                """
                {"source":0,"energy":42,"barcode":"123456789","measurement":1,"name":"Oats","brand":"Acme"}

                """.utf8
            )
            let germanDumpData = Data(
                """
                {"source":0,"energy":15,"barcode":"222","measurement":1,"name":"Hafer","brand":"Acme"}

                """.utf8
            )
            try firstEnglishDumpData.write(to: englishDumpURL)
            try germanDumpData.write(to: germanDumpURL)
            try writeManifest(
                to: manifestURL,
                englishSHA256: sha256(firstEnglishDumpData),
                germanSHA256: sha256(germanDumpData)
            )

            let client = ProductPreviewClient.live(manifestURL: manifestURL, assetBaseURL: directory)
            _ = try await client.importProductPreviews { _ in }

            // GIVEN only the English file changes in the manifest.
            let secondEnglishDumpData = Data(
                """
                {"source":0,"energy":50,"barcode":"123456789","measurement":1,"name":"Changed oats","brand":"Acme"}

                """.utf8
            )
            try secondEnglishDumpData.write(to: englishDumpURL)
            try FileManager.default.removeItem(at: germanDumpURL)
            try writeManifest(
                to: manifestURL,
                englishSHA256: sha256(secondEnglishDumpData),
                germanSHA256: sha256(germanDumpData)
            )

            // WHEN importing product previews again.
            let summary = try await client.importProductPreviews { _ in }

            // THEN only the changed file is downloaded and imported.
            #expect(summary.importedProductCount == 2)
            #expect(summary.importedFileCount == 1)

            // THEN unchanged cached rows are kept alongside refreshed rows.
            try await database.read { db in
                let previews = try ProductPreview.all.fetchAll(db)
                #expect(previews.map(\.name).sorted() == ["Changed oats", "Hafer"])
            }
        }

        @Test(.dependency(\.date.now, Date(timeIntervalSince1970: 1_800_000_000)))
        func importProductPreviewsKeepsCacheWhenChangedFileChecksumFails() async throws {
            // GIVEN an already-imported dump file.
            let directory = FileManager.default.temporaryDirectory
                .appending(path: UUID().uuidString, directoryHint: .isDirectory)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: directory) }

            let manifestURL = directory.appending(path: "overview.json")
            let dumpURL = directory.appending(path: "products.json")

            let firstDumpData = Data(
                """
                {"source":0,"energy":42,"barcode":"123456789","measurement":1,"name":"Oats","brand":"Acme"}

                """.utf8
            )
            try Data(
                """
                [{"language":"english","files":[{"source":0,"name":"products.json","sha256":"\(sha256(firstDumpData))"}]}]
                """.utf8
            )
            .write(to: manifestURL)
            try firstDumpData.write(to: dumpURL)

            let client = ProductPreviewClient.live(manifestURL: manifestURL, assetBaseURL: directory)
            _ = try await client.importProductPreviews { _ in }

            // GIVEN the manifest advertises a checksum that does not match the changed dump bytes.
            let corruptedDumpData = Data(
                """
                {"source":0,"energy":50,"barcode":"123456789","measurement":1,"name":"Changed oats","brand":"Acme"}

                """.utf8
            )
            try Data(
                """
                [{"language":"english","files":[{"source":0,"name":"products.json","sha256":"0000000000000000000000000000000000000000000000000000000000000000"}]}]
                """.utf8
            )
            .write(to: manifestURL)
            try corruptedDumpData.write(to: dumpURL)

            // WHEN importing product previews again.
            let summary = try await client.importProductPreviews { _ in }

            // THEN the failed file is skipped without counting a new import.
            #expect(summary.importedProductCount == 1)
            #expect(summary.importedFileCount == 0)

            // THEN the previous cache and file checksum metadata are preserved.
            try await database.read { db in
                let preview = try #require(try ProductPreview.fetchOne(db))
                let fileRecord = try #require(try ProductPreviewFileImportRecord.fetchOne(db))

                #expect(preview.name == "Oats")
                #expect(preview.energy == 42)
                #expect(fileRecord.sha256 == sha256(firstDumpData))
            }
        }

        @Test(.dependency(\.date.now, Date(timeIntervalSince1970: 1_800_000_000)))
        func importProductPreviewsPreservesSkippedCountWhenChangedFileChecksumFails() async throws {
            // GIVEN an already-imported dump file with one malformed product row.
            let directory = FileManager.default.temporaryDirectory
                .appending(path: UUID().uuidString, directoryHint: .isDirectory)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: directory) }

            let manifestURL = directory.appending(path: "overview.json")
            let dumpURL = directory.appending(path: "products.json")

            let firstDumpData = Data(
                """
                {"source":0,"energy":42,"barcode":"123456789","measurement":1,"name":"Oats","brand":"Acme"}
                {"source":0,"energy":"invalid","barcode":"987654321","measurement":1,"name":"Broken"}

                """.utf8
            )
            try Data(
                """
                [{"language":"english","files":[{"source":0,"name":"products.json","sha256":"\(sha256(firstDumpData))"}]}]
                """.utf8
            )
            .write(to: manifestURL)
            try firstDumpData.write(to: dumpURL)

            let client = ProductPreviewClient.live(manifestURL: manifestURL, assetBaseURL: directory)
            _ = try await client.importProductPreviews { _ in }

            // GIVEN the manifest advertises a changed file whose bytes fail checksum verification.
            let changedDumpData = Data(
                """
                {"source":0,"energy":50,"barcode":"123456789","measurement":1,"name":"Changed oats","brand":"Acme"}

                """.utf8
            )
            try Data(
                """
                [{"language":"english","files":[{"source":0,"name":"products.json","sha256":"0000000000000000000000000000000000000000000000000000000000000000"}]}]
                """.utf8
            )
            .write(to: manifestURL)
            try changedDumpData.write(to: dumpURL)

            // WHEN importing product previews again.
            let summary = try await client.importProductPreviews { _ in }

            // THEN the summary continues to represent the cached file metadata.
            #expect(summary.importedProductCount == 1)
            #expect(summary.skippedProductCount == 1)
            #expect(summary.importedFileCount == 0)

            try await database.read { db in
                let importRecord = try #require(try ProductPreviewImportRecord.fetchOne(db))
                let fileRecord = try #require(try ProductPreviewFileImportRecord.fetchOne(db))

                #expect(importRecord.skippedProductCount == 1)
                #expect(fileRecord.skippedProductCount == 1)
            }
        }

        private func sha256(_ data: Data) -> String {
            SHA256.hash(data: data)
                .map { String(format: "%02x", $0) }
                .joined()
        }

        private func writeManifest(
            to url: URL,
            englishSHA256: String,
            germanSHA256: String
        ) throws {
            try Data(
                """
                [
                  {"language":"english","files":[{"source":0,"name":"english.json","sha256":"\(englishSHA256)"}]},
                  {"language":"german","files":[{"source":0,"name":"german.json","sha256":"\(germanSHA256)"}]}
                ]
                """.utf8
            )
            .write(to: url)
        }
    }
}
