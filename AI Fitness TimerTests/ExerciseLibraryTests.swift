import XCTest
@testable import AI_Fitness_Timer

final class ExerciseLibraryTests: XCTestCase {
    func testLoadsClosedTemplateSet() throws {
        let library = try ExerciseLibrary.loadFromBundle()
        XCTAssertEqual(library.templates.count, 16)
        XCTAssertNotNil(library.template(id: "chair_squat"))
        XCTAssertTrue(library.templates.allSatisfy { !$0.id.isEmpty && !$0.name.isEmpty })
    }

    func testFiltersInvalidTemplateIDs() throws {
        let library = try ExerciseLibrary.loadFromBundle()
        let result = library.validTemplates(ids: ["wall_pushup", "not_real", "chair_squat"])
        XCTAssertEqual(result.map(\.id), ["wall_pushup", "chair_squat"])
    }

    func testRejectsDuplicateTemplateIDs() throws {
        let library = try ExerciseLibrary.loadFromBundle()
        let duplicateTemplates = library.templates + [library.templates[0]]

        XCTAssertThrowsError(try ExerciseLibrary(templates: duplicateTemplates)) { error in
            XCTAssertEqual(error as? ExerciseLibraryError, .duplicateTemplateID("chair_squat"))
        }
    }

    func testBundledTemplatesHaveValidResourceIntegrity() throws {
        let library = try ExerciseLibrary.loadFromBundle()
        let ids = Set(library.templates.map(\.id))

        XCTAssertEqual(ids.count, library.templates.count)
        XCTAssertTrue(library.templates.allSatisfy { template in
            !template.id.isEmpty &&
            !template.name.isEmpty &&
            !template.instructions.isEmpty &&
            !template.safety.isEmpty &&
            template.duration > 0 &&
            template.sets > 0 &&
            template.restTime > 0 &&
            template.alternatives.allSatisfy { ids.contains($0) }
        })
    }
}
