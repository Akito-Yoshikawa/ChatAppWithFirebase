//
//  NukeAccessore.swift
//  FreeTalk
//
//  Created by 吉川聖斗 on 2022/06/16.
//

import Foundation
import Nuke

class NukeAccessore: NSObject {
    
    static let sharedManager = NukeAccessore()
    
    func loadImage(thumnaillString: String, completion: @escaping (ImageResponse?) -> Void) {
        guard let thumnaillUrl =  URL(string: thumnaillString) else {
            print("URLの変換に失敗しました。")
            completion(nil)
            return
        }
        
        ImagePipeline.shared.loadImage(with: thumnaillUrl) { result in
            switch result {
            case .success(let data):
                completion(data)
            case .failure(let error):
                print("ImagePipelineのloadImageに失敗しました。\(error)")
                completion(nil)
            }
        }
    }
}
