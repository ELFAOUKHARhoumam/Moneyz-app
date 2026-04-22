import SwiftData

enum PreviewContainer {
    static var modelContainer: ModelContainer {
        PersistenceController.previewContainer()
    }
}
