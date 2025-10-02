import SwiftUI
import PopupView
import MapKit
import TamaraSDK
import PassKit

enum PurchaseType: String, CaseIterable, Identifiable {
    case myself = "شخصي"
    case friend = "لصديق"

    var id: String { self.rawValue }
}

enum PaymentOption: String, CaseIterable, Identifiable {
    case hyperpay, tamara, cash

    var id: String { self.rawValue }
    var displayName: String {
        switch self {
        case .hyperpay: return "الدفع الإلكتروني (بطاقة/أبل باي)"
        case .tamara: return "تمارا (ادفع لاحقًا)"
        case .cash: return "الدفع عند الاستلام"
        }
    }
}

enum HyperpayBrand: Int, CaseIterable, Identifiable {
    case visa = 1
    case master = 2
    case mada = 3
    case apple = 4

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .visa: return "VISA"
        case .master: return "MASTER"
        case .mada: return "MADA"
        case .apple: return "APPLEPAY"
        }
    }

    static func from(string: String) -> HyperpayBrand {
        switch string.uppercased() {
        case "MADA": return .mada
        case "APPLEPAY": return .apple
        case "MASTER", "MASTERCARD": return .master
        default: return .visa
        }
    }

    /// ترجع الرقم المناسب لإرساله للداتابيس حسب المطلوب (1 للفيزا أو الماستر، 2 للمدى، 3 للأبل باي)
    var dbValue: Int {
        switch self {
        case .visa, .master: return 1
        case .mada: return 2
        case .apple: return 3
        }
    }

    /// أيقونات رمزية
    var iconName: String {
        switch self {
        case .visa: return "creditcard"
        case .master: return "creditcard.fill"
        case .mada: return "creditcard.and.123"
        case .apple: return "applelogo"
        }
    }
}

struct CheckoutView: View {
    @EnvironmentObject var appRouter: AppRouter
    @StateObject var viewModel = OrderViewModel(errorHandling: ErrorHandling())
    @State private var isShowingAddress = false
    @StateObject private var userViewModel = UserViewModel(errorHandling: ErrorHandling())
    @State private var addressTitle = ""
    @State private var streetName = ""
    @State private var buildingNo = ""
    @State private var floorNo = ""
    @State private var flatNo = ""
    @State private var servicePlace: PlaceType = .home
    @State private var locations: [Mark] = []
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
    @State private var isShowingMap = false
    @State private var userLocation: CLLocationCoordinate2D? = nil
    @StateObject private var cartViewModel = CartViewModel(errorHandling: ErrorHandling())
    let cartItems: CartItems?
    @StateObject var orderViewModel = OrderViewModel(errorHandling: ErrorHandling())
    @State var currentUserLocation: AddressItem?
    @StateObject private var locationManager2 = LocationManager2()
    @State private var selectedPurchaseType: PurchaseType = .myself
    @State private var isAddressBook = false
    @State private var coupon: String = ""
    @State private var notes: String = LocalizedStringKey.notes
    @State var placeholderString = LocalizedStringKey.notes
    @StateObject private var paymentViewModel = PaymentViewModel()
    @State private var showTamaraPayment = false
    @State private var checkoutUrl = ""
    @State var tamaraViewModel: TamaraWebViewModel? = nil
    @State private var selectedPayment: PaymentOption = .hyperpay
    @State private var selectedBrand: HyperpayBrand = .mada
    @State private var currentHyperpayId: String?
    @State private var showBrandSheet = false

    @State private var showApplePaySheet = false
    @State private var applePayCheckoutId: String?
    @State private var applePayAmount: Double = 0.0
    let canShowApplePay: Bool = PKPaymentAuthorizationViewController.canMakePayments(usingNetworks: [.visa, .masterCard, .mada])

    // رسالة موحدة لعدم وجود مبلغ صالح
    private let invalidAmountMessage = "لا يوجد مبلغ صالح للدفع"

