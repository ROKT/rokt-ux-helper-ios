//
//  ExternalAsyncImage.swift
//  RoktUXHelper
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import SwiftUI
import Combine
import DcuiSchema

@available(iOS 15.0, *)
struct ExternalAsyncImage: View {
    @ObservedObject var imageDownloader: ImageDownloader
    let scale: BackgroundImageScale?
    let altString: String
    @State private var image: UIImage?

    init(urlString: String, scale: BackgroundImageScale?, altString: String, loader: ImageLoader) {
        self.imageDownloader = ImageDownloader(urlString: urlString, loader: loader)
        self.scale = scale
        self.altString = altString
    }

    var body: some View {
        if let image = image {
            Image(uiImage: image)
                .scaleIfNeeded(scale: scale)
                .accessibilityLabel(altString)
                .accessibilityHidden(altString.isEmpty)
                .onReceive(imageDownloader.imageSubject) { newImage in
                    self.image = newImage
                }
        } else {
            EmptyView()
                .onReceive(imageDownloader.imageSubject) { newImage in
                    self.image = newImage
                }
        }

    }
}
