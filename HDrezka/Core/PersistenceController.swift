import CoreData
import SwiftUI

@Observable
class PersistenceController {
    @ObservationIgnored
    static let shared = PersistenceController()

    @ObservationIgnored
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    @ObservationIgnored
    private let container: NSPersistentContainer

    init() {
        container = NSPersistentContainer(name: "HDrezka")
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Core Data failed to load: \(error.localizedDescription)")
            }
        }
    }
}

extension SelectPosition {
    static func fetch() -> NSFetchRequest<SelectPosition> {
        let request = NSFetchRequest<SelectPosition>(entityName: "SelectPosition")

        request.sortDescriptors = []

        return request
    }
}

extension PlayerPosition {
    static func fetch() -> NSFetchRequest<PlayerPosition> {
        let request = NSFetchRequest<PlayerPosition>(entityName: "PlayerPosition")

        request.sortDescriptors = []

        return request
    }
}

extension NSManagedObjectContext {
    func saveContext() {
        if hasChanges {
            try? save()
        }
    }
}
