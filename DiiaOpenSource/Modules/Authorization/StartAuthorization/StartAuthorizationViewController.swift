import UIKit
import DiiaMVPModule
import DiiaUIComponents

protocol StartAuthorizationView: BaseView {
    func setLoadingState(_ state: LoadingState)
    func setAuthMethods(with viewModel: DSListViewModel)
    func setCheckmarks(with viewModel: BorderedCheckmarksViewModel)
    func setAvailability(_ isAvailable: Bool)
    func setServerStatus(_ isOnline: Bool)
    func showError(message: String)
}

final class StartAuthorizationViewController: UIViewController, Storyboarded {
    
    // MARK: - Outlets
    @IBOutlet private weak var loadingView: ContentLoadingView!
    @IBOutlet private weak var contentView: UIView!
    @IBOutlet private weak var scrollView: UIScrollView!
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var appVersion: UILabel!
    @IBOutlet private weak var authInfoLabel: UILabel!
    @IBOutlet private weak var readPleaseLabel: UILabel!
    @IBOutlet private weak var personalDataLabel: UILabel!
    @IBOutlet private weak var checkmarksView: BorderedCheckmarksView!
    @IBOutlet private weak var authMethodsListView: DSWhiteColoredListView!
    
    // Login/Password fields
    private var usernameTextField: UITextField!
    private var passwordTextField: UITextField!
    private var loginButton: UIButton!
    private var serverStatusLabel: UILabel!
    private var showPasswordButton: UIButton!
    
