import Foundation
import Testing
@testable import INDDConverterEngine

@Suite struct EngineTests {
    @Test func testExtendScriptPayloadGeneration() {
        let bridge = InDesignBridge()
        let payload = bridge.generateExtendScriptPayload(
            appName: "Adobe InDesign 2024",
            inputPath: "/Users/test/document with spaces.indd",
            outputPath: "/Users/test/output.idml"
        )

        #expect(payload.contains("Adobe InDesign 2024"))
        #expect(payload.contains("UserInteractionLevels.NEVER_INTERACT"))
        #expect(payload.contains("ExportFormat.INDESIGN_XML"))
        #expect(payload.contains("SaveOptions.NO"))
        #expect(payload.contains("document with spaces.indd"))
        #expect(payload.contains("output.idml"))
    }

    @Test func testBatchConverterItemManagement() {
        let batch = BatchConverter()
        let tmpDir = FileManager.default.temporaryDirectory
        let sample1 = tmpDir.appendingPathComponent("sample1.indd")
        let sample2 = tmpDir.appendingPathComponent("sample2.indt")
        let nonIndd = tmpDir.appendingPathComponent("image.png")

        try? "dummy".write(to: sample1, atomically: true, encoding: .utf8)
        try? "dummy".write(to: sample2, atomically: true, encoding: .utf8)
        try? "dummy".write(to: nonIndd, atomically: true, encoding: .utf8)

        batch.addInputs([sample1, sample2, nonIndd])

        #expect(batch.items.count == 2)
        #expect(batch.items[0].expectedOutputURL.pathExtension == "idml")
        #expect(batch.items[1].expectedOutputURL.pathExtension == "idml")

        batch.clear()
        #expect(batch.items.isEmpty)

        try? FileManager.default.removeItem(at: sample1)
        try? FileManager.default.removeItem(at: sample2)
        try? FileManager.default.removeItem(at: nonIndd)
    }

    @Test func testInDesignDetectorRunsWithoutCrashing() {
        let detector = InDesignDetector()
        let installations = detector.detectInstallations()
        #expect(installations.count >= 0)
    }

    @Test func testDefaultOutputLocationIsSameAsSource() {
        let batch = BatchConverter()
        let customFolder = FileManager.default.temporaryDirectory.appendingPathComponent("custom_dir_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: customFolder, withIntermediateDirectories: true)
        let sampleFile = customFolder.appendingPathComponent("sample_layout.indd")
        try? "dummy".write(to: sampleFile, atomically: true, encoding: .utf8)

        batch.addInputs([sampleFile])

        #expect(batch.items.count == 1)
        let item = batch.items[0]
        // Verify default destination is identical directory to source file
        #expect(item.expectedOutputURL.deletingLastPathComponent().path == sampleFile.deletingLastPathComponent().path)
        #expect(item.expectedOutputURL.lastPathComponent == "sample_layout.idml")

        try? FileManager.default.removeItem(at: customFolder)
    }

    @Test func testINDDSearcherCustomScope() async {
        let tmpDir = FileManager.default.temporaryDirectory.appendingPathComponent("search_test_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        let fileA = tmpDir.appendingPathComponent("documentA.indd")
        let fileB = tmpDir.appendingPathComponent("documentB.indt")
        let fileC = tmpDir.appendingPathComponent("notes.txt")
        try? "data".write(to: fileA, atomically: true, encoding: .utf8)
        try? "data".write(to: fileB, atomically: true, encoding: .utf8)
        try? "data".write(to: fileC, atomically: true, encoding: .utf8)

        let searcher = INDDSearcher()
        let results = await searcher.search(scope: .custom(tmpDir))

        #expect(results.count == 2)
        #expect(results.contains { $0.fileName == "documentA.indd" })
        #expect(results.contains { $0.fileName == "documentB.indt" })

        try? FileManager.default.removeItem(at: tmpDir)
    }
}
