import Foundation

enum ExerciseLibraryError: Error, Equatable {
    case duplicateTemplateID(String)
}

struct ExerciseLibrary {
    let templates: [ExerciseTemplate]
    private let byID: [String: ExerciseTemplate]

    init(templates: [ExerciseTemplate]) throws {
        var lookup: [String: ExerciseTemplate] = [:]
        for template in templates {
            if lookup[template.id] != nil {
                throw ExerciseLibraryError.duplicateTemplateID(template.id)
            }
            lookup[template.id] = template
        }

        self.templates = templates
        self.byID = lookup
    }

    static func loadFromBundle(bundle: Bundle = .main) throws -> ExerciseLibrary {
        guard let url = bundle.url(forResource: "ExerciseLibrary", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        let data = try Data(contentsOf: url)
        let templates = try JSONDecoder().decode([ExerciseTemplate].self, from: data)
        return try ExerciseLibrary(templates: templates)
    }

    func template(id: String) -> ExerciseTemplate? {
        byID[id]
    }

    func validTemplates(ids: [String]) -> [ExerciseTemplate] {
        ids.compactMap { byID[$0] }
    }
}