    // MARK: - Properties
    var presenter: StartAuthorizationAction!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initialSetup()
        presenter.configureView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        presenter.viewWillAppear()
    }
    
    // MARK: - Private Methods
    private func initialSetup() {
        setupFonts()
        setupTexts()
        setupRecognizers()
        setupAccessibility()
        setupLoginFields()
        scrollView.delegate = self
    }
    
    private func setupLoginFields() {
        // Создаем поля для логина и пароля программно
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Username field
        let usernameLabel = UILabel()
        usernameLabel.text = "Логін"
        usernameLabel.font = FontBook.usualFont
        usernameLabel.textColor = .black
        
        usernameTextField = UITextField()
        usernameTextField.placeholder = "Ваш логін"
        usernameTextField.borderStyle = .roundedRect
        usernameTextField.backgroundColor = UIColor.white.withAlphaComponent(0.7)
        usernameTextField.autocapitalizationType = .none
        usernameTextField.autocorrectionType = .no
        usernameTextField.heightAnchor.constraint(equalToConstant: 56).isActive = true
        
        // Password field
        let passwordLabel = UILabel()
        passwordLabel.text = "Пароль"
        passwordLabel.font = FontBook.usualFont
        passwordLabel.textColor = .black
        
        let passwordContainer = UIView()
        passwordContainer.translatesAutoresizingMaskIntoConstraints = false
        
        passwordTextField = UITextField()
        passwordTextField.placeholder = "Ваш пароль"
        passwordTextField.borderStyle = .roundedRect
        passwordTextField.backgroundColor = UIColor.white.withAlphaComponent(0.7)
        passwordTextField.isSecureTextEntry = true
        passwordTextField.autocapitalizationType = .none
        passwordTextField.autocorrectionType = .no
        passwordTextField.translatesAutoresizingMaskIntoConstraints = false
        
        showPasswordButton = UIButton(type: .system)
        showPasswordButton.setImage(UIImage(systemName: "eye"), for: .normal)
        showPasswordButton.addTarget(self, action: #selector(togglePasswordVisibility), for: .touchUpInside)
        showPasswordButton.translatesAutoresizingMaskIntoConstraints = false
        
        passwordContainer.addSubview(passwordTextField)
        passwordContainer.addSubview(showPasswordButton)
        
        NSLayoutConstraint.activate([
            passwordTextField.leadingAnchor.constraint(equalTo: passwordContainer.leadingAnchor),
            passwordTextField.trailingAnchor.constraint(equalTo: showPasswordButton.leadingAnchor, constant: -8),
            passwordTextField.topAnchor.constraint(equalTo: passwordContainer.topAnchor),
            passwordTextField.bottomAnchor.constraint(equalTo: passwordContainer.bottomAnchor),
            passwordTextField.heightAnchor.constraint(equalToConstant: 56),
            showPasswordButton.trailingAnchor.constraint(equalTo: passwordContainer.trailingAnchor, constant: -8),
            showPasswordButton.centerYAnchor.constraint(equalTo: passwordContainer.centerYAnchor),
            showPasswordButton.widthAnchor.constraint(equalToConstant: 44),
            showPasswordButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        // Server status label
        serverStatusLabel = UILabel()
        serverStatusLabel.font = FontBook.usualFont.withSize(12)
        serverStatusLabel.textColor = UIColor.black.withAlphaComponent(0.6)
        
        // Login button
        loginButton = UIButton(type: .system)
        loginButton.setTitle("Увійти", for: .normal)
        loginButton.titleLabel?.font = FontBook.usualFont.withSize(18)
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.backgroundColor = .black
        loginButton.layer.cornerRadius = 16
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        loginButton.heightAnchor.constraint(equalToConstant: 56).isActive = true
        
        stackView.addArrangedSubview(usernameLabel)
        stackView.addArrangedSubview(usernameTextField)
        stackView.addArrangedSubview(passwordLabel)
        stackView.addArrangedSubview(passwordContainer)
        stackView.addArrangedSubview(serverStatusLabel)
        stackView.addArrangedSubview(loginButton)
        
        // Добавляем stackView в contentView вместо authMethodsListView
        if let contentView = contentView {
            contentView.addSubview(stackView)
            NSLayoutConstraint.activate([
                stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
                stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
                stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
                stackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -24)
            ])
        }
        
        // Скрываем старый список методов авторизации
        authMethodsListView.isHidden = true
    }
    
    @objc private func togglePasswordVisibility() {
        passwordTextField.isSecureTextEntry.toggle()
        let imageName = passwordTextField.isSecureTextEntry ? "eye" : "eye.slash"
        showPasswordButton.setImage(UIImage(systemName: imageName), for: .normal)
    }
    
    @objc private func loginButtonTapped() {
        guard let username = usernameTextField.text, !username.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            showError(message: "Будь ласка, введіть логін та пароль")
            return
        }
        
        usernameTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
        
        presenter.login(username: username, password: password)
    }
    
    private func setupFonts() {
        titleLabel.font = FontBook.numbersHeadingFont
        appVersion.font = FontBook.usualFont
        authInfoLabel.font = FontBook.usualFont
        readPleaseLabel.font = FontBook.usualFont
    }
    
    private func setupTexts() {
        titleLabel.text = R.Strings.authorization_authorization.localized()
        appVersion.text = R.Strings.general_app_version.formattedLocalized(arguments: AppConstants.App.appVersion)
        appVersion.textColor = Constants.appVersionTextColor
        
        authInfoLabel.setTextWithCurrentAttributes(
            text: R.Strings.authorization_info.localized(),
            lineHeightMultiple: Constants.lineHeightMultiple
        )
        readPleaseLabel.setTextWithCurrentAttributes(
            text: R.Strings.authorization_read_please.localized(),
            lineHeightMultiple: Constants.lineHeightMultiple
        )
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = Constants.lineHeightMultiple
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: FontBook.usualFont,
            .foregroundColor: UIColor.black,
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .paragraphStyle: paragraphStyle
        ]
        
        personalDataLabel.attributedText = NSAttributedString(string: R.Strings.authorization_personal_data_message.localized(), attributes: attributes)
    }
    
    private func setupRecognizers() {
        let personalDataTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(showPersonalDataMessage))
        personalDataLabel.addGestureRecognizer(personalDataTapRecognizer)
        personalDataLabel.isUserInteractionEnabled = true
    }
    
    override func canGoBack() -> Bool {
        return false
    }
    
    // MARK: - Actions
    @objc private func showPersonalDataMessage() {
        presenter.showPersonalDataProcessing()
    }
    
    // MARK: - Accessibility
    private func setupAccessibility() {
        titleLabel.accessibilityIdentifier = Constants.titleComponentId
        authInfoLabel.accessibilityIdentifier = Constants.textConditionsComponentId
        checkmarksView.accessibilityIdentifier = Constants.checkboxComponentId
        authMethodsListView.accessibilityIdentifier = Constants.methodsListComponentId
        
        personalDataLabel.accessibilityLabel = R.Strings.auth_accessibility_start_person_data.localized()
        personalDataLabel.accessibilityTraits = .link
        
        checkmarksView.isAccessibilityElement = true
        checkmarksView.accessibilityTraits = [.button, .selected]
        checkmarksView.accessibilityLabel = R.Strings.auth_accessibility_start_checkmark.localized()
        
        appVersion.isAccessibilityElement = true
        appVersion.accessibilityTraits = .staticText
        appVersion.accessibilityLabel = R.Strings.general_app_version.formattedLocalized(arguments: AppConstants.App.appVersion).replacingOccurrences(of: ".", with: " ")
    }
    
    private func updateCheckmarkAccessibility(isChecked: Bool) {
        checkmarksView.accessibilityTraits = isChecked ? .selected : .notEnabled
    }
}

