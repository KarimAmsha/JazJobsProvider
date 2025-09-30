//
//  APIClient.swift
//  Wishy
//
//  Created by Karim Amsha on 27.04.2024.
//

import Foundation
import Alamofire
import Combine

class APIClient {
    static let shared = APIClient()
    private var activeRequest: DataRequest?
    
    enum APIError: Error {
        case networkError(AFError)
        case invalidData
        case decodingError(DecodingError)
        case requestError(AFError)
        case unauthorized
        case notFound
        case badRequest
        case serverError
        case invalidToken
        case customError(message: String)
        case unknownError

        var errorDescription: String? {
            switch self {
            case .networkError(let err):
                return "خطأ في الاتصال بالشبكة: \(err.localizedDescription)"
            case .invalidData:
                return "البيانات غير صالحة"
            case .decodingError(let err):
                return "خطأ في قراءة البيانات: \(err.localizedDescription)"
            case .requestError(let err):
                return "خطأ في الطلب: \(err.localizedDescription)"
            case .unauthorized:
                return "غير مصرح لك"
            case .notFound:
                return "العنصر غير موجود"
            case .badRequest:
                return "طلب غير صالح"
            case .serverError:
                return "خطأ في الخادم"
            case .invalidToken:
                return "رمز الدخول غير صالح"
            case .customError(let message):
                return message
            case .unknownError:
                return "حدث خطأ غير معروف"
            }
        }
    }

