//
//  ImageDownloader.swift
//  RoktUXHelper
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import Combine
import SwiftUI

@available(iOS 13.0, *)
class ImageDownloader: ObservableObject {
    var imageSubject = CurrentValueSubject<UIImage?, Never>(nil)

    init(urlString: String, loader: RoktUXImageLoader) {
        loader.loadImage(urlString: urlString) { [weak self] result in
            switch result {
            case .success(let image):
                DispatchQueue.main.async {
                    self?.imageSubject.send(image) // Publish the new image
                }
            default:
                break
            }
        }
    }
}
