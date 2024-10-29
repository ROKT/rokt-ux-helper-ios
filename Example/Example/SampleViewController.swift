//
//  SampleVC.swift
//  Example
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/


import RoktUXHelper
import SwiftUI
import SafariServices
import UIKit

class SampleViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupView()
    }
    
    @objc func setupView() {
        view.backgroundColor = .white
        guard let experience = String.getExperienceResponse(for: "experience") else {
            return
        }
        
        let roktView = RoktLayoutUIView(
            experienceResponse: experience, 
            location: "#target_element" // "targetElementSelector" in experience JSON file
        ) { [weak self] uxEvent in
            guard let self else { return }
        
            // Handle open URL event
            // Here is a sample how to open different types of URLs
            if let event = uxEvent as? RoktUXEvent.OpenUrl,
               let url = URL(string: event.url){
                switch event.type {
                case .externally:
                    UIApplication.shared.open(url) { _ in
                        event.onClose?(event.id)
                    }
                default:
                    let safariVC = SFSafariViewController(url: url)
                    safariVC.modalPresentationStyle = .pageSheet
                    present(safariVC, animated: true) {
                        event.onClose?(event.id)
                    }
                }
            } else if uxEvent as? RoktUXEvent.LayoutCompleted != nil {
                dismiss(animated: true)
            }
            
            // Handle UX events here
            
        } onPlatformEvent: { platformEvent in
            // Send these platform events to Rokt API
        }

        view.addSubview(roktView)
        
        roktView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            roktView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100),
            roktView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            roktView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            roktView.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor)
        ])
    }
}

extension SampleViewController: ImageLoader {
    
    func loadImage(urlString: String, completion: @escaping (Result<UIImage?, any Error>) -> Void) {
        guard let url = URL(string: urlString) else { return }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else { return }
            DispatchQueue.main.async {
                completion(.success(UIImage(data: data)))
            }
        }
        
        task.resume()
    }
}

struct SampleVCRepresentable: UIViewControllerRepresentable {
    
    func makeUIViewController(context: Context) -> UIViewController {
        SampleViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
