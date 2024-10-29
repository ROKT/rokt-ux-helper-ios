//
//  HomeView.swift
//  Example
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import SwiftUI
import RoktUXHelper

struct HomeView: View {

    @State private var isShowingSwiftUIView = false
    @State private var isShowingUIKitView = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.white.edgesIgnoringSafeArea(.all)
                VStack {
                    Image("RoktLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, alignment: .center)
                        .padding(.top, 100)
                    
                    Text("Seize the Transaction Moment")
                        .font(.defaultFont(.header3))
                        .foregroundColor(.titleColor)
                        .multilineTextAlignment(.center)
                        .padding()
                    Spacer()
                    
                    Button(action: {
                        isShowingSwiftUIView = true
                    }) {
                        Text("Load SwiftUI")
                    }
                    .padding(.top)
                    .buttonStyle(ButtonDefaultOutlined())
                    
                    Button(action: {
                        isShowingUIKitView = true
                    }) {
                        Text("Load UIKit")
                    }
                    .padding(.top)
                    .buttonStyle(ButtonDefaultOutlined())
                    
                    Spacer()
                    Text("® Rokt 2024 — All rights reserved")
                        .font(.defaultFont(.subtitle2))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.textColor)
                        .padding(.bottom)
                        .padding(.top, 48)
                }
                .padding()
            }
            
        }
        .background(Color.white)
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $isShowingSwiftUIView) {
            SampleView()
        }
        .sheet(isPresented: $isShowingUIKitView) {
            SampleVCRepresentable()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