// MARK: - View logic
extension StartAuthorizationViewController: StartAuthorizationView {
    func setLoadingState(_ state: DiiaUIComponents.LoadingState) {
        loadingView.setLoadingState(state)
        contentView.isHidden = state == .loading
    }
    
    func setAuthMethods(with viewModel: DSListViewModel) {
        contentView.isHidden = false
        authMethodsListView.configure(viewModel: viewModel)
    }
    
    func setCheckmarks(with viewModel: BorderedCheckmarksViewModel) {
        checkmarksView.configure(with: viewModel)
    }
    
    func setAvailability(_ isAvailable: Bool) {
        updateCheckmarkAccessibility(isChecked: isAvailable)
        loginButton.isEnabled = isAvailable
        loginButton.alpha = isAvailable ? Constants.activeAlpha : Constants.inactiveAlpha
    }
    
    func setServerStatus(_ isOnline: Bool) {
        guard let serverStatusLabel = serverStatusLabel else { return }
        
        let statusColor = isOnline ? UIColor.systemGreen : UIColor.systemOrange
        let statusView = UIView()
        statusView.backgroundColor = statusColor
        statusView.layer.cornerRadius = 4
        statusView.translatesAutoresizingMaskIntoConstraints = false
        statusView.widthAnchor.constraint(equalToConstant: 8).isActive = true
        statusView.heightAnchor.constraint(equalToConstant: 8).isActive = true
        
        serverStatusLabel.text = isOnline ? "Сервер підключено" : "Offline режим"
        
        // Если label уже в stackView с индикатором, обновляем только текст
        if let parentStack = serverStatusLabel.superview as? UIStackView,
           parentStack.arrangedSubviews.count == 2 {
            // Обновляем только текст
            return
        }
        
        // Создаем новый stackView с индикатором и текстом
        let statusStackView = UIStackView(arrangedSubviews: [statusView, serverStatusLabel])
        statusStackView.axis = .horizontal
        statusStackView.spacing = 8
        statusStackView.alignment = .center
        
        // Заменяем label на stackView в родительском view
        if let parent = serverStatusLabel.superview {
            parent.addSubview(statusStackView)
            statusStackView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                statusStackView.leadingAnchor.constraint(equalTo: serverStatusLabel.leadingAnchor),
                statusStackView.trailingAnchor.constraint(equalTo: serverStatusLabel.trailingAnchor),
                statusStackView.topAnchor.constraint(equalTo: serverStatusLabel.topAnchor),
                statusStackView.bottomAnchor.constraint(equalTo: serverStatusLabel.bottomAnchor)
            ])
            serverStatusLabel.removeFromSuperview()
        }
    }
    
    func showError(message: String) {
        let alert = UIAlertController(title: "Помилка", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UIScrollViewDelegate
extension StartAuthorizationViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollView.isScrollEnabled = scrollView.frame.height <= scrollView.contentSize.height
    }
}

// MARK: - Constants
extension StartAuthorizationViewController {
    private enum Constants {
        static let lineHeightMultiple: CGFloat = 1.25
        static let activeAlpha: CGFloat = 1.0
        static let inactiveAlpha: CGFloat = 0.2
        static let appVersionTextColor = UIColor.black.withAlphaComponent(0.5)
        
        static let titleComponentId = "title_auth"
        static let textConditionsComponentId = "text_conditions_auth"
        static let checkboxComponentId = "checkbox_conditions_bordered_auth"
        static let methodsListComponentId = "methods_list_auth"
    }
}
