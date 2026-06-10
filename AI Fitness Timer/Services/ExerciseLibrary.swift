import Foundation

struct ExerciseLibrary {
    let templates: [ExerciseTemplate]
    private let byID: [String: ExerciseTemplate]

    init(templates: [ExerciseTemplate]) {
        self.templates = templates
        self.byID = Dictionary(uniqueKeysWithValues: templates.map { ($0.id, $0) })
    }

    static func loadFromBundle(bundle: Bundle = .main) throws -> ExerciseLibrary {
        guard let url = bundle.url(forResource: "ExerciseLibrary", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        let data = try Data(contentsOf: url)
        let templates = try JSONDecoder().decode([ExerciseTemplate].self, from: data)
        return ExerciseLibrary(templates: templates)
    }

    func template(id: String) -> ExerciseTemplate? {
        byID[id]
    }

    func validTemplates(ids: [String]) -> [ExerciseTemplate] {
        ids.compactMap { byID[$0] }
    }
}
