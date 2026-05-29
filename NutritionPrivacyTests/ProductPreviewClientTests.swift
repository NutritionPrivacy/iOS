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

            let summary = try await client.importProductPreviews { progress in
                progressEvents.withValue { $0.append(progress) }
            }

            #expect(summary.importedProductCount == 2)
            #expect(summary.skippedProductCount == 0)
            #expect(summary.importedFileCount == 1)
            #expect(progressEvents.value.first?.phase == .fetchingManifest)
            #expect(progressEvents.value.last?.phase == .finished)

            try await database.read { db in
                let previews = try ProductPreview.all.fetchAll(db)
                let importRecord = try ProductPreviewImportRecord.fetchOne(db)

                #expect(previews.count == 2)
                #expect(previews.map(\.name).sorted() == ["Almond drink", "Rolled oats"])
                #expect(previews.allSatisfy { $0.language == .english })
                #expect(previews.allSatisfy { $0.source == .openFoodFacts })
                #expect(previews.first { $0.barcode == "123456789" }?.energy == 45)

                let record = try #require(importRecord)
                #expect(record.id == "nightly")
                #expect(record.manifestDigest != nil)
                #expect(record.productCount == 2)
                #expect(record.skippedProductCount == 0)
            }
        }

        @Test(.dependency(\.date.now, Date(timeIntervalSince1970: 1_800_000_000)))
        func importProductPreviewsSkipsDumpWhenManifestIsUnchanged() async throws {
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

            try Data(
                """
                {"source":0,"energy":50,"barcode":"123456789","measurement":1,"name":"Changed oats","brand":"Acme"}

                """.utf8
            )
            .write(to: dumpURL)

            let progressEvents = LockIsolated<[ProductPreviewImportProgress]>([])
            let summary = try await client.importProductPreviews { progress in
                progressEvents.withValue { $0.append(progress) }
            }

            #expect(summary.importedProductCount == 1)
            #expect(summary.importedFileCount == 0)
            #expect(progressEvents.value.map(\.phase) == [.fetchingManifest, .finished])

            try await database.read { db in
                let preview = try #require(try ProductPreview.fetchOne(db))
                #expect(preview.name == "Oats")
                #expect(preview.energy == 42)
            }
        }

        private func sha256(_ data: Data) -> String {
            SHA256.hash(data: data)
                .map { String(format: "%02x", $0) }
                .joined()
        }
    }
}
