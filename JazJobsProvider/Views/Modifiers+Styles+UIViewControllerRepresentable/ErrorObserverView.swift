//
//  ErrorObserverView.swift
//  Wishy
//
//  Created by Karim OTHMAN on 5.05.2025.
//

import SwiftUI

struct ErrorObserverView: View {
    @Binding var errorMessage: String?
    @EnvironmentObject var appRouter: AppRouter

    var body: some View {
        Color.clear // حتى تقبلها `.overlay`
            .onChange(of: errorMessage) { newValue in
                if let message = newValue {
                    appRouter.toggleAppPopup(.alertError("", message))
                }
            }
    }
}
