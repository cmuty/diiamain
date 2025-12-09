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

final class StartAuthorizationViewController: UIViewController {
    
    // MARK: - Properties
    var presenter: StartAuthorizationAction?
    
    // UI Elements - все не optional для надежности
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()
    private let titleLabel = UILabel()
    private let usernameTextField = UITextField()
    private let passwordTextField = UITextField()
    private let showPasswordButton = UIButton(type: .system)
    private let loginButton = UIButton(type: .system)
    private let serverStatusLabel = UILabel()
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    
    private var isPasswordVisible = false
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        presenter?.configureView()
        // Автозагрузка логина/пароля временно отключена
        // loadCredentialsFromServer()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        presenter?.viewWillAppear()
    }
    
    // MARK: - Private Methods
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // ScrollView
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        view.addSubview(scrollView)
        
        // ContentView
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // StackView
        stackView.axis = .vertical
        stackView.spacing = 24
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stackView)
        
        // Title
        titleLabel.text = "Вітаємо в Дія 👋"
        titleLabel.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        stackView.addArrangedSubview(titleLabel)
        
        // Username field
        let usernameContainer = createTextFieldContainer(
            label: "Логін",
            placeholder: "Ваш логін",
            textField: usernameTextField
        )
        stackView.addArrangedSubview(usernameContainer)
        
        // Password field
        let passwordContainer = createPasswordFieldContainer()
        stackView.addArrangedSubview(passwordContainer)
        
        // Server status
        serverStatusLabel.text = "Перевірка сервера..."
        serverStatusLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        serverStatusLabel.textColor = .secondaryLabel
        serverStatusLabel.textAlignment = .center
        stackView.addArrangedSubview(serverStatusLabel)
        
        // Login button
        loginButton.setTitle("Увійти", for: .normal)
        loginButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.backgroundColor = .systemBlue
        loginButton.layer.cornerRadius = 12
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        loginButton.heightAnchor.constraint(equalToConstant: 56).isActive = true
        stackView.addArrangedSubview(loginButton)
        
        // Loading indicator
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingIndicator)
        
        // Constraints
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 40),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func createTextFieldContainer(label: String, placeholder: String, textField: UITextField) -> UIStackView {
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 8
        container.alignment = .fill
        
        let labelView = UILabel()
        labelView.text = label
        labelView.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        labelView.textColor = .label
        
        textField.placeholder = placeholder
        textField.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.backgroundColor = .secondarySystemBackground
        textField.layer.cornerRadius = 12
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        textField.leftViewMode = .always
        textField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        textField.rightViewMode = .always
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.heightAnchor.constraint(equalToConstant: 56).isActive = true
        
        container.addArrangedSubview(labelView)
        container.addArrangedSubview(textField)
        
        return container
    }
    
    private func createPasswordFieldContainer() -> UIStackView {
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 8
        container.alignment = .fill
        
        let label = UILabel()
        label.text = "Пароль"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        
        let passwordContainer = UIView()
        passwordContainer.translatesAutoresizingMaskIntoConstraints = false
        passwordContainer.backgroundColor = .secondarySystemBackground
        passwordContainer.layer.cornerRadius = 12
        
        passwordTextField.placeholder = "Ваш пароль"
        passwordTextField.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        passwordTextField.isSecureTextEntry = true
        passwordTextField.autocapitalizationType = .none
        passwordTextField.autocorrectionType = .no
        passwordTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        passwordTextField.leftViewMode = .always
        passwordTextField.translatesAutoresizingMaskIntoConstraints = false
        passwordTextField.heightAnchor.constraint(equalToConstant: 56).isActive = true
        
        showPasswordButton.setImage(UIImage(systemName: "eye"), for: .normal)
        showPasswordButton.tintColor = .systemGray
        showPasswordButton.addTarget(self, action: #selector(togglePasswordVisibility), for: .touchUpInside)
        showPasswordButton.translatesAutoresizingMaskIntoConstraints = false
        
        passwordContainer.addSubview(passwordTextField)
        passwordContainer.addSubview(showPasswordButton)
        
        NSLayoutConstraint.activate([
            passwordTextField.leadingAnchor.constraint(equalTo: passwordContainer.leadingAnchor),
            passwordTextField.trailingAnchor.constraint(equalTo: showPasswordButton.leadingAnchor, constant: -8),
            passwordTextField.topAnchor.constraint(equalTo: passwordContainer.topAnchor),
            passwordTextField.bottomAnchor.constraint(equalTo: passwordContainer.bottomAnchor),
            
            showPasswordButton.trailingAnchor.constraint(equalTo: passwordContainer.trailingAnchor, constant: -16),
            showPasswordButton.centerYAnchor.constraint(equalTo: passwordContainer.centerYAnchor),
            showPasswordButton.widthAnchor.constraint(equalToConstant: 44),
            showPasswordButton.heightAnchor.constraint(equalToConstant: 44),
            
            passwordContainer.heightAnchor.constraint(equalToConstant: 56)
        ])
        
        container.addArrangedSubview(label)
        container.addArrangedSubview(passwordContainer)
        
        return container
    }
    
    @objc private func togglePasswordVisibility() {
        isPasswordVisible.toggle()
        passwordTextField.isSecureTextEntry = !isPasswordVisible
        let imageName = isPasswordVisible ? "eye.slash" : "eye"
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
        
        presenter?.login(username: username, password: password)
    }
    
    override func canGoBack() -> Bool {
        return false
    }
}

// MARK: - View logic
extension StartAuthorizationViewController: StartAuthorizationView {
    func setLoadingState(_ state: DiiaUIComponents.LoadingState) {
        switch state {
        case .loading:
            loadingIndicator.startAnimating()
            loginButton.isEnabled = false
            loginButton.alpha = 0.6
        case .ready:
            loadingIndicator.stopAnimating()
            loginButton.isEnabled = true
            loginButton.alpha = 1.0
        }
    }
    
    func setAuthMethods(with viewModel: DSListViewModel) {
        // Not used in new design
    }
    
    func setCheckmarks(with viewModel: BorderedCheckmarksViewModel) {
        // Not used in new design
    }
    
    func setAvailability(_ isAvailable: Bool) {
        loginButton.isEnabled = isAvailable
        loginButton.alpha = isAvailable ? 1.0 : 0.6
    }
    
    func setServerStatus(_ isOnline: Bool) {
        if isOnline {
            serverStatusLabel.text = "✅ Сервер підключено"
            serverStatusLabel.textColor = .systemGreen
        } else {
            serverStatusLabel.text = "⚠️ Offline режим"
            serverStatusLabel.textColor = .systemOrange
        }
    }
    
    func showError(message: String) {
        let alert = UIAlertController(title: "Помилка", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