    @State private var selectedAddress: AddressItem? {
        didSet {
            // Update the region and other address-related fields when a new address is selected
            if let selectedAddress = selectedAddress {
                streetName = selectedAddress.streetName ?? ""
                floorNo = selectedAddress.floorNo ?? ""
                buildingNo = selectedAddress.buildingNo ?? ""
                flatNo = selectedAddress.flatNo ?? ""
                
                // Update the region based on the selected address coordinates
                region.center = CLLocationCoordinate2D(latitude: selectedAddress.lat ?? 0, longitude: selectedAddress.lng ?? 0)
                region.span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                
                // Append a new Mark with the selected address coordinates and title
                let newLocation = Mark(
                    title: selectedAddress.title ?? "",
                    coordinate: CLLocationCoordinate2D(latitude: selectedAddress.lat ?? 0, longitude: selectedAddress.lng ?? 0),
                    show: true,
                    imageName: "ic_logo",
                    isUserLocation: false
                )

                locations.removeAll()
                locations.append(newLocation)
            }
        }
    }
        
    var body: some View {
        VStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    ProductSummarySection(products: cartItems?.results)

                    PurchaseTypeSection(purchaseType: $selectedPurchaseType)
                        .disabled(orderViewModel.isLoading)

                    AddressSelectionView(addressTitle: $addressTitle, streetName: $streetName, isShowingMap: $isShowingMap, servicePlace: $servicePlace, locations: $locations, region: $region, isShowingAddress: $isShowingAddress, userLocation: $userLocation, purchaseType: $selectedPurchaseType)
                        .disabled(orderViewModel.isLoading)

                    NotesView(notes: $notes, placeholder: placeholderString)
                        .disabled(orderViewModel.isLoading)

                    if let cartTotal = cartViewModel.cartTotal {
                        OrderSummarySection(cartTotal: cartTotal)
                    }
                    
                    PaymentSection(
                        selectedPayment: $selectedPayment,
                        selectedBrand: $selectedBrand,
                        showBrandSheet: $showBrandSheet,
                        canShowApplePay: canShowApplePay,
                        isDisabled: orderViewModel.isLoading,
                        amount: cartViewModel.cartTotal?.final_total ?? 0.0
                    )
                }
                .padding()
            }
            VStack {
                if orderViewModel.isLoading {
                    LoadingView()
                }
                
                checkoutButton()
                    .disabled(orderViewModel.isLoading)
            }
            .padding()
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

                    Text(LocalizedStringKey.payment)
                        .customFont(weight: .bold, size: 20)
                        .foregroundColor(Color.primaryBlack())
                }
            }
        }
        .popup(isPresented: $isShowingAddress) {
            let model = CustomModel(
                title: LocalizedStringKey.addressBook,
                content: "",
                items: userViewModel.addressBook ?? [],
                onSelect: { item in
                    DispatchQueue.main.async {
                        selectedAddress = item
                        addressTitle = item.title ?? ""
                        
                        isShowingAddress = false
                    }
            })
            
            AddressListView(customModel: model, currentUserLocation: $currentUserLocation, isAddressBook: $isAddressBook)

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
        .overlay(
            MessageAlertObserverView(
                message: $orderViewModel.errorMessage,
                alertType: .constant(.error)
            )
        )
        .overlay(
            MessageAlertObserverView(
                message: $cartViewModel.errorMessage,
                alertType: .constant(.error)
            )
        )
        .onChange(of: locationManager2.location) { value in
            if let location = locationManager2.location {
                print("New Location: \(location)")
                currentUserLocation = AddressItem(
                    streetName: "",
                    floorNo: "",
                    buildingNo: "",
                    flatNo: "",
                    type: "موقعي الحالي",
                    createAt: "",
                    id: "",
                    title: "موقعي الحالي",
                    lat: location.coordinate.latitude,
                    lng: location.coordinate.longitude,
                    address: locationManager2.address,
                    userId: "",
                    discount: 0
                )
            }
        }
        .overlay(
            MessageAlertObserverView(
                message: $paymentViewModel.errorMessage,
                alertType: .constant(.error)
            )
        )
        .overlay(
            MessageAlertObserverView(
                message: $orderViewModel.errorMessage,
                alertType: .constant(.error)
            )
        )
        .onChange(of: selectedPurchaseType) { _ in
            addressTitle = ""
            streetName = ""
            selectedAddress = nil
        }
        .fullScreenCover(isPresented: $showTamaraPayment) {
            if let url = URL(string: checkoutUrl) {
                SafariView(url: url) { redirectedURL in
                }
            }
        }
        .onAppear {
            userViewModel.getAddressByType(type: servicePlace.rawValue)
            cartViewModel.cartTotal {
                //
            }
            cartViewModel.getCartItems()
            locationManager2.startUpdatingLocation()
        }
    }
    
    @ViewBuilder
    func checkoutButton() -> some View {
        let amountText: String = {
            if let amount = cartViewModel.cartTotal?.final_total {
                return String(format: "%.2f ﷼", amount)
            }
            return ""
        }()

        if selectedPayment == .hyperpay,
           selectedBrand == .apple,
           canShowApplePay,
           let amount = cartViewModel.cartTotal?.final_total,
           amount > 0
        {
        } else {
            // باقي وسائل الدفع (الزر العادي)
            Button(action: {
                orderViewModel.errorMessage = nil

                // تحقق من المبلغ
                guard let amount = cartViewModel.cartTotal?.final_total, amount > 0 else {
                    orderViewModel.errorMessage = invalidAmountMessage
                    return
                }

                switch selectedPayment {
                case .cash:
                    addOrder()
                case .tamara:
                    tamaraCheckout()
                case .hyperpay:
                    // تحقق من المستخدم لعمليات الدفع الإلكتروني
                    guard validateUserForOnlinePayment() else { return }
                }
            }) {
                let buttonLabel: some View = HStack {
                    if selectedPayment == .hyperpay {
                        Image(systemName: "creditcard")
                        Text("ادفع إلكترونيًا")
                    } else if selectedPayment == .tamara {
                        Image(systemName: "cart.fill")
                        Text("ادفع عبر تمارا")
                    } else {
                        Image(systemName: "banknote")
                        Text("الدفع عند الاستلام")
                    }
                    Spacer()
                    if !amountText.isEmpty {
                        Text(amountText)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.85))
                    }
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                buttonLabel
            }
            .buttonStyle(
                GradientPrimaryButton(
                    fontSize: 16,
                    fontWeight: .bold,
                    background: Color.primaryGradientColor(),
                    foreground: .white,
                    height: 48,
                    radius: 12
                )
            )
            .disabled(orderViewModel.isLoading)
        }
    }
}

