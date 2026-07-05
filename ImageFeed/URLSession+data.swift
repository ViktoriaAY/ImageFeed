import Foundation

enum NetworkError: Error {
    case httpStatusCode(Int)
    case urlRequestError(Error)
    case urlSessionError
    case invalidRequest
    case decodingError(Error)
}

extension URLSession {
    func data(
        for request: URLRequest,
        completion: @escaping (Result<Data, Error>) -> Void
    ) -> URLSessionTask {

        let fulfillCompletionOnTheMainThread: (Result<Data, Error>) -> Void = { result in
            DispatchQueue.main.async {
                completion(result)
            }
        }

        let task = dataTask(with: request) { data, response, error in

            print("===== URLSession callback =====")

            if let response = response as? HTTPURLResponse {
                print("STATUS =", response.statusCode)
            }

            if let data = data,
               let body = String(data: data, encoding: .utf8) {
                print("BODY =", body)
            }

            if let error = error {
                print("ERROR =", error.localizedDescription)
            }

            if let data = data,
               let response = response as? HTTPURLResponse {

                if 200..<300 ~= response.statusCode {
                    fulfillCompletionOnTheMainThread(.success(data))
                } else {
                    print("UNSPLASH SERVER ERROR: Сервер вернул код ошибки \(response.statusCode)") 
                    fulfillCompletionOnTheMainThread(.failure(NetworkError.httpStatusCode(response.statusCode)))
                }

            } else if let error = error {
                fulfillCompletionOnTheMainThread(.failure(NetworkError.urlRequestError(error)))
            } else {
                fulfillCompletionOnTheMainThread(.failure(NetworkError.urlSessionError))
            }
        }

        return task
    }
}
