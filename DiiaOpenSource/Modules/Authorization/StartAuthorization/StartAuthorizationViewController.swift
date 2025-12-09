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
    @IBOutlet private weak var loadingView: ContentLoadingView?
    @IBOutlet private weak var contentView: UIView?
    @IBOutlet private weak var scrollView: UIScrollView?
    
    // MARK: - Properties
    var presenter: StartAuthorizationAction?
    
    // UI Elements
    private var backgroundGradientView: AnimatedGradientBackgroundView?
    private var mainScrollView: UIScrollView!
    private var mainStackView: UIStackView?
    private var usernameTextField: UITextField?
    private var passwordTextField: UITextField?
    private var showPasswordButton: UIButton?
    private var loginButton: UIButton?
    private var serverStatusStackView: UIStackView?
    private var serverStatusIndicator: UIView?
    private var serverStatusLabel: UILabel?
    private var forgotPasswordButton: UIButton?
    private var registrationStackView: UIStackView?
    private var registrationButton: UIButton!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Убеждаемся, что view загружена
        guard view != nil else {
            print("ERROR: view is nil in viewDidLoad")
            return
        }
        
        setupBackground()
        setupUI()
        presenter?.configureView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        presenter?.viewWillAppear()
    }
    
    // MARK: - Private Methods
    private func setupBackground() {
        let gradientView = AnimatedGradientBackgroundView()
        gradientView.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(gradientView, at: 0)
        backgroundGradientView = gradientView
        
        NSLayoutConstraint.activate([
            gradientView.topAnchor.constraint(equalTo: view.topAnchor),
            gradientView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gradientView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupUI() {
        // Создаем свой scrollView, если его нет в storyboard
        if let existingScrollView = scrollView {
            self.mainScrollView = existingScrollView
        } else {
            let createdScrollView = UIScrollView()
            createdScrollView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(createdScrollView)
            NSLayoutConstraint.activate([
                createdScrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                createdScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                createdScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                createdScrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
            self.mainScrollView = createdScrollView
        }

        guard let scrollView = self.mainScrollView else {
            print("ERROR: Failed to create scrollView")
            return
        }
        scrollView.delegate = self

        // Main scroll view content
        let scrollContentView = UIView()
        scrollContentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(scrollContentView)

        // Main stack view
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 24
        stackView.alignment = .leading
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollContentView.addSubview(stackView)
        mainStackView = stackView

        // Title
        let titleLabel = UILabel()
        titleLabel.text = "Вітаємо в Дія 👋"
        titleLabel.font = UIFont.systemFont(ofSize: 30, weight: .regular)
        titleLabel.textColor = .black
        stackView.addArrangedSubview(titleLabel)

        // Username field
        let usernameContainer = createTextFieldContainer(
            label: "Логін",
            placeholder: "Ваш логін",
            textField: &usernameTextField
        )
        stackView.addArrangedSubview(usernameContainer)

        // Password field
        let passwordContainer = createPasswordFieldContainer()
        stackView.addArrangedSubview(passwordContainer)

        // Forgot password button
        let forgotButton = UIButton(type: .system)
        forgotButton.setTitle("Забули пароль?", for: .normal)
        forgotButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        forgotButton.setTitleColor(.black, for: .normal)
        forgotButton.addTarget(self, action: #selector(forgotPasswordTapped), for: .touchUpInside)
        stackView.addArrangedSubview(forgotButton)
        forgotPasswordButton = forgotButton

        // Server status
        let statusView = createServerStatusView()
        stackView.addArrangedSubview(statusView)
        serverStatusStackView = statusView

        // Login button
        let loginBtn = UIButton(type: .system)
        loginBtn.setTitle("Увійти", for: .normal)
        loginBtn.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        loginBtn.setTitleColor(.white, for: .normal)
        loginBtn.backgroundColor = .black
        loginBtn.layer.cornerRadius = 16
        loginBtn.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        loginBtn.translatesAutoresizingMaskIntoConstraints = false
        loginBtn.heightAnchor.constraint(equalToConstant: 56).isActive = true
        stackView.addArrangedSubview(loginBtn)
        loginButton = loginBtn

        // Spacer
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.heightAnchor.constraint(equalToConstant: 100).isActive = true
        stackView.addArrangedSubview(spacer)

        // Registration section
        let regView = createRegistrationSection()
        stackView.addArrangedSubview(regView)
        registrationStackView = regView

        // Constraints
        NSLayoutConstraint.activate([
            scrollContentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            scrollContentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            scrollContentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            scrollContentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            scrollContentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            stackView.topAnchor.constraint(equalTo: scrollContentView.topAnchor, constant: 64),
            stackView.leadingAnchor.constraint(equalTo: scrollContentView.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: scrollContentView.trailingAnchor, constant: -24),
            stackView.bottomAnchor.constraint(equalTo: scrollContentView.bottomAnchor, constant: -32)
        ])

        // Hide old content if exists
        contentView?.isHidden = true
        loadingView?.isHidden = true
    }
    
    private func createTextFieldContainer(label: String, placeholder: String, textField: inout UITextField?) -> UIStackView {
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 8
        container.alignment = .leading
        
        let labelView = UILabel()
        labelView.text = label
        labelView.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        labelView.textColor = .black
        
        textField = UITextField()
        textField?.placeholder = placeholder
        textField?.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        textField?.autocapitalizationType = .none
        textField?.autocorrectionType = .no
        textField?.backgroundColor = UIColor.white.withAlphaComponent(0.7)
        textField?.layer.cornerRadius = 16
        textField?.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        textField?.leftViewMode = .always
        textField?.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        textField?.rightViewMode = .always
        textField?.translatesAutoresizingMaskIntoConstraints = false
        textField?.heightAnchor.constraint(equalToConstant: 56).isActive = true
        
        container.addArrangedSubview(labelView)
        if let textField = textField {
            container.addArrangedSubview(textField)
        }
        
        return container
    }
    
    private func createPasswordFieldContainer() -> UIStackView {
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 8
        container.alignment = .leading
        
        let label = UILabel()
        label.text = "Пароль"
        label.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        label.textColor = .black
        
        let passwordContainer = UIView()
        passwordContainer.translatesAutoresizingMaskIntoConstraints = false
        
        let passwordField = UITextField()
        passwordField.placeholder = "Ваш пароль"
        passwordField.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        passwordField.isSecureTextEntry = true
        passwordField.autocapitalizationType = .none
        passwordField.autocorrectionType = .no
        passwordField.backgroundColor = UIColor.white.withAlphaComponent(0.7)
        passwordField.layer.cornerRadius = 16
        passwordField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        passwordField.leftViewMode = .always
        passwordField.translatesAutoresizingMaskIntoConstraints = false
        passwordField.heightAnchor.constraint(equalToConstant: 56).isActive = true
        passwordTextField = passwordField
        
        let showButton = UIButton(type: .system)
        showButton.setImage(UIImage(systemName: "eye"), for: .normal)
        showButton.tintColor = .gray
        showButton.addTarget(self, action: #selector(togglePasswordVisibility), for: .touchUpInside)
        showButton.translatesAutoresizingMaskIntoConstraints = false
        showPasswordButton = showButton
        
        passwordContainer.addSubview(passwordField)
        passwordContainer.addSubview(showButton)
        
        NSLayoutConstraint.activate([
            passwordField.leadingAnchor.constraint(equalTo: passwordContainer.leadingAnchor),
            passwordField.trailingAnchor.constraint(equalTo: showButton.leadingAnchor, constant: -8),
            passwordField.topAnchor.constraint(equalTo: passwordContainer.topAnchor),
            passwordField.bottomAnchor.constraint(equalTo: passwordContainer.bottomAnchor),
            passwordField.heightAnchor.constraint(equalToConstant: 56),
            showButton.trailingAnchor.constraint(equalTo: passwordContainer.trailingAnchor, constant: -16),
            showButton.centerYAnchor.constraint(equalTo: passwordContainer.centerYAnchor),
            showButton.widthAnchor.constraint(equalToConstant: 44),
            showButton.heightAnchor.constraint(equalToConstant: 44),
            passwordContainer.heightAnchor.constraint(equalToConstant: 56)
        ])
        
        container.addArrangedSubview(label)
        container.addArrangedSubview(passwordContainer)
        
        return container
    }
    
    private func createServerStatusView() -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.alignment = .center
        
        let indicator = UIView()
        indicator.backgroundColor = .orange
        indicator.layer.cornerRadius = 4
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.widthAnchor.constraint(equalToConstant: 8).isActive = true
        indicator.heightAnchor.constraint(equalToConstant: 8).isActive = true
        serverStatusIndicator = indicator
        
        let label = UILabel()
        label.text = "Offline режим"
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        label.textColor = UIColor.black.withAlphaComponent(0.6)
        serverStatusLabel = label
        
        stackView.addArrangedSubview(indicator)
        stackView.addArrangedSubview(label)
        
        return stackView
    }
    
    private func createRegistrationSection() -> UIStackView {
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 16
        container.alignment = .fill
        
        let textStack = UIStackView()
        textStack.axis = .vertical
        textStack.spacing = 4
        textStack.alignment = .center
        
        let titleLabel = UILabel()
        titleLabel.text = "Не зареєстровані?"
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        titleLabel.textColor = .black
        titleLabel.textAlignment = .center
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = "Реєстрація доступна в нашому боті"
        subtitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = .gray
        subtitleLabel.textAlignment = .center
        
        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(subtitleLabel)
        
        let regButton = UIButton(type: .system)
        regButton.setTitle("Перейти до бота", for: .normal)
        regButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        regButton.setTitleColor(.black, for: .normal)
        regButton.backgroundColor = UIColor.white.withAlphaComponent(0.7)
        regButton.layer.cornerRadius = 16
        regButton.addTarget(self, action: #selector(registrationButtonTapped), for: .touchUpInside)
        regButton.translatesAutoresizingMaskIntoConstraints = false
        regButton.heightAnchor.constraint(equalToConstant: 56).isActive = true
        registrationButton = regButton
        
        let arrowImage = UIImageView(image: UIImage(systemName: "arrow.right"))
        arrowImage.tintColor = .black
        arrowImage.translatesAutoresizingMaskIntoConstraints = false
        regButton.addSubview(arrowImage)
        
        NSLayoutConstraint.activate([
            arrowImage.trailingAnchor.constraint(equalTo: regButton.trailingAnchor, constant: -16),
            arrowImage.centerYAnchor.constraint(equalTo: regButton.centerYAnchor)
        ])
        
        container.addArrangedSubview(textStack)
        container.addArrangedSubview(regButton)
        
        return container
    }
    
    @objc private func togglePasswordVisibility() {
        guard let passwordField = passwordTextField, let showButton = showPasswordButton else { return }
        passwordField.isSecureTextEntry.toggle()
        let imageName = passwordField.isSecureTextEntry ? "eye" : "eye.slash"
        showButton.setImage(UIImage(systemName: imageName), for: .normal)
    }
    
    @objc private func loginButtonTapped() {
        guard let username = usernameTextField?.text, !username.isEmpty,
              let password = passwordTextField?.text, !password.isEmpty else {
            showError(message: "Будь ласка, введіть логін та пароль")
            return
        }
        
        usernameTextField?.resignFirstResponder()
        passwordTextField?.resignFirstResponder()
        
        presenter?.login(username: username, password: password)
    }
    
    @objc private func forgotPasswordTapped() {
        if let url = URL(string: "https://t.me/maijediiabot") {
            UIApplication.shared.open(url)
        }
    }
    
    @objc private func registrationButtonTapped() {
        if let url = URL(string: "https://t.me/maijediiabot") {
            UIApplication.shared.open(url)
        }
    }
    
    override func canGoBack() -> Bool {
        return false
    }
}

// MARK: - View logic
extension StartAuthorizationViewController: StartAuthorizationView {
    func setLoadingState(_ state: DiiaUIComponents.LoadingState) {
        loadingView?.setLoadingState(state)
        mainScrollView?.isHidden = state == .loading
    }
    
    func setAuthMethods(with viewModel: DSListViewModel) {
        // Not used in new design
    }
    
    func setCheckmarks(with viewModel: BorderedCheckmarksViewModel) {
        // Not used in new design
    }
    
    func setAvailability(_ isAvailable: Bool) {
        loginButton?.isEnabled = isAvailable
        loginButton?.alpha = isAvailable ? 1.0 : 0.5
    }
    
    func setServerStatus(_ isOnline: Bool) {
        serverStatusIndicator?.backgroundColor = isOnline ? .green : .orange
        serverStatusLabel?.text = isOnline ? "Сервер підключено" : "Offline режим"
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