struct ProductSummarySection: View {
    let products: [CartProduct]?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(LocalizedStringKey.productSummary)
                .customFont(weight: .bold, size: 15)
                .foregroundColor(.black121212())

            if let products = products {
                ForEach(products.indices, id: \.self) { index in
                    let item = products[index]
                    HStack {
                        VStack(alignment: .leading) {
                            Text(item.name ?? "")
                            
                            if let variationName = item.variation_name, !variationName.isEmpty {
                                Text("النوع: \(variationName)")
                                    .customFont(weight: .regular, size: 14)
                                    .foregroundColor(.gray)
                            }

                            HStack {
                                Text(LocalizedStringKey.quantity)
                                Text(item.qty?.toString() ?? "")
                            }
                        }
                        Spacer()
                        VStack(alignment: .leading) {
                            HStack {
                                Text(String(format: "%.2f", item.sale_price ?? 0))
                                Text(LocalizedStringKey.sar)
                            }
                        }
                    }
                    .customFont(weight: .regular, size: 15)
                    .foregroundColor(.black121212())
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

struct CheckboxButton: View {
    let title: String
    @Binding var isChecked: Bool
    @Binding var other1: Bool
    @Binding var other2: Bool
    
    var body: some View {
        Button(action: {
            if !isChecked {
                isChecked = true
                other1 = false
                other2 = false
            }
        }) {
            HStack(spacing: 10) {
                Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(isChecked ? .primary() : .gray595959())
                Text(title)
                    .font(.body)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct OrderSummarySection: View {
    let cartTotal: CartTotal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(LocalizedStringKey.orderSummary)
                .customFont(weight: .bold, size: 15)
                .foregroundColor(.black121212())

            if let tax = cartTotal.tax {
                orderSummaryRow(title: LocalizedStringKey.cartTotalTax, amount: tax)
            }

            if let totalPrice = cartTotal.total_price {
                orderSummaryRow(title: LocalizedStringKey.cartTotalTotalPrice, amount: totalPrice)
            }
  
            if let finalTotal = cartTotal.final_total {
                orderSummaryRow(title: LocalizedStringKey.cartTotalFinalTotal, amount: finalTotal)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
    
    private func orderSummaryRow(title: String, amount: Double) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text("\(LocalizedStringKey.sar) \(amount, specifier: "%.2f")")
                .environment(\.locale, .init(identifier: "en_US"))
        }
        .customFont(weight: title == LocalizedStringKey.cartTotalFinalTotal ? .bold : .regular, size: 15)
        .foregroundColor(.black121212())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CheckoutView(cartItems: nil)
        }
    }
}

struct AddressSelectionView: View {
    @Binding var addressTitle: String
    @Binding var streetName: String
    @Binding var isShowingMap: Bool
    @Binding var servicePlace: PlaceType
    @Binding var locations: [Mark]
    @Binding var region: MKCoordinateRegion
    @Binding var isShowingAddress: Bool
    @Binding var userLocation: CLLocationCoordinate2D?
    @Binding var purchaseType: PurchaseType

    @State private var isRotating = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(LocalizedStringKey.yourLocation)
                .customFont(weight: .bold, size: 15)
                .foregroundColor(.black121212())

            if purchaseType == .friend {
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizedStringKey.address)
                        .customFont(weight: .regular, size: 12)
                        .foregroundColor(.black1F1F1F())
                    CustomTextField(text: $addressTitle, placeholder: LocalizedStringKey.address, textColor: .black4E5556(), placeholderColor: .grayA4ACAD())
                }
            } else {
                if servicePlace != .currentLocation {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(LocalizedStringKey.selectAddress)
                            .customFont(weight: .regular, size: 12)
                            .foregroundColor(.black1F1F1F())
                        ZStack {
                            CustomTextField(text: $addressTitle, placeholder: LocalizedStringKey.selectAddress, textColor: .black4E5556(), placeholderColor: .grayA4ACAD())
                                .disabled(true)
                            HStack {
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.gray8F8F8F())
                                    .padding()
                            }
                        }
                    }
                    .onTapGesture {
                        isShowingAddress = true
                    }
                }
            }

            VStack(alignment: .leading) {
                ZStack {
                    Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: locations) { location in
                        MapAnnotation(
                            coordinate: location.coordinate,
                            anchorPoint: CGPoint(x: 0.5, y: 0.7)
                        ) {
                            VStack {
                                if location.isUserLocation {
                                    Circle()
                                        .frame(width: 20, height: 20)
                                        .foregroundColor(.blue)
                                        .rotationEffect(.degrees(isRotating ? 360 : 0))
                                        .onAppear {
                                            withAnimation(Animation.linear(duration: 2).repeatForever(autoreverses: false)) {
                                                self.isRotating.toggle()
                                            }
                                        }
                                } else {
                                    Image("ic_pin")
                                        .resizable()
                                        .frame(width: 32, height: 32)
                                }
                            }
                        }
                    }
                    .disabled(true)
                    .onAppear {
                        moveToUserLocation()
                    }

                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image(systemName: "square.arrowtriangle.4.outward")
                                .resizable()
                                .frame(width: 32, height: 32)
                                .foregroundColor(.gray)
                                .onTapGesture {
                                    isShowingMap = true
                                }
                        }
                    }
                    .padding(10)
                    .sheet(isPresented: $isShowingMap) {
                        if purchaseType == .friend {
                            FullMapView(region: $region, isShowingMap: $isShowingMap, address: $addressTitle)
                        } else {
                            ShowMapView(region: $region, locations: $locations, isShowingMap: $isShowingMap)
                        }
                    }
                    .onChange(of: region, perform: { newRegion in
                        if purchaseType == .friend {
                            Utilities.getAddress(for: newRegion.center) { address in
                                self.addressTitle = address
                            }
                        }
                    })
                }
                .frame(height: 158)
                .cornerRadius(8)
            }
            
            if servicePlace == .currentLocation {
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizedStringKey.name)
                        .customFont(weight: .regular, size: 12)
                        .foregroundColor(.black1F1F1F())
                    CustomTextField(text: $addressTitle, placeholder: LocalizedStringKey.homeAddress, textColor: .black4E5556(), placeholderColor: .grayA4ACAD())
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizedStringKey.address)
                        .customFont(weight: .regular, size: 12)
                        .foregroundColor(.black1F1F1F())
                    CustomTextField(text: $streetName, placeholder: LocalizedStringKey.address, textColor: .black4E5556(), placeholderColor: .grayA4ACAD())
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
    
    func moveToUserLocation() {
        withAnimation(.easeInOut(duration: 2.0)) {
            LocationManager.shared.getCurrentLocation { location in
                if let location = location {
                    region.center = location
                    region.span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                    let userLocationMark = Mark(
                        title: "موقعي",
                        coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude),
                        show: true,
                        imageName: "ic_logo",
                        isUserLocation: true
                    )
                    
                    locations.append(userLocationMark)
                    self.userLocation = location
                    Utilities.getAddress(for: location) { address in
                        self.streetName = address
                    }
                }
            }
        }
    }
}

