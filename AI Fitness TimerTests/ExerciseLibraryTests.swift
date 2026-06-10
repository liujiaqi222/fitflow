import XCTest
@testable import AI_Fitness_Timer

final class ExerciseLibraryTests: XCTestCase {
    func testLoadsClosedTemplateSet() throws {
        let library = try ExerciseLibrary.loadFromBundle()
        XCTAssertGreaterThanOrEqual(library.templates.count, 16)
        XCTAssertNotNil(library.template(id: "chair_squat"))
        XCTAssertTrue(library.templates.allSatisfy { !$0.id.isEmpty && !$0.name.isEmpty })
    }

    func testFiltersInvalidTemplateIDs() throws {
        let library = try ExerciseLibrary.loadFromBundle()
        let result = library.validTemplates(ids: ["chair_squat", "not_real"])
        XCTAssertEqual(result.map(\.id), ["chair_squat"])
    }
}
