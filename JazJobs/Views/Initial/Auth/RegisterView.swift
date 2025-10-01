////
////  RegisterView.swift
////  Wishy
////
////  Created by Karim Amsha on 27.04.2024.
////
import SwiftUI
import PopupView
import FirebaseMessaging
import MapKit
import Combine

struct RegisterView: View {
    @State var name: String = ""
    @State var email: String = ""
    @State var mobile: String = ""
    @State var isEditing: Bool = true
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settings: UserSettings
    @Environment(\.presentationMode) var presentationMode
    @State var completePhoneNumber = ""
    @StateObject private var viewModel = AuthViewModel(errorHandling: ErrorHandling())
    @State private var userLocation: CLLocationCoordinate2D? = nil

    // Country/state lifted for MobileView + sheet
    @State var countryCode : String = "+966"
    @State var countryFlag : String = "🇸🇦"
    @State var countryPattern : String = "## ### ####"
    @State var countryLimit : Int = 17

    let counrties: [CPData] = Bundle.main.decode("CountryNumbers.json")
    @State private var searchCountry: String = ""

    @Binding var loginStatus: LoginStatus
    @FocusState private var keyIsFocused: Bool
    @State var presentSheet = false
    @EnvironmentObject var appRouter: AppRouter

    // New: user type
    @State private var selectedUserType: UserType = .personal

    var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {

                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(LocalizedStringKey.welcome)
                            .customFont(weight: .bold, size: 24)
                            .foregroundColor(.primaryBlack())
                        Text(LocalizedStringKey.secondWelcome)
                            .customFont(weight: .regular, size: 12)
                            .foregroundColor(.gray999999())
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // User type
                    VStack(alignment: .leading, spacing: 8) {
                        Text(LocalizedStringKey.userType)
                            .customFont(weight: .medium, size: 12)
                            .foregroundColor(.primaryBlack())

                        HStack(spacing: 10) {
                            userTypeButton(type: .personal, title: LocalizedStringKey.personal)
                            userTypeButton(type: .company, title: LocalizedStringKey.company)
                        }
                    }

                    // Full name
                    VStack(alignment: .leading, spacing: 4) {
                        Text(LocalizedStringKey.fullName)
                            .customFont(weight: .medium, size: 12)
                            .foregroundColor(.primaryBlack())

                        TextField("", text: $name)
                            .placeholder(when: name.isEmpty) {
                                Text(LocalizedStringKey.fullName)
                                    .foregroundColor(.gray999999())
                            }
                            .customFont(weight: .regular, size: 14)
                            .foregroundColor(.black1C2433())
                            .padding(.horizontal, 16)
                            .padding(.vertical, 18)
                            .roundedBackground(cornerRadius: 8, strokeColor: .gray.opacity(0.2), lineWidth: 1)
                    }

                    // Mobile (original MobileView signature)
                    MobileView(
                        mobile: $mobile,
                        presentSheet: $presentSheet
                    )

                    // Email
                    VStack(alignment: .leading, spacing: 4) {
                        Text(LocalizedStringKey.email)
                            .customFont(weight: .medium, size: 12)
                            .foregroundColor(.primaryBlack())

                        TextField("", text: $email)
                            .placeholder(when: email.isEmpty) {
                                Text("example@email.com")
                                    .foregroundColor(.gray999999())
                            }
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .textContentType(.emailAddress)
                            .customFont(weight: .regular, size: 14)
                            .foregroundColor(.black1C2433())
                            .padding(.horizontal, 16)
                            .padding(.vertical, 18)
                            .roundedBackground(cornerRadius: 8, strokeColor: .gray.opacity(0.2), lineWidth: 1)
                    }

                    Spacer(minLength: 8)

                    // Loader while registering
                    if viewModel.isLoading {
                        LoadingView()
                    }

                    // Register button
                    Button {
                        Messaging.messaging().token { token, error in
                            if let error = error {
                                appRouter.toggleAppPopup(.alertError(LocalizedStringKey.error, error.localizedDescription))
                            } else if let token = token {
                                register(fcmToken: token)
                            }
                        }
                    } label: {
                        Text(LocalizedStringKey.register)
                    }
                    .buttonStyle(GradientPrimaryButton(fontSize: 16, fontWeight: .bold, background: Color.primaryGradientColor(), foreground: .white, height: 48, radius: 12))
                    .disabled(!isFormValid || viewModel.isLoading)

                    // Already have account?
                    HStack {
                        Text(LocalizedStringKey.youHaveAccount)
                            .customFont(weight: .regular, size: 12)
                            .foregroundColor(.gray999999())
                        Spacer()
                        Button {
                            loginStatus = .login
                        } label: {
                            Text(LocalizedStringKey.loginNow)
                                .customFont(weight: .medium, size: 14)
                                .foregroundColor(.primary())
                        }
                    }
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: geometry.size.height)
            }
        }
        .padding(24)
        .toolbarColorScheme(.light, for: .navigationBar)
        .toolbarBackground(Color.white,for: .navigationBar)
        .dismissKeyboardOnTap()
        .background(Color.white)
        .sheet(isPresented: $presentSheet) {
            NavigationStack {
                List(filteredResorts) { country in
                    HStack {
                        Text(country.flag)
                        Text(country.name)
                            .font(.headline)
                        Spacer()
                        Text(country.dial_code)
                            .foregroundColor(.secondary)
                    }
                    .onTapGesture {
                        self.countryFlag = country.flag
                        self.countryCode = country.dial_code
                        self.countryPattern = country.pattern
                        self.countryLimit = country.limit
                        // إعادة ضبط الرقم ليتوافق مع النمط الجديد
                        self.mobile = ""
                        presentSheet = false
                        searchCountry = ""
                    }
                }
                .listStyle(.plain)
                .searchable(text: $searchCountry, prompt: LocalizedStringKey.yourCountry)
            }
            .environment(\.layoutDirection, .leftToRight)
        }
        .navigationBarBackButtonHidden()
        .background(Color.background())
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(LocalizedStringKey.createNewAccount)
                            .customFont(weight: .bold, size: 20)
                        
                        Text(LocalizedStringKey.registerHint)
                            .customFont(weight: .regular, size: 12)
                    }
                    .foregroundColor(Color.primaryBlack())
                }
            }
        }
        .onAppear {
            // Use the user's current location if available
//            if let userLocation = LocationManager.shared.userLocation {
//                self.userLocation = userLocation
//            }
        }
        .overlay(
            MessageAlertObserverView(
                message: $viewModel.errorMessage,
                alertType: .constant(.error)
            )
        )
    }

    // Segmented buttons
    @ViewBuilder
    private func userTypeButton(type: UserType, title: String) -> some View {
        Button {
            selectedUserType = type
        } label: {
            Text(title)
                .customFont(weight: .medium, size: 14)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .foregroundColor(selectedUserType == type ? .white : .primaryBlack())
                .background((selectedUserType == type ? Color.primary() : Color.gray.opacity(0.12)))
                .cornerRadius(12)
        }
    }

    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        isValidEmail(email) &&
        !mobile.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func isValidEmail(_ email: String) -> Bool {
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: email)
    }
    
    private func getCompletePhoneNumber() -> String {
        completePhoneNumber = "\(countryCode)\(mobile)".replacingOccurrences(of: " ", with: "")
        
        // Remove "+" from countryCode
        if countryCode.hasPrefix("+") {
            completePhoneNumber = completePhoneNumber.replacingOccurrences(of: countryCode, with: String(countryCode.dropFirst()))
        }
        
        return completePhoneNumber
    }

    var filteredResorts: [CPData] {
        if searchCountry.isEmpty {
            return counrties
        } else {
            return counrties.filter { $0.name.contains(searchCountry) }
        }
    }
}

