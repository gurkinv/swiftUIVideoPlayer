//
//  ContentView.swift
//  swiftuiVideoPlayer
//
//  Created by Василий Гуркин on 13.08.2024.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let safeArea = proxy.safeAreaInsets
            
            MainView(size: size, safeArea: safeArea).ignoresSafeArea()
                .preferredColorScheme(.dark)
            
        }
    }
}

#Preview {
    ContentView()
}
