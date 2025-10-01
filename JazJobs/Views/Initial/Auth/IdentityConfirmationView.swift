//
//  IdentityConfirmationView.swift
//  Wishy
//
//  Created by Karim Amsha on 5.10.2025.
//

import SwiftUI
import PopupView

struct IdentityConfirmationView: View {
    let token: String
    @Binding var loginStatus: LoginStatus

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var appRouter: AppRouter

    // Pickers
    @StateObject private var profilePickerVM = MediaPickerViewModel()
    @StateObject private var idPickerVM = MediaPickerViewModel()

    @State private var isProfilePickerSheetPresented = false
    @State private var isIDPickerSheetPresented = false

    @State private var isUploading = false
    @State private var errorMessage: String?

    var body: some View {
        GeometryReader { geometry in
            // احسب ارتفاع المربعات بحيث يملؤون المساحة المتاحة
            let buttonHeight: CGFloat = 48
            let verticalSpacing: CGFloat = 20
            // هامش تقريبي للعنوان والمسافات الداخلية
            let headerApproxHeight: CGFloat = 80
            // نضيف مسافات إضافية للهوامش الداخلية
            let extraPadding: CGFloat = 40

            let availableHeight = geometry.size.height - headerApproxHeight - buttonHeight - extraPadding - verticalSpacing
            let tileHeight = max(180, availableHeight / 2)

            VStack(spacing: verticalSpacing) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: verticalSpacing) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text(LocalizedStringKey.confirmIdentity)
                                .customFont(weight: .bold, size: 24)
                                .foregroundColor(.primaryBlack())
                            Text(LocalizedStringKey.hint2)
                                .customFont(weight: .regular, size: 12)
                                .foregroundColor(.gray999999())
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        // Profile photo tile (يملأ العرض والارتفاع المحسوب)
                        uploadTile(
                            image: profilePickerVM.selectedImage,
                            systemIcon: "camera.fill",
                            title: LocalizedStringKey.uploadProfilePicture,
                            subtitle: LocalizedStringKey.hint2,
                            height: tileHeight
                        ) {
                            isProfilePickerSheetPresented.toggle()
                        }
                        .popup(isPresented: $isProfilePickerSheetPresented) {
                            FloatingPickerView(
                                isPresented: $isProfilePickerSheetPresented,
                                onChoosePhoto: {
                                    profilePickerVM.choosePhoto()
                                },
                                onTakePhoto: {
                                    profilePickerVM.takePhoto()
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

                        // ID photo tile (يملأ العرض والارتفاع المحسوب)
                        uploadTile(
                            image: idPickerVM.selectedImage,
                            systemIcon: "rectangle.badge.person.crop",
                            title: LocalizedStringKey.uploadIDPicture,
                            subtitle: LocalizedStringKey.hint2,
                            height: tileHeight
                        ) {
                            isIDPickerSheetPresented.toggle()
                        }
                        .popup(isPresented: $isIDPickerSheetPresented) {
                            FloatingPickerView(
                                isPresented: $isIDPickerSheetPresented,
                                onChoosePhoto: {
                                    idPickerVM.choosePhoto()
                                },
                                onTakePhoto: {
                                    idPickerVM.takePhoto()
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

                        if isUploading {
                            LoadingView()
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: geometry.size.height * 0.6, alignment: .top)
                }

                Button {
                    startUpload()
                } label: {
                    Text(LocalizedStringKey.next)
                }
                .buttonStyle(GradientPrimaryButton(fontSize: 16, fontWeight: .bold, background: Color.primaryGradientColor(), foreground: .white, height: buttonHeight, radius: 12))
                .disabled(isUploading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(24)
        .dismissKeyboardOnTap()
        .navigationBarBackButtonHidden()
        .background(Color.background())
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(LocalizedStringKey.confirmIdentity)
                            .customFont(weight: .bold, size: 20)
                        Text(LocalizedStringKey.hint2)
                            .customFont(weight: .regular, size: 12)
                    }
                    .foregroundColor(Color.primaryBlack())
                }
            }
        }
        // Image pickers
        .fullScreenCover(isPresented: $profilePickerVM.isPresentingImagePicker) {
            ImagePicker(sourceType: profilePickerVM.sourceType, completionHandler: profilePickerVM.didSelectImage)
        }
        .fullScreenCover(isPresented: $idPickerVM.isPresentingImagePicker) {
            ImagePicker(sourceType: idPickerVM.sourceType, completionHandler: idPickerVM.didSelectImage)
        }
        .overlay(
            MessageAlertObserverView(
                message: $errorMessage,
                alertType: .constant(.error)
            )
        )
    }

    // MARK: - Views

    @ViewBuilder
    private func uploadTile(image: UIImage?, systemIcon: String, title: String, subtitle: String, height: CGFloat, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [6]))
                    .foregroundColor(Color.gray.opacity(0.4))

                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .clipped()
                        .cornerRadius(12)
                        .padding(0)
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: systemIcon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 36, height: 36)
                            .foregroundColor(.primary())
                        Text(title)
                            .customFont(weight: .medium, size: 14)
                            .foregroundColor(.primaryBlack())
                        Text(subtitle)
                            .customFont(weight: .regular, size: 11)
                            .foregroundColor(.gray999999())
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(maxWidth: .infinity, minHeight: height, maxHeight: height, alignment: .center)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func startUpload() {
        guard let personalImage = profilePickerVM.selectedImage,
              let idImage = idPickerVM.selectedImage else {
            errorMessage = "يرجى رفع كلتا الصورتين أولاً"
            return
        }

        isUploading = true
        let images: [UIImage?] = [personalImage, idImage]
        let userID = appState.userId // تم حفظه في RegisterView بعد التسجيل

        FirestoreService.shared.uploadMultipleImages(images: images, id: userID) { urls, success in
            isUploading = false
            if success {
                // الانتقال للخطوة التالية (الملف الشخصي)
                loginStatus = .profile(token)
            } else {
                errorMessage = "فشل رفع الصور، الرجاء المحاولة لاحقًا"
            }
        }
    }
}

#Preview {
    IdentityConfirmationView(token: "", loginStatus: .constant(.identityConfirmation("")))
        .environmentObject(AppState())
        .environmentObject(UserSettings())
}
