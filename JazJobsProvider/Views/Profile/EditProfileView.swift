//
//  EditProfileView.swift
//  Wishy
//
//  Created by Karim Amsha on 30.04.2024.
//

import SwiftUI
import PopupView
import MapKit

struct EditProfileView: View {
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var appRouter: AppRouter
    @State private var name = ""
    @State private var email = ""
    @StateObject private var viewModel = UserViewModel(errorHandling: ErrorHandling())
    @State private var userLocation: CLLocationCoordinate2D? = nil
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(
            latitude: 24.7136,
            longitude: 46.6753
        ),
        span: MKCoordinateSpan(
            latitudeDelta: 5,
            longitudeDelta: 5
        )
    )
    @State private var description: String = LocalizedStringKey.specificText
    @State var placeholderString = LocalizedStringKey.specificText
    @State private var isFloatingPickerPresented = false
    @StateObject var mediaPickerViewModel = MediaPickerViewModel()
    @FocusState private var keyIsFocused: Bool
    @State private var isShowingDatePicker = false
    @State private var dateStr: String = ""
    @State private var date: Date = Date()

    private var isImageSelected: Bool {
        mediaPickerViewModel.selectedImage != nil
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 0) {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        // MARK: - Dashed tappable box (change profile picture)
                        VStack(spacing: 10) {
                            circleProfileImageView(size: 72)
                                .shadow(color: .primary().opacity(0.16), radius: 2.5, x: 0, y: 5)

                            Text("قم بالضغط لتغيير صورتك الشخصية")
                                .customFont(weight: .bold, size: 14)
                                .foregroundColor(.primaryBlack())

                            Text("يفضل أن تكون صورة واضحة وتوضح ملامح الشخص للتعرف على شخصيتك بشكل أفضل ...")
                                .customFont(weight: .regular, size: 12)
                                .foregroundColor(.gray999999())
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(style: StrokeStyle(lineWidth: 1, dash: [6]))
                                .foregroundColor(.grayCCCCCC())
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            isFloatingPickerPresented.toggle()
                        }

                        // MARK: - Full name
                        VStack(alignment: .leading, spacing: 8) {
                            Text(LocalizedStringKey.fullName)
                                .customFont(weight: .medium, size: 12)

                            TextField(LocalizedStringKey.fullName, text: $name)
                                .placeholder(when: name.isEmpty) {
                                    Text(LocalizedStringKey.fullName)
                                        .foregroundColor(.gray999999())
                                }
                                .focused($keyIsFocused)
                                .customFont(weight: .regular, size: 14)
                                .accentColor(.primary())
                                .padding(.horizontal, 16)
                                .padding(.vertical, 18)
                                .roundedBackground(cornerRadius: 12, strokeColor: .primaryBlack(), lineWidth: 1)
                        }
                        .foregroundColor(.black222020())

                        // MARK: - Full description (bio)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("الوصف الكامل")
                                .customFont(weight: .medium, size: 12)
                                .foregroundColor(.black222020())

                            ZStack(alignment: .topLeading) {
                                TextEditor(text: $description)
                                    .customFont(weight: .regular, size: 14)
                                    .frame(minHeight: 120, alignment: .topLeading)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 12)
                                    .accentColor(.primary())
                                    .background(Color.white)
                                    .roundedBackground(cornerRadius: 12, strokeColor: .primaryBlack(), lineWidth: 1)

                                if description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    Text(placeholderString)
                                        .customFont(weight: .regular, size: 14)
                                        .foregroundColor(.gray999999())
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 20)
                                }
                            }
                        }

                        Spacer(minLength: 8)

                        if let uploadProgress = viewModel.uploadProgress {
                            // Display the progress view only when upload is in progress
                            LinearProgressView(LocalizedStringKey.loading, progress: uploadProgress, color: .primary())
                        }

                        Button {
                            update()
                        } label: {
                            Text(LocalizedStringKey.saveChanges)
                        }
                        .buttonStyle(GradientPrimaryButton(fontSize: 16, fontWeight: .bold, background: Color.primaryGradientColor(), foreground: .white, height: 48, radius: 12))
                        .disabled(viewModel.isLoading)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: geometry.size.height)
                }
            }
        }
        .dismissKeyboardOnTap()
        .fullScreenCover(isPresented: $mediaPickerViewModel.isPresentingImagePicker, content: {
            ImagePicker(sourceType: mediaPickerViewModel.sourceType, completionHandler: mediaPickerViewModel.didSelectImage)
        })
        .popup(isPresented: $isFloatingPickerPresented) {
            FloatingPickerView(
                isPresented: $isFloatingPickerPresented,
                onChoosePhoto: {
                    mediaPickerViewModel.choosePhoto()
                },
                onTakePhoto: {
                    mediaPickerViewModel.takePhoto()
                }
            )
        } customize: {
            $0
                .type(.toast)
                .position(.bottom)
                .animation(.spring())
                .closeOnTapOutside(false)
                .closeOnTap(false)
                .backgroundColor(.black.opacity(0.5))
        }
        .navigationBarBackButtonHidden()
        .background(Color.background())
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HStack {
                    Button {
                        appRouter.navigateBack()
                    } label: {
                        Image("ic_back")
                    }

                    Text(LocalizedStringKey.editMyProfile)
                        .customFont(weight: .bold, size: 20)
                        .foregroundColor(Color.primaryBlack())
                }
            }
        }
        .onAppear {
            getUserData()

            // Use the user's current location if available
            if let userLocation = LocationManager.shared.userLocation {
                self.userLocation = userLocation
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
    EditProfileView()
        .environmentObject(UserSettings())
        .environmentObject(AppState())
        .environmentObject(AppRouter())
}

extension EditProfileView {
    private func getUserData() {
        viewModel.fetchUserData {
            name = viewModel.user?.full_name ?? ""
            email = viewModel.user?.email ?? ""
            dateStr = viewModel.user?.formattedDOB ?? ""
            description = viewModel.user?.bio ?? description
        }
    }

    private func update() {
        var params: [String: Any] = [
            "email": email,
            "full_name": name,
            "lat": userLocation?.latitude ?? 0.0,
            "lng": userLocation?.longitude ?? 0.0,
            "address": "",
            "dob": dateStr,
            "bio": description
        ]

        // If user selected a new image, upload it to Firebase then send URL
        if let uiImage = mediaPickerViewModel.selectedImage,
           let imageData = uiImage.jpegData(compressionQuality: 0.8) {
            uploadProfileImageToFirebase(imageData: imageData) { result in
                switch result {
                case .success(let downloadURL):
                    params["image"] = downloadURL.absoluteString
                    self.viewModel.updateUserData(params: params) { message in
                        showMessage(message: message)
                    }
                case .failure(let error):
                    self.viewModel.errorMessage = error.localizedDescription
                }
            }
        } else {
            // No image change, just update the other fields
            viewModel.updateUserData(params: params) { message in
                showMessage(message: message)
            }
        }
    }

    // Now uses FirestoreService with progress reporting
    private func uploadProfileImageToFirebase(imageData: Data, completion: @escaping (Result<URL, Error>) -> Void) {
        viewModel.startUpload()
        viewModel.updateUploadProgress(newProgress: 0.0)

        let userId = settings.id ?? UUID().uuidString
        let fileName = "profile_\(Int(Date().timeIntervalSince1970)).jpg"

        FirestoreService.shared.uploadImageData(imageData, id: userId, imageName: fileName, progress: { fraction in
            self.viewModel.updateUploadProgress(newProgress: fraction)
        }, completion: { result in
            // Finish upload and map result to URL
            self.viewModel.finishUpload()
            switch result {
            case .success(let urlString):
                if let url = URL(string: urlString) {
                    completion(.success(url))
                } else {
                    completion(.failure(NSError(domain: "Upload", code: -4, userInfo: [NSLocalizedDescriptionKey: "Invalid download URL"])))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        })
    }

    private func showMessage(message: String) {
        let alertModel = AlertModel(icon: "",
                                    title: "",
                                    message: message,
                                    hasItem: false,
                                    item: nil,
                                    okTitle: LocalizedStringKey.ok,
                                    cancelTitle: LocalizedStringKey.back,
                                    hidesIcon: true,
                                    hidesCancel: true) {
            appRouter.dismissPopup()
            appRouter.navigateBack()
        } onCancelAction: {
            appRouter.dismissPopup()
        }

        appRouter.togglePopup(.alert(alertModel))
    }
}

extension EditProfileView {
    @ViewBuilder
    func circleProfileImageView(size: CGFloat) -> some View {
        if let selectedImage = mediaPickerViewModel.selectedImage {
            Image(uiImage: selectedImage)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
        } else {
            let imageURL = viewModel.user?.image?.toURL()
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .empty:
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFill()
                        .foregroundColor(.grayCCCCCC())
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure(_):
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFill()
                        .foregroundColor(.grayCCCCCC())
                @unknown default:
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFill()
                        .foregroundColor(.grayCCCCCC())
                }
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
        }
    }
}

