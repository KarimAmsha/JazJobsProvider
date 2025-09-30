//
//  PopupObserverView.swift
//  Wishy
//
//  Created by Karim OTHMAN on 5.05.2025.
//

import SwiftUI

struct PopupObserverView: View {
    @Binding var message: String?
    var type: AlertType
    @EnvironmentObject var appRouter: AppRouter

    var body: some View {
        Color.clear
            .onChange(of: message) { newValue in
                if let newValue = newValue {
                    switch type {
                    case .success:
                        appRouter.toggleAppPopup(.alertSuccess("", newValue))
                    case .error:
                        appRouter.toggleAppPopup(.alertError("", newValue))
                    case .info:
                        appRouter.toggleAppPopup(.alertInfo("", newValue))
                    }
                }
            }
    }
}

