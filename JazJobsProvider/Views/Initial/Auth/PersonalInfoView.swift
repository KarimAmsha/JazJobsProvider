//
//  PersonalInfoView.swift
//  Wishy
//
//  Created by Karim Amsha on 27.04.2024.
//

import SwiftUI
import PopupView
import MapKit

struct PersonalInfoView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var appRouter: AppRouter
    @State private var name = ""
    @State private var email = ""
    @StateObject private var viewModel = UserViewModel(errorHandling: ErrorHandling())
    @State private var userLocation: CLLocationCoordinate2D? = nil
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 24.7136, longitude: 46.6753),
        span: MKCoordinateSpan(latitudeDelta: 5, longitudeDelta: 5)
    )
    @State private var isShowingDatePicker = false
    @State private var dateStr: String = ""
    @State private var date: Date = Date()

    // MARK: - Multi-step states
    @State private var currentStep: Int = 0 // 0: Work & Experiences, 1: Overview, 2: Address

    // Step 0: Work & Experiences
    @State private var workField: String = ""
    @State private var experiences: [String] = [""]

    // Step 1: Overview
    @State private var overviewText: String = ""

    // Step 2: Address details
    @State private var address: String = ""
    @State private var isShowingMap = false
    @State private var country: String = ""
    @State private var city: String = ""
    @State private var streetName: String = ""
    @State private var buildingName: String = ""
    @State private var buildingNo: String = ""
    @State private var floorNo: String = ""

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 0) {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {

                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text(LocalizedStringKey.completeProfile)
                                .customFont(weight: .bold, size: 24)
                                .foregroundColor(.primaryBlack())
                            Text(LocalizedStringKey.completeProfileMessage)
                                .customFont(weight: .regular, size: 12)
                                .foregroundColor(.gray999999())
                        }

                        // Tabs
                        Picker("", selection: $currentStep) {
                            Text(LocalizedStringKey.workExperiences).tag(0)
                            Text(LocalizedStringKey.personalProfile).tag(1)
                            Text(LocalizedStringKey.address).tag(2)
                        }
                        .pickerStyle(.segmented)

                        VStack(alignment: .leading, spacing: 0) {
                            if currentStep == 0 {
                                workAndExperiencesStep
                            } else if currentStep == 1 {
                                overviewStep
                            } else {
                                addressStep
                            }

                            // يثبت المحتوى أعلى ويمنع تمدد لا نهائي
                            Spacer(minLength: 0)
                        }

                        if viewModel.isLoading {
                            LoadingView()
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    // لا تربط minHeight بارتفاع GeometryReader داخل ScrollView لتفادي حلقات التخطيط
                }

                // Bottom buttons
                HStack(spacing: 12) {
                    if currentStep > 0 {
                        Button {
                            withAnimation { currentStep -= 1 }
                        } label: {
                            Text(LocalizedStringKey.back)
                        }
                        .buttonStyle(PrimaryButton(fontSize: 16, fontWeight: .bold, background: .primaryLightActive(), foreground: .primary(), height: 48, radius: 12))
                        .disabled(viewModel.isLoading)
                    }

                    Button {
                        withAnimation {
                            if currentStep < 2 {
                                currentStep += 1
                            } else {
                                update()
                            }
                        }
                    } label: {
                        Text(LocalizedStringKey.next)
                    }
                    .buttonStyle(GradientPrimaryButton(fontSize: 16, fontWeight: .bold, background: Color.primaryGradientColor(), foreground: .white, height: 48, radius: 12))
                    .disabled(viewModel.isLoading)
                }
                .padding([.horizontal, .bottom])
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .dismissKeyboardOnTap()
        .navigationBarBackButtonHidden()
        .background(Color.background())
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(LocalizedStringKey.completeProfile)
                            .customFont(weight: .bold, size: 20)
                        Text(LocalizedStringKey.completeProfileMessage)
                            .customFont(weight: .regular, size: 12)
                    }
                    .foregroundColor(Color.primaryBlack())
                }
            }
        }
        .onAppear {
            // تجنب الشبكة/الموقع أثناء الـ Preview لأنهما قد يسببان تعليق المعاينة
            let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
            if !isPreview {
                getUserData()

                if let userLocation = LocationManager.shared.userLocation {
                    self.userLocation = userLocation
                    region.center = userLocation
                }
            }
        }
        .overlay(
            MessageAlertObserverView(
                message: $viewModel.errorMessage,
                alertType: .constant(.error)
            )
        )
        .popup(isPresented: $isShowingDatePicker) {
            let dateModel = DateTimeModel(pickerMode: .date) { date in
                self.date = date
                dateStr = date.toString(format: "yyyy-MM-dd")
                isShowingDatePicker = false
            } onCancelAction: {
                isShowingDatePicker = false
            }
            
            DateTimePicker(model: dateModel)
        } customize: {
            $0
                .type(.toast)
                .position(.bottom)
                .animation(.spring())
                .closeOnTapOutside(true)
                .closeOnTap(false)
                .backgroundColor(Color.black.opacity(0.80))
                .isOpaque(true)
                .useKeyboardSafeArea(true)
        }
    }
}

