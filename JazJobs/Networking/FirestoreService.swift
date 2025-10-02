//
//  FirestoreService.swift
//  Wishy
//
//  Created by Karim Amsha on 6.05.2024.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging
import FirebaseStorage
import UIKit

class FirestoreService {
    static let shared = FirestoreService()
    let imageStorage = Storage.storage().reference().child("images")

    private init() {}
    
    // Upload Image (existing API - kept for backward compatibility)
    func uploadImageWithThumbnail(image: UIImage?, id: String, imageName: String, completion: @escaping(String?, Bool)->Void) {
        guard let image = image,
              let uploadData = image.jpegData(compressionQuality: 0.5) else {
            completion(nil, false)
            return
        }
        
        let storedImage = imageStorage.child(id).child(imageName)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        storedImage.putData(uploadData, metadata: metadata) { (metadata, error) in
            if let error = error {
                print("Error uploading image: \(error.localizedDescription)")
                completion(nil, false)
            } else {
                storedImage.downloadURL { (url, error) in
                    if let downloadURL = url?.absoluteString {
                        completion(downloadURL, true)
                    } else {
                        completion(nil, false)
                    }
                }
            }
        }
    }
    
    // Upload Multi Images (existing API)
    func uploadMultipleImages2(images: [UIImage?], id: String, completion: @escaping ([String]?, Bool) -> Void) {
        var uploadedImageUrls: [String] = []
        var uploadCount = 0
        
        guard !images.isEmpty else {
            completion([], false)
            return
        }
        
        for (index, image) in images.enumerated() {
            var imageName = ""
            switch index {
                case 0: imageName = "image"
                case 1: imageName = "id_image"
                default: break
            }
            
            uploadImageWithThumbnail(image: image, id: id, imageName: imageName) { (url, success) in
                uploadCount += 1
                
                if let url = url {
                    uploadedImageUrls.append(url)
                }
                
                if uploadCount == images.count {
                    completion(uploadedImageUrls, true)
                } else if !success {
                    completion(nil, false)
                }
            }
        }
    }
    
    func uploadMultipleImages(images: [UIImage?], id: String, completion: @escaping ([String]?, Bool) -> Void) {
        var uploadedImageUrls: [String] = []
        let dispatchGroup = DispatchGroup()
        
        guard !images.isEmpty else {
            completion([], false)
            return
        }
        
        for image in images {
            dispatchGroup.enter()
            let imageName = generateRandomImageName() // Generate a random name
            
            uploadImageWithThumbnail(image: image, id: id, imageName: imageName) { (url, success) in
                if let url = url {
                    uploadedImageUrls.append(url)
                }
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) {
            if uploadedImageUrls.count == images.count {
                completion(uploadedImageUrls, true)
            } else {
                completion(nil, false)
            }
        }
    }
    
    // Function to generate a random image name
    func generateRandomImageName() -> String {
        let uuid = UUID().uuidString // Generate a unique identifier
        let imageName = "image_\(uuid)" // Append it to a base name or use it directly
        return imageName
    }
    
    // MARK: - New APIs with progress support

    // Upload UIImage with progress callback
    func uploadImageWithThumbnail(image: UIImage?,
                                  id: String,
                                  imageName: String,
                                  progress: ((Double) -> Void)? = nil,
                                  completion: @escaping (Result<String, Error>) -> Void) {
        guard let image = image,
              let uploadData = image.jpegData(compressionQuality: 0.5) else {
            completion(.failure(NSError(domain: "Upload", code: -3, userInfo: [NSLocalizedDescriptionKey: "Invalid image data"])))
            return
        }
        
        let storedImage = imageStorage.child(id).child(imageName)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        let uploadTask = storedImage.putData(uploadData, metadata: metadata)
        
        uploadTask.observe(.progress) { snapshot in
            if let snapProgress = snapshot.progress {
                let fraction = Double(snapProgress.completedUnitCount) / Double(max(snapProgress.totalUnitCount, 1))
                progress?(fraction)
            }
        }
        
        uploadTask.observe(.success) { _ in
            storedImage.downloadURL { (url, error) in
                if let error = error {
                    completion(.failure(error))
                } else if let url = url {
                    completion(.success(url.absoluteString))
                } else {
                    completion(.failure(NSError(domain: "Upload", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown storage error"])))
                }
            }
        }
        
        uploadTask.observe(.failure) { snapshot in
            if let error = snapshot.error {
                completion(.failure(error))
            } else {
                completion(.failure(NSError(domain: "Upload", code: -2, userInfo: [NSLocalizedDescriptionKey: "Upload failed"])))
            }
        }
    }
    
    // Upload raw Data with progress callback (preserves caller's chosen compression/quality)
    func uploadImageData(_ data: Data,
                         id: String,
                         imageName: String,
                         progress: ((Double) -> Void)? = nil,
                         completion: @escaping (Result<String, Error>) -> Void) {
        let storedImage = imageStorage.child(id).child(imageName)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        let uploadTask = storedImage.putData(data, metadata: metadata)
        
        uploadTask.observe(.progress) { snapshot in
            if let snapProgress = snapshot.progress {
                let fraction = Double(snapProgress.completedUnitCount) / Double(max(snapProgress.totalUnitCount, 1))
                progress?(fraction)
            }
        }
        
        uploadTask.observe(.success) { _ in
            storedImage.downloadURL { (url, error) in
                if let error = error {
                    completion(.failure(error))
                } else if let url = url {
                    completion(.success(url.absoluteString))
                } else {
                    completion(.failure(NSError(domain: "Upload", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown storage error"])))
                }
            }
        }
        
        uploadTask.observe(.failure) { snapshot in
            if let error = snapshot.error {
                completion(.failure(error))
            } else {
                completion(.failure(NSError(domain: "Upload", code: -2, userInfo: [NSLocalizedDescriptionKey: "Upload failed"])))
            }
        }
    }
}

