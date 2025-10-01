//
//  SplashView.swift
//  Wishy
//
//  Created by Karim Amsha on 27.04.2024.
//

import SwiftUI

struct SplashView: View {
    @State private var logoOpacity: Double = 0.0

    var body: some View {
        ZStack {
            // Brand gradient from Color+Extensions (05659E -> 04517E)
            Color.primaryGradientColor()
                .ignoresSafeArea()

            Image("ic_logo")
                .opacity(logoOpacity)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 3)) {
                self.logoOpacity = 1.0
                // إذا حابب تنتقل تلقائيًا بعد الأنيميشن:
                // UserSettings.shared.loggedIn = true
            }
        }
    }
}

#Preview {
    SplashView()
}
