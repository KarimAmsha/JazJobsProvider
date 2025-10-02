//
//  DismissingKeyboard.swift
//  Khawi
//
//  Created by Karim Amsha on 22.10.2023.
//

import SwiftUI

extension View {
    func dismissKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                            to: nil, from: nil, for: nil)
        }
    }
}
