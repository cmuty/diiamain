import UIKit
import DiiaMVPModule
import DiiaCommonTypes
import DiiaUIComponents
import DiiaCommonServices
import DiiaAuthorizationPinCode

protocol StartAuthorizationAction: BasePresenter {
    func showPersonalDataProcessing()
    func viewWillAppear()
    func login(username: String, password: String)
}

final class StartAuthorizationPresenter: StartAuthorizationAction {
    
    unowned var view: StartAuthorizationView
    private let storeHelper: StoreHelperProtocol = StoreHelper.instance
    private let networkManager = NetworkManager.shared
    private let authManager = AuthManager.shared

    private var checkmarks: [CheckmarkViewModel] = []
    private var isLoading = false

    // MARK: - Init
    init(view: StartAuthorizationView) {
        self.view = view
    }

    // MARK: - Public Methods
    func configureView() {
        storeHelper.save(true, type: Bool.self, forKey: .hasAppBeenLaunchedBefore)
        setupAgreement()
        view.setLoadingState(.ready)
    }

    func viewWillAppear() {
        // Проверяем статус сервера
        Task {
            let isServerOnline = await networkManager.checkServerHealth()
            await MainActor.run {
                view.setServerStatus(isServerOnline)
            }
        }
    }

    func showPersonalDataProcessing() {
        CommunicationHelper.url(urlString: Constants.personalDataProcessingUrl)
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
            
            await MainActor.run {
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
                        // Используем данные из бота (full_name и birth_date)
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
                                await MainActor.run {
                                    UserDefaults.standard.set(photoData, forKey: "userPhoto")
                                }
                            }
                        }
                        
                        // Инициализируем генератор данных при первом входе
                        _ = StaticDataGenerator.shared.getBirthPlace()
                        _ = StaticDataGenerator.shared.getResidenceAddress()
                        
                        // Переходим к созданию PIN-кода
                        await MainActor.run {
                            self.createPincode()
                        }
                    } else {
                        await MainActor.run {
                            self.view.showError(message: "Помилка отримання даних користувача")
                        }
                    }
                } else {
                    await MainActor.run {
                        self.view.showError(message: result.message)
                    }
                }
            }
        }
    }

    private func setupAgreement() {
        self.checkmarks = [
            CheckmarkViewModel(
                text: R.Strings.authorization_data_processing_agreement.localized(),
                isChecked: true,
                componentId: Constants.checkmarkComponentId)
        ]
        let viewModel = BorderedCheckmarksViewModel(checkmarks: self.checkmarks)
        viewModel.onClick = { [weak self] in
            guard let self = self else { return }
            let isAvailable = self.checkmarks.contains(where: { $0.isChecked })
            self.view.setAvailability(isAvailable)
        }
        view.setCheckmarks(with: viewModel)
    }

    // MARK: - Navigation
    private func createPincode() {
        view.open(module: StartAuthorizationPresenter.userLoginSuccessModule())
    }
}

// MARK: - Constants
extension StartAuthorizationPresenter {
    private enum Constants {
        static let personalDataProcessingUrl = "https://diia.gov.ua/app_policy"
        static let checkmarkComponentId = "checkbox_conditions_auth"
    }
}

extension StartAuthorizationPresenter {
    /// completion handler wiith app level specific code for using after successfull authorization. Reused in Authorization Core
    static func userLoginSuccessModule() -> CreatePinCodeModule {
        return CreatePinCodeModule(
            viewModel: PinCodeViewModel(
                pinCodeLength: AppConstants.App.defaultPinCodeLength,
                createDetails: R.Strings.authorization_new_pin_details.localized(),
                repeatDetails: R.Strings.authorization_repeat_pin_details.localized(),
                authFlow: .login,
                completionHandler: { (pincode, view) in
                    // Сохраняем PIN-код через старую систему для совместимости
                    ServicesProvider.shared.authService.setPincode(pincode: pincode)
                    switch BiometryHelper.biometricType() {
                    case .none:
                        AppRouter.instance.open(module: MainTabBarModule(), needPincode: false, asRoot: true)
                        AppRouter.instance.didFinishStartingWithPincode = true
                    default:
                        StoreHelper.instance.save(false, type: Bool.self, forKey: .isBiometryEnabled)
                        view.open(module: BiometryRequestModule(viewModel: .default(authFlow: .login)))
                    }
                }
            )
        )
    }
}