    // MARK: Common Request Function
    private func performRequest<T: Decodable>(
        for endpoint: APIEndpoint,
        with publisher: DataRequest
    ) -> AnyPublisher<T, APIError> {
        return publisher
            .publishData()
            .tryMap { response in
                guard let data = response.data else {
                    throw APIError.invalidData
                }

                let statusCode = response.response?.statusCode ?? 0

                if let jsonStr = String(data: data, encoding: .utf8) {
                    print("📦 Raw JSON response (\(statusCode)): \(jsonStr)")
                }

                // نحاول نفكّه كنص عام ونبحث عن status = false
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    // إذا status == false => فشل
                    if let status = json["status"] as? Bool, status == false {
                        let message = json["message"] as? String ?? "حدث خطأ غير معروف"
                        throw APIError.customError(message: message)
                    }

                    // أو لو statusCode مثل 500
                    if let statusCode = json["statusCode"] as? Int,
                       let message = json["message"] as? String {
                        throw APIError.customError(message: message)
                    }
                }

                // إذا كله تمام، نرجّع الداتا لفكها لاحقًا
                return data
            }
            .decode(type: T.self, decoder: JSONDecoder())
            .mapError { error in
                self.mapDecodingError(error)
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

// MARK: Request Functions
extension APIClient {
    func request<T: Decodable>(endpoint: APIEndpoint, completion: @escaping (Result<T, APIError>) -> Void) {
        activeRequest = AF.request(endpoint.fullURL, method: endpoint.method, parameters: endpoint.parameters, headers: endpoint.headers)
            .validate()
            .response { response in
                self.decodeApiResponse(response: response, completion: completion)
            }
    }
    
//    func requestPublisher<T: Decodable>(endpoint: APIEndpoint) -> AnyPublisher<T, APIError> {
//        let dataRequest = AF.request(endpoint.fullURL, method: endpoint.method, parameters: endpoint.parameters, headers: endpoint.headers)
//        
//        return performRequest(for: endpoint, with: dataRequest)
//    }
    
    func sendData(
        endpoint: APIEndpoint,
        completion: @escaping (Result<Any, AFError>) -> Void
    ) {
        AF.request(endpoint.fullURL, method: .post, parameters: endpoint.parameters, encoding: JSONEncoding.default, headers: endpoint.headers)
            .validate()
            .responseJSON { response in
                completion(response.result)
            }
    }

    func createRequest(endpoint: APIEndpoint, requestInfo: [String :String], completion: @escaping (_ result: String) -> Void){
                
        let parameters: [String : Any] = ["request" : JSONToString(json : requestInfo)!]
        
        AF.request(endpoint.fullURL, method: .post, parameters: parameters, encoding: URLEncoding.httpBody).responseString { response in
            print(response)
            
        }
    }
    
    func JSONToString(json: [String : String]) -> String?{
        do {
            let mdata =  try JSONSerialization.data(withJSONObject: json, options: JSONSerialization.WritingOptions.prettyPrinted) // json to the data
            let convertedString = String(data: mdata, encoding: String.Encoding.utf8) // the data will be converted to the string
            print("the converted json to string is : \(convertedString!)") // <-- here is ur string

            return convertedString!

        } catch let myJSONError {
            print(myJSONError)
        }
        return ""
    }

    func requestMultipartPublisherWithProgress<T: Decodable>(endpoint: APIEndpoint, imageFiles: [(Data, String)]?) -> AnyPublisher<(T, Double), APIError> {
        return Future { promise in
            var request = AF.upload(multipartFormData: { multipartFormData in
                self.createMultipartFormData(
                    multipartFormData: multipartFormData,
                    imageFiles: imageFiles,
                    parameters: endpoint.parameters
                )
            }, to: endpoint.fullURL, headers: endpoint.headers)
                        
            let progressSubject = PassthroughSubject<Double, Never>() // Create a subject for progress updates

            request = request.uploadProgress(closure: { progress in
                let uploadProgress = progress.fractionCompleted
                progressSubject.send(uploadProgress) // Send progress updates
            })
            
            request.responseDecodable(of: T.self, decoder: JSONDecoder()) { response in
                switch response.result {
                case .success(let value):
                    promise(.success((value, 1.0))) // Progress completed when the response is successful
                case .failure(let error):
                    promise(.failure(APIError.requestError(error)))
                }
            }
            
            var cancellable: AnyCancellable?
            cancellable = progressSubject.sink { progress in
                // You can access the progress updates here
                // For example, you can update your UI with the current progress
                let formatter = NumberFormatter()
                formatter.numberStyle = .percent
                formatter.maximumFractionDigits = 1
                if let formattedProgress = formatter.string(from: NSNumber(value: progress)) {
                    print("Upload Progress: \(formattedProgress)")
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
    
    // Helper method to create multipart form data
    private func createMultipartFormData(multipartFormData: MultipartFormData, imageFiles: [(Data, String)]?, parameters: [String: Any]?) {
        if let imageFiles = imageFiles {
            for (imageData, fieldName) in imageFiles {
                multipartFormData.append(imageData, withName: fieldName, fileName: "image.jpg", mimeType: "image/jpeg")
            }
        }

        if let parameters = parameters {
            for (key, value) in parameters {
                if let data = "\(value)".data(using: .utf8) {
                    multipartFormData.append(data, withName: key)
                }
            }
        }
    }

    func requestMultipartPublisher<T: Decodable>(endpoint: APIEndpoint, imageFiles: [(Data, String)]?) -> AnyPublisher<T, APIError> {
        return Future { promise in
            AF.upload(
                multipartFormData: { multipartFormData in
                    if let imageFiles = imageFiles {
                        for (imageData, fieldName) in imageFiles {
                            multipartFormData.append(imageData, withName: fieldName, fileName: "image.jpg", mimeType: "image/jpeg")
                        }
                    }
                    
                    // Add other fields as needed
                    if let parameters = endpoint.parameters {
                        for (key, value) in parameters {
                            if let data = "\(value)".data(using: .utf8) {
                                multipartFormData.append(data, withName: key)
                            }
                        }
                    }
                },
                to: endpoint.fullURL,
                headers: endpoint.headers
            )
            .uploadProgress(closure: { progress in
                // You can handle upload progress here
                print("Upload Progress: \(progress.fractionCompleted * 100)%")
            })
            .responseDecodable(of: T.self, decoder: JSONDecoder()) { response in
                switch response.result {
                case .success(let value):
                    if response.response?.statusCode == 200 {
                        promise(.success(value))
                    } else if response.response?.statusCode == 400 {
                        promise(.failure(APIError.badRequest))
                    } else if response.response?.statusCode == 500 {
                        promise(.failure(APIError.serverError))
                    } else {
                        promise(.failure(APIError.customError(message: LocalizedError.unknownError)))
                    }
                case .failure(let error):
                    promise(.failure(APIError.requestError(error)))
                }
            }
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
}

extension APIClient {
    // MARK: Cancel Request
    func cancelRequest() {
        activeRequest?.cancel()
    }
}

extension APIClient {
    private func decodeApiResponse<T: Decodable>(
        response: AFDataResponse<Data?>,
        completion: @escaping (Result<T, APIError>) -> Void
    ) {
        let statusCode = response.response?.statusCode ?? 0
        print("📡 Response Code: \(statusCode)")

        switch response.result {
        case .success(let data):
            guard let data = data else {
                return completion(.failure(.invalidData))
            }

            // ✅ جرب تفكك النجاح
            if statusCode == 200 {
                do {
                    let decoded = try JSONDecoder().decode(T.self, from: data)
                    return completion(.success(decoded))
                } catch let decodingError as DecodingError {
                    return completion(.failure(mapDecodingError(decodingError)))
                } catch {
                    return completion(.failure(.unknownError))
                }
            }

            // ✅ فكك الخطأ
            do {
                if let jsonStr = String(data: data, encoding: .utf8) {
                    print("❌ Failed to decode AlternateErrorResponse: \(jsonStr)")
                    completion(.failure(.customError(message: jsonStr))) // بدل الرسالة العامة
                } else {
                    completion(.failure(.customError(message: "حدث خطأ غير متوقع في الخادم")))
                }

                let errorResponse = try JSONDecoder().decode(AlternateErrorResponse.self, from: data)
                let message = [
                    errorResponse.message,
                    errorResponse.error,
                    errorResponse.items
                ].compactMap { $0 }.first ?? "حدث خطأ غير معروف من الخادم"

                switch statusCode {
                case 400: completion(.failure(.badRequest))
                case 401: completion(.failure(.unauthorized))
                case 403: completion(.failure(.customError(message: "غير مصرح")))
                case 404: completion(.failure(.notFound))
                case 430: completion(.failure(.invalidToken))
                case 500...599: completion(.failure(.serverError))
                default: completion(.failure(.customError(message: message)))
                }

            } catch {
                if let jsonStr = String(data: data, encoding: .utf8) {
                    print("❌ Failed to decode AlternateErrorResponse: \(jsonStr)")
                }
                completion(.failure(.customError(message: "حدث خطأ غير متوقع في الخادم")))
            }

        case .failure(let afError):
            if let data = response.data,
               let errorJson = String(data: data, encoding: .utf8) {
                print("🔴 Server Error JSON Body: \(errorJson)")
            } else {
                print("🔴 Server Error with no body")
            }
            completion(.failure(.networkError(afError)))
        }
    }

    // Helper function to map decoding errors
    func mapDecodingError(_ error: Error) -> APIError {
        if let decodingError = error as? DecodingError {
            switch decodingError {
            case .dataCorrupted(let context):
                return .customError(message: "Data corrupted: \(context)")
            case .keyNotFound(let key, let context):
                return .customError(message: "Key '\(key.stringValue)' not found: \(context)")
            case .typeMismatch(let type, let context):
                return .customError(message: "Type mismatch, expected \(type): \(context)")
            case .valueNotFound(let type, let context):
                return .customError(message: "Value not found, expected \(type): \(context)")
            default:
                return .decodingError(decodingError)
            }
        } else {
            return .unknownError
        }
    }
}

extension APIClient {
    func requestPublisher<T: Decodable>(endpoint: APIEndpoint) -> AnyPublisher<T, APIError> {
        let request = AF.request(endpoint.fullURL, method: endpoint.method, parameters: endpoint.parameters, encoding: endpoint.encoding, headers: endpoint.headers)
            .validate(statusCode: 200..<600) // نتحقق من كل الأكواد ونحللها يدويًا

        return request.publishData()
            .tryMap { response in
                // Raw Debug
                if let raw = response.data, let json = String(data: raw, encoding: .utf8) {
                    print("\n📦 Raw JSON Response: \(json)\n")
                }

                guard let statusCode = response.response?.statusCode else {
                    throw APIError.unknownError
                }

                switch statusCode {
                case 200..<300:
                    break // OK
                case 400:
                    throw APIError.badRequest
                case 401:
                    throw APIError.unauthorized
                case 403:
                    throw APIError.invalidToken
                case 404:
                    throw APIError.notFound
                case 500:
                    throw APIError.serverError
                default:
                    throw APIError.unknownError
                }

                guard let data = response.data else {
                    throw APIError.invalidData
                }

                return data
            }
            .decode(type: T.self, decoder: JSONDecoder())
            .mapError { error in
                if let apiError = error as? APIError {
                    return apiError
                } else if let decodingError = error as? DecodingError {
                    return self.mapDecodingError(decodingError)
                } else if let afError = error as? AFError {
                    return .networkError(afError)
                } else {
                    return .unknownError
                }
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    // MARK: - Decoding Error Mapper
    func mapDecodingError(_ error: DecodingError) -> APIError {
        switch error {
        case .dataCorrupted(let context):
            return .customError(message: "البيانات تالفة: \(context.debugDescription)")
        case .keyNotFound(let key, let context):
            return .customError(message: "المفتاح \(key.stringValue) غير موجود: \(context.debugDescription)")
        case .typeMismatch(let type, let context):
            return .customError(message: "نوع البيانات غير متطابق \(type): \(context.debugDescription)")
        case .valueNotFound(let type, let context):
            return .customError(message: "القيمة من نوع \(type) غير موجودة: \(context.debugDescription)")
        default:
            return .decodingError(error)
        }
    }
}
