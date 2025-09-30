//
//  Binding+Extension.swift
//  Wishy
//
//  Created by Karim OTHMAN on 5.05.2025.
//

import SwiftUI

extension Binding where Value == AlertType? {
    func orDefault(_ fallback: AlertType) -> Binding<AlertType> {
        Binding<AlertType>(
            get: { self.wrappedValue ?? fallback },
            set: { self.wrappedValue = $0 }
        )
    }
}

extension Binding where Value == String? {
    func orDefaultString(_ fallback: String) -> Binding<String> {
        Binding<String>(
            get: { self.wrappedValue ?? fallback },
            set: { self.wrappedValue = $0 }
        )
    }
}
