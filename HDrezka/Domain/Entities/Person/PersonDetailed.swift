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
    let id: UUID

    init(nameRu: String, nameOrig: String?, hphoto: String, photo: String, career: String?, birthDate: String?, birthPlace: String?, deathDate: String?, deathPlace: String?, height: String?, actorMovies: [MovieSimple]?, actressMovies: [MovieSimple]?, directorMovies: [MovieSimple]?, producerMovies: [MovieSimple]?, screenwriterMovies: [MovieSimple]?, operatorMovies: [MovieSimple]?, editorMovies: [MovieSimple]?, artistMovies: [MovieSimple]?, composerMovies: [MovieSimple]?, id: UUID = .init()) {
        self.nameRu = nameRu
        self.nameOrig = nameOrig
        self.hphoto = hphoto
        self.photo = photo
        self.career = career
        self.birthDate = birthDate
        self.birthPlace = birthPlace
        self.deathDate = deathDate
        self.deathPlace = deathPlace
        self.height = height
        self.actorMovies = actorMovies
        self.actressMovies = actressMovies
        self.directorMovies = directorMovies
        self.producerMovies = producerMovies
        self.screenwriterMovies = screenwriterMovies
        self.operatorMovies = operatorMovies
        self.editorMovies = editorMovies
        self.artistMovies = artistMovies
        self.composerMovies = composerMovies
        self.id = id
    }
}
