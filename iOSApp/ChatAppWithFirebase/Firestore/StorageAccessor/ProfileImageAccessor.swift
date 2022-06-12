//
//  ProfileImageAccessor.swift
//  ChatAppWithFirebase
//
//  Created by 吉川聖斗 on 2022/06/12.
//

import Firebase

struct ProfileImage {
    static func targetCollectionRef(_ fileName: String) -> StorageReference {
        return Storage.storage().reference().child("profile_image").child(fileName)
    }
}

class ProfileImageAccessor: NSObject {
    
    static let sharedManager = ProfileImageAccessor()
    
    /// profile_image/fileName(指定した名前)の直下に画像データをセットする
    func profileImagePutData(fileName: String, uploadImage: Data, completion: @escaping (Error?) -> Void) {
        
        ProfileImage.targetCollectionRef(fileName).putData(uploadImage, metadata: nil) {
            (matadata, error) in
                if let error = error {
                    print("Firestorageへの情報の保存に失敗しました。\(error)")
                    completion(error)
                    return
                }
            print("Firestorageへの情報の保存に成功しました。")

            completion(nil)
        }
    }

    /// profile_image/fileName(指定した名前)の直下から画像データをダウンロードする
    func downloadImageReturnURLString(fileName: String, completion: @escaping (Result<String?, Error>) -> Void) {
        
        ProfileImage.targetCollectionRef(fileName).downloadURL { (url, error) in
            if let error = error {
                print("Firestorageからのダウンロードに失敗しました。\(error)")
                completion(.failure(error))
                return
            }

            print("Firestorageからのダウンロードに成功しました。")

            guard let urlString = url?.absoluteString else {
                completion(.success(nil))
                return
            }

            completion(.success(urlString))
        }
    }
}
