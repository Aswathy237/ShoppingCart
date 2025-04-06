//
//  ImageLoader.swift
//  APIdemo
//
//  Created by 61086256 on 06/04/25.
//

import Foundation
import SwiftUI

class ImageLoader: ObservableObject {
    @Published var image: UIImage? = nil

    func loadImage(from url: String) {
        guard let imageURL = URL(string: url) else { return }
        
        // Create a custom URLSession with the CustomURLSessionDelegate
        let session = URLSession(configuration: .default, delegate: CustomURLSessionDelegate(), delegateQueue: nil)
        
        session.dataTask(with: imageURL) { [weak self] data, response, error in
            if let data = data, let loadedImage = UIImage(data: data) {
                DispatchQueue.main.async {
                    self?.image = loadedImage
                }
            }
        }.resume()
    }
}