extension CheckoutView {
    var paymentTypeValue: String {
        switch selectedPayment {
        case .hyperpay, .tamara:
            return "online"
        case .cash:
            return "cash"
        }
    }

    func addOrder() {
        let validation = validateAddress(purchaseType: selectedPurchaseType, selectedAddress: selectedAddress, region: region)

        handleValidationResult(validation)
        guard validation == .valid else { 
            // نظّف حالات التحميل إن كانت فعالة
            orderViewModel.isLoading = false
            return
        }

        let currentDate = Date()
        let formattedDate = currentDate.formattedDateString()
        let formattedTime = currentDate.formattedTimeString()

        // Prepare parameters dictionary
        var params: [String: Any] = [
            "couponCode": coupon,
            "PaymentType": paymentTypeValue,
            "dt_date": formattedDate,
            "dt_time": formattedTime,
            "is_address_book": isAddressBook,
            "OrderType": selectedPurchaseType == .myself ? 1 : 2,
            "notes": notes,
        ]

        // Determine address and coordinates based on purchase type
        if selectedPurchaseType == .myself {
            params["address"] = selectedAddress?.address ?? ""
            params["lat"] = selectedAddress?.lat ?? 0.0
            params["lng"] = selectedAddress?.lng ?? 0.0
        } else { // For purchase type = .friend
            params["address"] = addressTitle
            params["lat"] = region.center.latitude
            params["lng"] = region.center.longitude
        }
        
        if isAddressBook {
            params["address_book"] = selectedAddress?.id ?? ""
        }
        
        print("ppppp \(params)")
        
        orderViewModel.addOrder(params: params) { id, msg in
            // نظّف التحميل وأغلق أي شاشات
            orderViewModel.isLoading = false
            showApplePaySheet = false
            showTamaraPayment = false

            appRouter.navigate(to: .paymentSuccess)
        }
    }
    
