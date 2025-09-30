//
//  SMSVerificationView.swift
//  Wishy
//
//  Created by Karim Amsha on 27.04.2024.
//

import SwiftUI
import Combine
import PopupView

struct SMSVerificationView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settings: UserSettings
    @State private var passCodeFilled = false
    @Environment(\.presentationMode) var presentationMode
    @State private var totalSeconds = 300
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    var minutes: Int {
        return totalSeconds / 60
    }

    var seconds: Int {
        return totalSeconds % 60
    }
    var id: String
    var mobile: String
    @State var code = ""
    @StateObject private var viewModel = AuthViewModel(errorHandling: ErrorHandling())
    private let errorHandling = ErrorHandling()
    @Binding var loginStatus: LoginStatus
    @EnvironmentObject var appRouter: AppRouter

    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedStringKey.enterOTP)
                    .customFont(weight: .medium, size: 12)
                    .foregroundColor(.primaryBlack())

                HStack {
                    Spacer()
                    OtpFormFieldView(combinedPins: $code)
                        .disabled(viewModel.isLoading)
                    Spacer()
                }
                .environment(\.layoutDirection, .leftToRight)
            }

            VStack(alignment: .center, spacing: 10) {
                Text(formattedTime(minutes: minutes, seconds: seconds))
                    .customFont(weight: .regular, size: 14)
                    .foregroundColor(.grayA4ACAD())
                    .onReceive(timer) { _ in
                        if totalSeconds > 0 {
                            totalSeconds -= 1
                        } else {
                            resendCode()
                        }
                    }
                
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text(LocalizedStringKey.youDontReceiveCode)
                        .customFont(weight: .regular, size: 12)
                        .foregroundColor(.grayA4ACAD())

                    Button {
                        resendCode()
                    } label: {
                        Text(LocalizedStringKey.requestNewCode)
                    }
                    .buttonStyle(CustomButtonStyle(fontSize: 14, fontWeight: .bold, background: .clear, foreground: .primaryBlack()))
                }
            }
            
            // Show a loader while registering
            if viewModel.isLoading {
                LoadingView()
            }

            Spacer()
            
            Button {
//                loginStatus = .profile("", nil)
                verify()
            } label: {
                Text(LocalizedStringKey.verifyCode)
            }
            .buttonStyle(GradientPrimaryButton(fontSize: 16, fontWeight: .bold, background: Color.primaryGradientColor(), foreground: .white, height: 48, radius: 12))
            .disabled(viewModel.isLoading)

        }
        .padding(24)
        .dismissKeyboardOnTap()
        .navigationBarBackButtonHidden()
        .background(Color.background())
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HStack {
                    Image("ic_gift")

                    VStack(alignment: .leading, spacing: 2) {
                        Text(LocalizedStringKey.enterOTP)
                            .customFont(weight: .bold, size: 20)
                        
                        Text(LocalizedStringKey.smsVerHint)
                            .customFont(weight: .regular, size: 12)
                    }
                    .foregroundColor(Color.primaryBlack())
                }
            }
        }
        .overlay(
            MessageAlertObserverView(
                message: $viewModel.errorMessage,
                alertType: .constant(.error)
            )
        )
    }
    
    private func formattedTime(minutes: Int, seconds: Int) -> String {
        let date = Date(timeIntervalSinceReferenceDate: TimeInterval(minutes * 60 + seconds))
        let formatter = DateFormatter()

        // Force English locale
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "mm:ss"

        return formatter.string(from: date)
    }
}

struct SMSVerificationView_Previews: PreviewProvider {
    static var previews: some View {
        SMSVerificationView(id: "", mobile: "", loginStatus: .constant(.verification))
            .environmentObject(AppState())
            .environmentObject(UserSettings())
    }
}

extension SMSVerificationView {
    private func verify() {
        var lastPathComponent = ""
        if let referalUrl = appState.referalUrl {
            lastPathComponent = referalUrl.lastPathComponent
        }

        let params = [
            "id": appState.userId,
            "verify_code": code,
            "phone_number": appState.phoneNumber,
            "by": lastPathComponent
        ] as [String : Any]

        viewModel.verify(params: params) { profileCompleted, token in
            if profileCompleted {
                settings.loggedIn = true
                return
            }
            loginStatus = .profile(appState.token)
        }
    }
    
    private func resendCode() {
        let params = [
            "id": appState.userId
        ] as [String : Any]

        viewModel.resend(params: params) {}
    }
}
