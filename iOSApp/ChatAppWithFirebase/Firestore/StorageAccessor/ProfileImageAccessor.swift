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
    
    // FIXME: デフォルトイメージを登録(仮画像)
    let defaultImage =  UIImage(named: "freeImage01")
    let defaultImageFileName = "defautIcon.jpg"
    
    /// profile_image/fileName(指定した名前)の直下に画像データをセットする
    func profileImagePutData(fileName: String, uploadImage: Data, metadata: StorageMetadata, completion: @escaping (Error?) -> Void) {
        
        ProfileImage.targetCollectionRef(fileName).putData(uploadImage, metadata: metadata) {
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
    
    func uploadProfileImage(_ uploadImage: Data, completion: @escaping (String?) -> Void) {
        let fileName = "\(NSUUID().uuidString).jpg"
        let metaData = StorageMetadata()
        metaData.contentType = "image/jpg"
        
        self.profileImagePutData(fileName: fileName, uploadImage: uploadImage, metadata: metaData) { (error) in

            if let _ = error {
                completion(nil)
                return
            }
                        
            self.downloadImageReturnURLString(fileName: fileName) { (result) in

                switch result {
                case .success(let urlString):
                    guard let urlString = urlString else {
                        completion(nil)
                        return
                    }
                    
                    completion(urlString)
                case .failure(_):
                    completion(nil)
                    return
                }
            }
        }
    }
}