    func checkCartCoupun() {
        let params: [String: Any] = [
            "coupon": $coupon,
            "is_address_book": isAddressBook,
            "address_book": isAddressBook ? selectedAddress?.id ?? "" : "",
            "lat": selectedAddress?.lat ?? 0.0,
            "lng": selectedAddress?.lng ?? 0.0,
        ]

        cartViewModel.checkCartCoupun(params: params)
    }
}

struct PurchaseTypeSection: View {
    @Binding var purchaseType: PurchaseType

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 10) {
                Text("نوع عملية الشراء")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.black)

                VStack(alignment: .leading, spacing: 10) {
                    RadioButton2(label: "شخصي", isSelected: purchaseType == .myself) {
                        purchaseType = .myself
                    }
                    RadioButton2(label: "لصديق", isSelected: purchaseType == .friend) {
                        purchaseType = .friend
                    }
                }
            }

            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

struct RadioButton2: View {
    var label: String
    var isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: isSelected ? "circle.fill" : "circle")
                .resizable()
                .frame(width: 16, height: 16)
                .foregroundColor(isSelected ? .primary1() : .black121212())
                .onTapGesture {
                    action()
                }
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.black1F1F1F())
        }
        .padding(.vertical, 8)
    }
}

struct CouponCheckSection: View {
    @Binding var coupon: String
    var checkCoupon: () -> Void
    
