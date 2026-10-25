import Alamofire
import Defaults
import Foundation

final class CustomInterceptor: RequestInterceptor {
    func retry(_ request: Request, for _: Session, dueTo _: any Error, completion: @escaping (RetryResult) -> Void) {
        if request.retryCount < 1, request.response?.statusCode == 403 {
            Defaults[.useHeaders] = request.request?.headers["X-Hdrezka-Android-App"] == nil

            completion(.retry)
        } else {
            completion(.doNotRetry)
        }
    }
}