#Preview {
    PersonalInfoView()
        .environmentObject(UserSettings())
        .environmentObject(AppState())
        .environmentObject(AppRouter())
}

extension PersonalInfoView {
    // MARK: - Steps

    private var workAndExperiencesStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedStringKey.workField)
                .customFont(weight: .medium, size: 12)
                .foregroundColor(.primaryBlack())

            ZStack {
                TextField(LocalizedStringKey.showOptions, text: $workField)
                    .placeholder(when: workField.isEmpty) {
                        Text(LocalizedStringKey.showOptions)
                            .foregroundColor(.gray999999())
                    }
                    .customFont(weight: .regular, size: 14)
                    .foregroundColor(.black1C2433())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 18)
                    .roundedBackground(cornerRadius: 8, strokeColor: .primaryBlack(), lineWidth: 1)

                HStack {
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.black1F1F1F())
                        .padding(.trailing, 14)
                }
            }

            Text(LocalizedStringKey.experiences)
                .customFont(weight: .medium, size: 12)
                .foregroundColor(.primaryBlack())

            VStack(spacing: 10) {
                ForEach(experiences.indices, id: \.self) { index in
                    TextField("", text: Binding(
                        get: { experiences[index] },
                        set: { experiences[index] = $0 }
                    ))
                    .placeholder(when: experiences[index].isEmpty) {
                        Text("Experience \(index + 1)")
                            .foregroundColor(.gray999999())
                    }
                    .customFont(weight: .regular, size: 14)
                    .foregroundColor(.black1C2433())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 18)
                    .roundedBackground(cornerRadius: 8, strokeColor: .primaryBlack(), lineWidth: 1)
                }

                Button {
                    experiences.append("")
                } label: {
                    Text(LocalizedStringKey.newExperiences)
                }
                .buttonStyle(PrimaryButton(fontSize: 12, fontWeight: .medium, background: .primaryLightActive(), foreground: .primary(), height: 40, radius: 8))
            }
        }
        .foregroundColor(.black222020())
    }

    private var overviewStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedStringKey.dob)
                .customFont(weight: .medium, size: 12)
                .foregroundColor(.primaryBlack())

            HStack {
                TextField(LocalizedStringKey.dmy, text: $dateStr)
                    .placeholder(when: dateStr.isEmpty) {
                        Text(LocalizedStringKey.dmy)
                            .foregroundColor(.gray999999())
                    }
                    .customFont(weight: .regular, size: 14)
                    .disabled(true)

                Spacer()

                Image("ic_calendar")
                    .foregroundColor(.black)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 18)
            .roundedBackground(cornerRadius: 12, strokeColor: .primaryBlack(), lineWidth: 1)
            .onTapGesture {
                isShowingDatePicker = true
            }

            Text(LocalizedStringKey.fullDescription)
                .customFont(weight: .medium, size: 12)
                .foregroundColor(.primaryBlack())

            TextEditor(text: $overviewText)
                .customFont(weight: .regular, size: 14)
                .foregroundColor(.black121212())
                .padding(.horizontal)
                .padding(.vertical, 14)
                .cornerRadius(12)
                .frame(height: 180)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .inset(by: 0.5)
                        .stroke(Color(red: 0.93, green: 0.93, blue: 0.93), lineWidth: 1)
                )
        }
    }

    private var addressStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedStringKey.address)
                .customFont(weight: .medium, size: 12)
                .foregroundColor(.primaryBlack())

            Button {
                isShowingMap = true
            } label: {
                VStack(spacing: 8) {
                    Text(LocalizedStringKey.chooseLocation)
                        .customFont(weight: .medium, size: 14)
                        .foregroundColor(.primaryBlack())
                    Text(LocalizedStringKey.hint4)
                        .customFont(weight: .regular, size: 11)
                        .foregroundColor(.gray999999())
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, minHeight: 120)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [6]))
                        .foregroundColor(Color.gray.opacity(0.4))
                )
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $isShowingMap) {
                FullMapView(region: $region, isShowingMap: $isShowingMap, address: $address)
            }

            Text(LocalizedStringKey.country)
                .customFont(weight: .medium, size: 12)
                .foregroundColor(.primaryBlack())
            ZStack {
                TextField("", text: $country)
                    .placeholder(when: country.isEmpty) {
                        Text(LocalizedStringKey.country)
                            .foregroundColor(.gray999999())
                    }
                    .customFont(weight: .regular, size: 14)
                    .foregroundColor(.black1C2433())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 18)
                    .roundedBackground(cornerRadius: 8, strokeColor: .primaryBlack(), lineWidth: 1)

                HStack {
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.black1F1F1F())
                        .padding(.trailing, 14)
                }
            }

            Text(LocalizedStringKey.city)
                .customFont(weight: .medium, size: 12)
                .foregroundColor(.primaryBlack())
            ZStack {
                TextField("", text: $city)
                    .placeholder(when: city.isEmpty) {
                        Text(LocalizedStringKey.city)
                            .foregroundColor(.gray999999())
                    }
                    .customFont(weight: .regular, size: 14)
                    .foregroundColor(.black1C2433())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 18)
                    .roundedBackground(cornerRadius: 8, strokeColor: .primaryBlack(), lineWidth: 1)

                HStack {
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.black1F1F1F())
                        .padding(.trailing, 14)
                }
            }

            Text(LocalizedStringKey.streetName)
                .customFont(weight: .medium, size: 12)
                .foregroundColor(.primaryBlack())
            TextField("", text: $streetName)
                .placeholder(when: streetName.isEmpty) {
                    Text(LocalizedStringKey.streetName)
                        .foregroundColor(.gray999999())
                }
                .customFont(weight: .regular, size: 14)
                .foregroundColor(.black1C2433())
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
                .roundedBackground(cornerRadius: 8, strokeColor: .primaryBlack(), lineWidth: 1)

            Text(LocalizedStringKey.buildingName)
                .customFont(weight: .medium, size: 12)
                .foregroundColor(.primaryBlack())
            TextField("", text: $buildingName)
                .placeholder(when: buildingName.isEmpty) {
                    Text(LocalizedStringKey.buildingName)
                        .foregroundColor(.gray999999())
                }
                .customFont(weight: .regular, size: 14)
                .foregroundColor(.black1C2433())
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
                .roundedBackground(cornerRadius: 8, strokeColor: .primaryBlack(), lineWidth: 1)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(LocalizedStringKey.buildingNo)
                        .customFont(weight: .medium, size: 12)
                        .foregroundColor(.primaryBlack())
                    TextField("", text: $buildingNo)
                        .placeholder(when: buildingNo.isEmpty) {
                            Text(LocalizedStringKey.buildingNo)
                                .foregroundColor(.gray999999())
                        }
                        .keyboardType(.numberPad)
                        .customFont(weight: .regular, size: 14)
                        .foregroundColor(.black1C2433())
                        .padding(.horizontal, 16)
                        .padding(.vertical, 18)
                        .roundedBackground(cornerRadius: 8, strokeColor: .primaryBlack(), lineWidth: 1)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(LocalizedStringKey.floorNo)
                        .customFont(weight: .medium, size: 12)
                        .foregroundColor(.primaryBlack())
                    TextField("", text: $floorNo)
                        .placeholder(when: floorNo.isEmpty) {
                            Text(LocalizedStringKey.floorNo)
                                .foregroundColor(.gray999999())
                        }
                        .keyboardType(.numberPad)
                        .customFont(weight: .regular, size: 14)
                        .foregroundColor(.black1C2433())
                        .padding(.horizontal, 16)
                        .padding(.vertical, 18)
                        .roundedBackground(cornerRadius: 8, strokeColor: .primaryBlack(), lineWidth: 1)
                }
            }
        }
    }
}

extension PersonalInfoView {
    private func getUserData() {
        viewModel.fetchUserData {
            name = viewModel.user?.full_name ?? ""
            email = viewModel.user?.email ?? ""
            dateStr = viewModel.user?.formattedDOB ?? ""
            address = viewModel.user?.address ?? ""
        }
    }
    
    private func update() {
        let expString = experiences
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " | ")

        let params: [String: Any] = [
            "email": email,
            "full_name": name,
            "dob": dateStr,
            "full_description": overviewText,
            "work_field": workField,
            "experiences": expString,
            "lat": region.center.latitude,
            "lng": region.center.longitude,
            "address": address,
            "country": country,
            "city": city,
            "street_name": streetName,
            "building_name": buildingName,
            "building_no": buildingNo,
            "floor_no": floorNo
        ]

        viewModel.updateUserData(params: params) { _ in
            settings.loggedIn = true
        }
    }
}
