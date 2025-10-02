//
//  ValidatedTextEditor.swift
//  Wishy
//
//  Created by Karim OTHMAN on 17.05.2025.
//

import SwiftUI

struct ValidatedTextEditor: View {
    @Binding var text: String
    var placeholder: String = "أدخل نصًا هنا..."
    var isRequired: Bool = true
    var maxCharacters: Int = 500

    @State private var showError: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 12)
                }

                TextEditor(text: $text)
                    .padding(8)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .inset(by: 0.5)
                            .stroke(Color.black121212(), lineWidth: 1)
                    )
                    .frame(height: 160)
                    .onChange(of: text) { _ in
                        validate()
                    }
            }

            if showError {
                Text("هذا الحقل مطلوب ولا يجب أن يتجاوز \(maxCharacters) حرف.")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .onAppear {
            validate()
        }
    }

    private func validate() {
        if isRequired {
            showError = text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || text.count > maxCharacters
        } else {
            showError = text.count > maxCharacters
        }
    }
}
