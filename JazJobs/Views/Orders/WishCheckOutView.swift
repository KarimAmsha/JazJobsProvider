//
//  WishCheckOutView.swift
//  Wishy
//
//  Created by Karim Amsha on 15.06.2024.
//

import SwiftUI
import PopupView
import MapKit

struct WishCheckOutView: View {
    // MARK: - State
    @EnvironmentObject var appRouter: AppRouter

    @StateObject private var userViewModel = UserViewModel(errorHandling: ErrorHandling())
    @StateObject private var cartViewModel = CartViewModel(errorHandling: ErrorHandling())
    @StateObject private var orderViewModel = OrderViewModel(errorHandling: ErrorHandling())
    @StateObject private var wishViewModel = WishesViewModel(errorHandling: ErrorHandling())
    @StateObject private var locationManager2 = LocationManager2()

    let wishId: String?

    @State private var isShowingAddress = false
    @State private var addressTitle = ""
    @State private var streetName = ""
    @State private var buildingNo = ""
    @State private var floorNo = ""
    @State private var flatNo = ""
    @State private var servicePlace: PlaceType = .home
    @State private var locations: [Mark] = []

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 24.7136, longitude: 46.6753),
        span: MKCoordinateSpan(latitudeDelta: 5, longitudeDelta: 5)
    )

    @State private var isShowingMap = false
    @State private var userLocation: CLLocationCoordinate2D? = nil
    @State private var currentUserLocation: AddressItem?

    @State private var selectedPurchaseType: PurchaseType = .myself
    @State private var isAddressBook = false
    @State private var coupon: String = ""
    @State private var notes: String = LocalizedStringKey.notes
    @State var placeholderString = LocalizedStringKey.notes

//    @State private var selectedAddress: AddressItem? {
//        didSet {
//            guard let selectedAddress = selectedAddress else { return }
//
//            streetName = selectedAddress.streetName ?? ""
//            floorNo = selectedAddress.floorNo ?? ""
//            buildingNo = selectedAddress.buildingNo ?? ""
//            flatNo = selectedAddress.flatNo ?? ""
//
//            region.center = CLLocationCoordinate2D(
//                latitude: selectedAddress.lat ?? 0,
//                longitude: selectedAddress.lng ?? 0
//            )
//            region.span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
//
//            let newLocation = Mark(
//                title: selectedAddress.title ?? "",
//                coordinate: CLLocationCoordinate2D(
//                    latitude: selectedAddress.lat ?? 0,
//                    longitude: selectedAddress.lng ?? 0
//                ),
//                show: true,
//                imageName: "ic_logo",
//                isUserLocation: false
//            )
//
//            locations.removeAll()
//            locations.append(newLocation)
//        }
//    }

    // MARK: - Body
    var body: some View {
        VStack {
//            ScrollView(showsIndicators: false) {
//                VStack(spacing: 20) {
//                    // فعّل هذا إذا أردت عرض ملخص المنتج الخاص بالأمنية
//                    // WishProductSummarySection(product: wishViewModel.wish?.product_id)
//
//                    AddressSelectionView(
//                        addressTitle: $addressTitle,
//                        streetName: $streetName,
//                        isShowingMap: $isShowingMap,
//                        servicePlace: $servicePlace,
//                        locations: $locations,
//                        region: $region,
//                        isShowingAddress: $isShowingAddress,
//                        userLocation: $userLocation,
//                        purchaseType: $selectedPurchaseType
//                    )
//                    .disabled(orderViewModel.isLoading)
//
//                    NotesView(notes: $notes, placeholder: placeholderString)
//                        .disabled(orderViewModel.isLoading)
//                }
//                .padding()
//            }

//            VStack {
//                if orderViewModel.isLoading {
//                    LoadingView()
//                }
//
//                Button(action: { addOrder() }) {
//                    HStack {
//                        Text("اطلب الان")
//                    }
//                }
//                .buttonStyle(
//                    GradientPrimaryButton(
//                        fontSize: 16,
//                        fontWeight: .bold,
//                        background: Color.primaryGradientColor(),
//                        foreground: .white,
//                        height: 48,
//                        radius: 12
//                    )
//                )
//                .disabled(orderViewModel.isLoading)
//            }
//            .padding()
        }
        .navigationBarBackButtonHidden()
        .background(Color.background())
//        .toolbar {
//            ToolbarItem(placement: .navigationBarLeading) {
//                HStack {
//                    Button { appRouter.navigateBack() } label: {
//                        Image("ic_back")
//                    }
//
//                    Text(LocalizedStringKey.payment)
//                        .customFont(weight: .bold, size: 20)
//                        .foregroundColor(Color.primaryBlack())
//                }
//            }
//        }
//        .popup(isPresented: $isShowingAddress) {
//            addressPopupContent
//        } customize: {
//            $0
//                .type(.toast)
//                .position(.bottom)
//                .animation(.spring())
//                .closeOnTapOutside(true)
//                .closeOnTap(false)
//                .backgroundColor(Color.black.opacity(0.80))
//                .isOpaque(true)
//                .useKeyboardSafeArea(true)
//        }
//        .overlay(
//            MessageAlertObserverView(
//                message: $orderViewModel.errorMessage,
//                alertType: .constant(.error)
//            )
//        )
//        .overlay(
//            MessageAlertObserverView(
//                message: $cartViewModel.errorMessage,
//                alertType: .constant(.error)
//            )
//        )
//        .onChange(of: locationManager2.location) { _ in
//            if let location = locationManager2.location {
//                currentUserLocation = AddressItem(
//                    streetName: "",
//                    floorNo: "",
//                    buildingNo: "",
//                    flatNo: "",
//                    type: "موقعي الحالي",
//                    createAt: "",
//                    id: "",
//                    title: "موقعي الحالي",
//                    lat: location.coordinate.latitude,
//                    lng: location.coordinate.longitude,
//                    address: locationManager2.address,
//                    userId: "",
//                    discount: 0
//                )
//            }
//        }
//        .onChange(of: selectedPurchaseType) { _ in
//            addressTitle = ""
//            streetName = ""
//            selectedAddress = nil
//        }
//        .onChange(of: servicePlace) { newValue in
//            userViewModel.getAddressByType(type: newValue.rawValue)
//        }
//        .onAppear {
//            wishViewModel.getWish(id: wishId ?? "")
//            userViewModel.getAddressByType(type: servicePlace.rawValue)
//            cartViewModel.cartTotal { }
//            locationManager2.startUpdatingLocation()
//        }
    }

    // MARK: - Popup content extracted to reduce type-check complexity
