import UIKit
import DiiaMVPModule
import DiiaCommonTypes
import DiiaUIComponents
import DiiaCommonServices
import DiiaAuthorizationPinCode
import DiiaDocumentsCommonTypes

protocol StartAuthorizationAction: BasePresenter {
    func viewWillAppear()
    func login(username: String, password: String)
}

final class StartAuthorizationPresenter: StartAuthorizationAction {
    
    unowned var view: StartAuthorizationView
    private let storeHelper: StoreHelperProtocol = StoreHelper.instance
    private let networkManager = NetworkManager.shared
    private let authManager = AuthManager.shared
    private var isLoading = false

    // MARK: - Init
    init(view: StartAuthorizationView) {
        self.view = view
    }

    // MARK: - Public Methods
    func configureView() {
        storeHelper.save(true, type: Bool.self, forKey: .hasAppBeenLaunchedBefore)
        view.setLoadingState(.ready)
    }

    func viewWillAppear() {
        // Проверяем статус сервера
        Task {
            let isServerOnline = await networkManager.checkServerHealth()
            Task { @MainActor in
                view.setServerStatus(isServerOnline)
            }
        }
    }
    
    func login(username: String, password: String) {
        guard !isLoading else { return }
        guard !username.isEmpty && !password.isEmpty else {
            view.showError(message: "Будь ласка, введіть логін та пароль")
            return
        }
        
        isLoading = true
        view.setLoadingState(.loading)
        
        Task {
            let result = await networkManager.login(username: username, password: password)
            
            Task { @MainActor in
                isLoading = false
                view.setLoadingState(.ready)
                
                if result.success {
                    // Проверяем подписку перед авторизацией
                    if let userData = result.userData {
                        // Если подписки нет - выкидываем пользователя
                        if !userData.subscription_active {
                            self.view.showError(message: "У вас немає активної підписки. Будь ласка, оформіть підписку в боті.")
                            return
                        }
                        
                        // Сохраняем данные авторизации
                        authManager.login(username: username, password: password)
                        
                        // Обновляем данные пользователя
                        authManager.updateUserData(
                            fullName: userData.full_name,
                            birthDate: userData.birth_date,
                            userId: userData.id,
                            subscriptionActive: userData.subscription_active,
                            subscriptionType: userData.subscription_type,
                            registeredAt: userData.registered_at
                        )
                        
                        // Сохраняем данные пользователя для использования в документах
                        UserDefaults.standard.set(userData.full_name, forKey: "documentUserFullName")
                        UserDefaults.standard.set(userData.birth_date, forKey: "documentUserBirthDate")
                        
                        // Создаем User для получения разбитых данных
                        let user = User(from: authManager)
                        UserDefaults.standard.set(user.taxId, forKey: "documentUserTaxId")
                        UserDefaults.standard.set(user.firstName, forKey: "documentUserFirstName")
                        UserDefaults.standard.set(user.lastName, forKey: "documentUserLastName")
                        UserDefaults.standard.set(user.patronymic, forKey: "documentUserPatronymic")
                        
                        // Загружаем фото пользователя
                        Task {
                            if let photoData = await networkManager.downloadUserPhoto(userId: userData.id) {
                                Task { @MainActor in
                                    UserDefaults.standard.set(photoData, forKey: "userPhoto")
                                }
                            }
                        }
                        
                        // Инициализируем генератор данных при первом входе
                        _ = StaticDataGenerator.shared.getBirthPlace()
                        _ = StaticDataGenerator.shared.getResidenceAddress()
                        
                        // Создаем мок документ с данными пользователя
                        self.createMockDocument(user: user)
                        
                        // Переходим к созданию PIN-кода или сразу в MainTab
                        self.openMainTab()
                    } else {
                        self.view.showError(message: "Помилка отримання даних користувача")
                    }
                } else {
                    self.view.showError(message: result.message)
                }
            }
        }
    }

    // MARK: - Mock Document Creation
    private func createMockDocument(user: User) {
        // Создаем мок JSON для всех трех документов
        let mockJSON = NetworkManager.shared.createMockDocumentsJSON(user: user)
        
        guard let jsonData = mockJSON.data(using: .utf8),
              let mockResponse = try? JSONDecoder().decode(DocumentsResponse.self, from: jsonData) else {
            print("⚠️ Не удалось создать мок документы")
            return
        }
        
        let storeHelper = StoreHelper.instance
        
        // Сохраняем все три документа
        if let idCard = mockResponse.idCard {
            storeHelper.save(idCard, type: DSFullDocumentModel.self, forKey: .idCard)
            print("✅ Создан ID-документ")
        }
        
        if let birthCert = mockResponse.birthCertificate {
            storeHelper.save(birthCert, type: DSFullDocumentModel.self, forKey: .birthCertificate)
            print("✅ Создано свидетельство о рождении")
        }
        
        if let passport = mockResponse.passport {
            storeHelper.save(passport, type: DSFullDocumentModel.self, forKey: .passport)
            print("✅ Создан паспорт")
        }
        
        // Устанавливаем порядок документов
        let orderService = DocumentReorderingService.shared
        let currentOrder = orderService.docTypesOrder()
        let expectedOrder = ["id-card", "birth-certificate", "passport"]
        
        if currentOrder.isEmpty || Set(currentOrder) != Set(expectedOrder) {
            orderService.setOrder(order: expectedOrder, synchronize: false)
            print("✅ Установлен порядок документов: \(expectedOrder.joined(separator: ", "))")
        }
        
        print("✅ Созданы все мок документы для \(user.userFullName)")
    }
    
    // MARK: - Navigation
    private func openMainTab() {
        // Проверяем, есть ли уже PIN-код
        if ServicesProvider.shared.authService.havePincode() {
            // Если PIN-код есть - сразу открываем MainTab
            AppRouter.instance.open(module: MainTabBarModule(), needPincode: false, asRoot: true)
            AppRouter.instance.didFinishStartingWithPincode = true
        } else {
            // Если PIN-кода нет - создаем его
            view.open(module: createPincodeModule())
        }
    }
    
    private func createPincodeModule() -> CreatePinCodeModule {
        return CreatePinCodeModule(
            viewModel: PinCodeViewModel(
                pinCodeLength: AppConstants.App.defaultPinCodeLength,
                createDetails: R.Strings.authorization_new_pin_details.localized(),
                repeatDetails: R.Strings.authorization_repeat_pin_details.localized(),
                authFlow: .login,
                completionHandler: { (pincode, view) in
                    // Сохраняем PIN-код через старую систему для совместимости
                    ServicesProvider.shared.authService.setPincode(pincode: pincode)
                    // Пропускаем экран Face ID, сразу переходим в MainTab
                    StoreHelper.instance.save(false, type: Bool.self, forKey: .isBiometryEnabled)
                    AppRouter.instance.open(module: MainTabBarModule(), needPincode: false, asRoot: true)
                    AppRouter.instance.didFinishStartingWithPincode = true
                }
            )
        )
    }
}
