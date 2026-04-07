import Foundation

struct Library: Hashable {
    let name: String
    let url: String
    let licenseBody: String
    let version: String?
    let branch: String?
    let identity: String
}