#Preview {
    LoginView(loginStatus: .constant(.login))
        .environmentObject(AppState())
        .environmentObject(UserSettings())
}

extension RegisterView {
    func register(fcmToken: String) {
        appState.phoneNumber = getCompletePhoneNumber()
        
        var params: [String: Any] = [
            "phone_number": getCompletePhoneNumber(),
            "os": "IOS",
            "fcmToken": fcmToken,
            "lat": userLocation?.latitude ?? 0.0,
            "lng": userLocation?.longitude ?? 0.0,
            // New fields
            "full_name": name,
            "email": email,
            "type": selectedUserType.value
        ]

        // Check if user location is available
        if let userLocation = userLocation {
            let dispatchGroup = DispatchGroup()
            dispatchGroup.enter()
            
            Utilities.getAddress(for: userLocation) { address in
                params["address"] = address
                dispatchGroup.leave()
            }
            
            dispatchGroup.notify(queue: .main) {
                self.continueRegistration(with: params)
            }
        } else {
            // No user location available, proceed with registration without address
            continueRegistration(with: params)
        }
    }

    private func continueRegistration(with params: [String: Any]) {
        viewModel.registerUser(params: params) { id, token in
            appState.userId = id
            UserSettings.shared.token = token
            // الانتقال لرفع الصور
            loginStatus = .identityConfirmation(token)
        }
    }
}