    var body: some View {
        HStack {
            HStack {
                TextField(LocalizedStringKey.coupon, text: $coupon)
                    .customFont(weight: .regular, size: 16)
                    .foregroundColor(.black)
                
                Spacer()
                
                Image("ic_coupon") // Replace with your actual image
                    .resizable()
                    .frame(width: 24, height: 24)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.primaryDark(), lineWidth: 1)
            )
            
            Button(action: {
                checkCoupon()
            }) {
                Text(LocalizedStringKey.checkCoupon)
                    .customFont(weight: .bold, size: 16)
                    .foregroundColor(.white)
            }
            .padding(18)
            .background(Color.primary())
            .cornerRadius(8)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct NotesView: View {
    @Binding var notes: String
    let placeholder: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(LocalizedStringKey.notes)
                .customFont(weight: .bold, size: 15)
                .foregroundColor(.black121212())

            TextEditor(text: $notes)
                .customFont(weight: .regular, size: 15)
                .foregroundColor(notes == placeholder ? .gray : .black121212())
                .frame(height: 100)
                .onTapGesture {
                    if notes == placeholder {
                        notes = ""
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                )
                .onAppear {
                    if notes.isEmpty {
                        notes = placeholder
                    }
                }
                .onChange(of: notes) { newValue in
                    if newValue.isEmpty {
                        notes = placeholder
                    } else if newValue == placeholder {
                        notes = ""
                    }
                }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

struct PaymentSection: View {
    @Binding var selectedPayment: PaymentOption
    @Binding var selectedBrand: HyperpayBrand
    @Binding var showBrandSheet: Bool
    var canShowApplePay: Bool
    var isDisabled: Bool = false
    var amount: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("اختر وسيلة الدفع")
                .font(.headline)
                .padding(.bottom, 4)

            ForEach(PaymentOption.allCases) { option in
                paymentOptionRow(option: option)
                    .disabled(isDisabled)
            }

            if selectedPayment == .hyperpay {
                VStack(alignment: .leading, spacing: 8) {
                    Text("نوع البطاقة")
                        .font(.subheadline)
                    Button {
                        showBrandSheet = true
                    } label: {
                        HStack {
                            Text(selectedBrand.displayName)
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                    .disabled(isDisabled)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .sheet(isPresented: $showBrandSheet) {
            BrandSheet(selectedBrand: $selectedBrand, showBrandSheet: $showBrandSheet, canShowApplePay: canShowApplePay)
        }
    }

    @ViewBuilder
    private func paymentOptionRow(option: PaymentOption) -> some View {
        let isSelected = selectedPayment == option
        let formattedAmount = String(format: "%.2f", amount)

        Button(action: {
            selectedPayment = option
        }) {
            HStack {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundColor(.primary())
                VStack(alignment: .leading) {
                    Text(option.displayName)
                        .foregroundColor(.black)
                    if isSelected {
                        Text("المبلغ: \(formattedAmount) ﷼")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                Spacer()
            }
            .padding()
            .background(Color.white)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.primary() : Color.gray.opacity(0.4), lineWidth: 1)
            )
        }
        .disabled(isDisabled)
    }
}

struct BrandSheet: View {
    @Binding var selectedBrand: HyperpayBrand
    @Binding var showBrandSheet: Bool
    var canShowApplePay: Bool

    var brands: [HyperpayBrand] {
        var base: [HyperpayBrand] = [.visa, .master, .mada]
        if canShowApplePay {
            base.append(.apple)
        }
        return base
    }

    var body: some View {
        VStack(spacing: 16) {
            Capsule()
                .fill(Color.gray.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 8)

            Text("اختر نوع البطاقة")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .padding(.bottom, 8)

            ForEach(brands, id: \.self) { brand in
                Button {
                    selectedBrand = brand
                    showBrandSheet = false
                } label: {
                    HStack {
                        Image(systemName: brand.iconName)
                            .foregroundColor(.black)
                            .frame(width: 24)
                        Text(brand.displayName)
                            .foregroundColor(.primary)
                            .fontWeight(selectedBrand == brand ? .bold : .regular)
                        Spacer()
                        if selectedBrand == brand {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selectedBrand == brand ? Color.blue : Color.clear, lineWidth: 1.5)
                            )
                    )
                }
            }

            Spacer()

            Button(action: {
                showBrandSheet = false
            }) {
                Text("إغلاق")
                    .font(.headline)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .cornerRadius(10)
            }
            .padding(.bottom)
        }
        .padding(.horizontal)
        .presentationDetents([.medium])
    }
}

extension CheckoutView {
    // التحقق الموحد لبيانات المستخدم للدفع الإلكتروني
    @discardableResult
    func validateUserForOnlinePayment() -> Bool {
        guard let user = UserSettings.shared.user else {
            orderViewModel.errorMessage = "يرجى تسجيل الدخول أولًا"
            return false
        }
        guard let name = user.full_name, !name.isEmpty,
              let email = user.email, !email.isEmpty else {
            orderViewModel.errorMessage = "الرجاء التأكد من إدخال الاسم والبريد الإلكتروني في حسابك قبل الدفع الإلكتروني"
            return false
        }
        return true
    }
}

extension CheckoutView {
    func tamaraCheckout() {
        let validation = validateAddress(purchaseType: selectedPurchaseType, selectedAddress: selectedAddress, region: region)

        handleValidationResult(validation)
        guard validation == .valid else { return }

        guard let cartTotal = cartViewModel.cartTotal,
              let cartItems = cartViewModel.cartItems?.results else {
            orderViewModel.errorMessage = "تعذر جلب بيانات السلة"
            return
        }

        // تحقق من المبلغ
        guard let amount = cartTotal.final_total, amount > 0 else {
            orderViewModel.errorMessage = invalidAmountMessage
            return
        }

        orderViewModel.isLoading = true
        let products = cartItems.map {
            TamaraProduct(
                product_id: $0.id ?? "",
                variation_name: $0.variation_name ?? "",
                variation_sku: $0.variation_sku ?? "",
                qty: $0.qty ?? 1
            )
        }

        let tamaraBody = TamaraBody(
            amount: amount,
            products: products
        )

        orderViewModel.tamaraCheckout(params: tamaraBody) {
            let url = orderViewModel.tamaraCheckout?.checkout_url ?? ""
            self.checkoutUrl = url

            // Initialize the Tamara view model with the new URL and merchantURL
            self.tamaraViewModel = TamaraWebViewModel(
                url: self.checkoutUrl,
                merchantURL: TamaraMerchantURL(
                    success: "https://wishy.sa/tamara/success",
                    failure: "https://wishy.sa/tamara/failure",
                    cancel: "https://wishy.sa/tamara/cancel",
                    notification: "https://wishy.sa/tamara/cancel"
                )
            )

            showTamaraPayment.toggle()
        }
    }
}

extension CheckoutView {
    func validateAddress(purchaseType: PurchaseType, selectedAddress: AddressItem?, region: MKCoordinateRegion) -> AddressValidationResult {
        switch purchaseType {
        case .myself:
            guard let address = selectedAddress else { return .missing }
            if address.lat == 0.0 || address.lng == 0.0 {
                return .invalidCoordinates
            }
        case .friend:
            if region.center.latitude == 0.0 || region.center.longitude == 0.0 {
                return .invalidCoordinates
            }
        }
        return .valid
    }

    func handleValidationResult(_ result: AddressValidationResult) {
        switch result {
        case .valid:
            return
        case .missing:
            orderViewModel.errorMessage = "لم تقم بتحديد أي عنوان، يرجى التحقق مرة أخرى."
        case .invalidCoordinates:
            orderViewModel.errorMessage = "العنوان المحدد غير صالح، يرجى اختيار عنوان آخر."
        }
    }
}

enum AddressValidationResult {
    case valid
    case missing
    case invalidCoordinates
}
