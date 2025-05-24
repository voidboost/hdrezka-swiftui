import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    private let container: NSPersistentContainer

    init() {
        container = NSPersistentContainer(name: "HDrezka")
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
    }
}

extension SelectPosition {
    static func fetch() -> NSFetchRequest<SelectPosition> {
        let request = NSFetchRequest<SelectPosition>(entityName: "SelectPosition")

        request.sortDescriptors = [NSSortDescriptor(keyPath: \SelectPosition.id, ascending: true)]

        return request
    }
}

extension PlayerPosition {
    static func fetch() -> NSFetchRequest<PlayerPosition> {
        let request = NSFetchRequest<PlayerPosition>(entityName: "PlayerPosition")

        request.sortDescriptors = [NSSortDescriptor(keyPath: \PlayerPosition.id, ascending: true)]

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