//    @ViewBuilder
//    private var addressPopupContent: some View {
//        let model: CustomModel<AddressItem> = CustomModel<AddressItem>(
//            title: LocalizedStringKey.addressBook,
//            content: "",
//            items: userViewModel.addressBook ?? [],
//            onSelect: { item in
//                DispatchQueue.main.async {
//                    selectedAddress = item
//                    addressTitle = item.title ?? ""
//                    isShowingAddress = false
//                }
//            }
//        )
//
//        AddressListView(
//            customModel: model,
//            currentUserLocation: $currentUserLocation,
//            isAddressBook: $isAddressBook
//        )
//    }
//}

// MARK: - Actions
//extension WishCheckOutView {
//    func addOrder() {
//        guard let selectedAddress = selectedAddress else {
//            orderViewModel.errorMessage = "الرجاء اختيار عنوان"
//            return
//        }
//
//        let now = Date()
//        let formattedDate = now.formattedDateString()
//        let formattedTime = now.formattedTimeString()
//
//        var params: [String: Any] = [
//            "couponCode": "",
//            "PaymentType": "wish",
//            "dt_date": formattedDate,
//            "dt_time": formattedTime,
//            "address": selectedAddress.address ?? "",
//            "lat": selectedAddress.lat ?? 0.0,
//            "lng": selectedAddress.lng ?? 0.0,
//            "is_address_book": isAddressBook,
//            "OrderType": 3,
//            "wish_id": wishId ?? "",
//            "notes": notes
//        ]
//
//        if isAddressBook {
//            params["address_book"] = selectedAddress.id ?? ""
//        }
//
//        wishViewModel.addOrderWish(params: params) {
//            appRouter.navigate(to: .paymentSuccess)
//        }
//    }
//
//    func checkCartCoupun() {
//        let params: [String: Any] = [
//            "coupon": coupon,
//            "is_address_book": isAddressBook,
//            "address_book": isAddressBook ? (selectedAddress?.id ?? "") : "",
//            "lat": selectedAddress?.lat ?? 0.0,
//            "lng": selectedAddress?.lng ?? 0.0
//        ]
//
//        cartViewModel.checkCartCoupun(params: params)
//    }
//}
//
//// MARK: - UI Sections
//struct WishProductSummarySection: View {
//    let product: Products?
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 10) {
//            Text(LocalizedStringKey.productSummary)
//                .customFont(weight: .bold, size: 15)
//                .foregroundColor(.black121212())
//
//            if let product = product {
//                HStack {
//                    VStack(alignment: .leading) {
//                        Text(product.name ?? "")
//                        HStack {
//                            Text(LocalizedStringKey.quantity)
//                            Text("1")
//                        }
//                    }
//                    Spacer()
//                    VStack(alignment: .leading) {
//                        HStack {
//                            Text(String(format: "%.2f", product.sale_price ?? 0))
//                            Text(LocalizedStringKey.sar)
//                        }
//                    }
//                }
//                .customFont(weight: .regular, size: 15)
//                .foregroundColor(.black121212())
//            }
//        }
//        .padding()
//        .background(Color.gray.opacity(0.1))
//        .cornerRadius(10)
//    }
}
