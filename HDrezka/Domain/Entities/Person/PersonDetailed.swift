import Foundation

struct PersonDetailed: Identifiable, Hashable {
    let nameRu: String
    let nameOrig: String?
    let hphoto: String
    let photo: String
    let career: String?
    let birthDate: String?
    let birthPlace: String?
    let deathDate: String?
    let deathPlace: String?
    let height: String?
    let actorMovies: [MovieSimple]?
    let actressMovies: [MovieSimple]?
    let directorMovies: [MovieSimple]?
    let producerMovies: [MovieSimple]?
    let screenwriterMovies: [MovieSimple]?
    let operatorMovies: [MovieSimple]?
    let editorMovies: [MovieSimple]?
    let artistMovies: [MovieSimple]?
    let composerMovies: [MovieSimple]?
    var id = UUID()
}
