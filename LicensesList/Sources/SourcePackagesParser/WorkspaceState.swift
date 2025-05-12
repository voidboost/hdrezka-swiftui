import Foundation

struct WorkspaceState: Decodable {
    let object: ObjectRef
    let version: Int

    struct ObjectRef: Decodable {
        let dependencies: [DependencyRef]
    }

    struct DependencyRef: Decodable {
        let packageRef: PackageRef
        let state: StateRef
    }

    struct PackageRef: Decodable {
        let identity: String
        let kind: String
        let location: String
        let name: String
    }

    struct StateRef: Decodable {
        let checkoutState: CheckoutStateRef
        let name: String
    }

    struct CheckoutStateRef: Decodable {
        let revision: String
        let version: String
    }
}
