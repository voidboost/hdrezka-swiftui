import Alamofire
import Defaults
import Foundation

final class CustomInterceptor: RequestInterceptor {
    func retry(_ request: Request, for session: Session, dueTo error: any Error, completion: @escaping (RetryResult) -> Void) {
        if request.retryCount < 1, request.response?.statusCode == 403 {
            Defaults[.useHeaders].toggle()

            completion(.retry)
        } else {
            completion(.doNotRetry)
        }
    }
}
