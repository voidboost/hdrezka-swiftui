import AVFoundation
import Combine

extension AVPlayer {
    func periodicTimePublisher(forInterval interval: CMTime, queue: DispatchQueue? = .main) -> AnyPublisher<CMTime, Never> {
        PeriodicTimePublisher(player: self, interval: interval, queue: queue).eraseToAnyPublisher()
    }
}

private struct PeriodicTimePublisher: Publisher {
    typealias Output = CMTime
    typealias Failure = Never

    private let player: AVPlayer
    private let interval: CMTime
    private let queue: DispatchQueue?

    init(player: AVPlayer, interval: CMTime, queue: DispatchQueue?) {
        self.player = player
        self.interval = interval
        self.queue = queue
    }

    func receive<S: Subscriber>(subscriber: S) where S.Input == Output, S.Failure == Failure {
        let subscription = PeriodicTimeSubscription(
            subscriber: subscriber,
            player: player,
            interval: interval,
            queue: queue,
        )

        subscriber.receive(subscription: subscription)
    }
}

private final class PeriodicTimeSubscription<S: Subscriber>: Subscription where S.Input == CMTime, S.Failure == Never {
    private var subscriber: S?
    private weak var player: AVPlayer?
    private var observer: Any?

    init(subscriber: S, player: AVPlayer, interval: CMTime, queue: DispatchQueue?) {
        self.subscriber = subscriber
        self.player = player

        observer = player.addPeriodicTimeObserver(forInterval: interval, queue: queue) { [weak self] time in
            _ = self?.subscriber?.receive(time)
        }
    }

    func request(_: Subscribers.Demand) {}

    func cancel() {
        guard let observer else {
            subscriber = nil
            return
        }

        player?.removeTimeObserver(observer)

        self.observer = nil
        subscriber = nil
    }

    deinit {
        cancel()
    }
}
