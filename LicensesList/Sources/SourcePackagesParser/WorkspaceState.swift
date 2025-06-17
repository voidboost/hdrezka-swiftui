import Foundation

struct WorkspaceState: Decodable {
    let object: ObjectRef

    struct ObjectRef: Decodable {
        let dependencies: [DependencyRef]
    }

    struct DependencyRef: Decodable {
        let packageRef: PackageRef
        let state: StateRef
    }

    struct PackageRef: Decodable {
        let identity: String
        let location: String
        let name: String
    }

    struct StateRef: Decodable {
        let checkoutState: CheckoutStateRef
    }

    struct CheckoutStateRef: Decodable {
        let version: String
    }
}
