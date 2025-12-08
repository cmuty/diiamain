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
    
    // MARK: - Outlets (старые из storyboard, не используются в новом дизайне)
    @IBOutlet private weak var loadingView: ContentLoadingView?
    @IBOutlet private weak var contentView: UIView?
    @IBOutlet private weak var scrollView: UIScrollView?
    @IBOutlet private weak var appVersion: UILabel?
    @IBOutlet private weak var authInfoLabel: UILabel?
    @IBOutlet private weak var authMethodsListView: UIView?
    @IBOutlet private weak var checkmarksView: UIView?
    @IBOutlet private weak var personalDataLabel: UILabel?
    @IBOutlet private weak var readPleaseLabel: UILabel?
    @IBOutlet private weak var titleLabel: UILabel?
    
    // MARK: - Properties
    var presenter: StartAuthorizationAction!
    
    // UI Elements
    private var backgroundGradientView: AnimatedGradientBackgroundView!
    private var mainScrollView: UIScrollView!
    private var mainStackView: UIStackView!
    private var usernameTextField: UITextField!
    private var passwordTextField: UITextField!
    private var showPasswordButton: UIButton!
    private var loginButton: UIButton!
    private var serverStatusStackView: UIStackView!
    private var serverStatusIndicator: UIView!
    private var serverStatusLabel: UILabel!
    private var forgotPasswordButton: UIButton!
    private var registrationStackView: UIStackView!
    private var registrationButton: UIButton!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupBackground()
        setupUI()
        presenter.configureView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        presenter.viewWillAppear()
    }
    
    // MARK: - Private Methods
    private func setupBackground() {
        backgroundGradientView = AnimatedGradientBackgroundView()
        backgroundGradientView.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(backgroundGradientView, at: 0)
        
        NSLayoutConstraint.activate([
            backgroundGradientView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundGradientView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundGradientView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundGradientView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupUI() {
        // Создаем свой scrollView, если его нет в storyboard
        if let existingScrollView = scrollView {
            self.mainScrollView = existingScrollView
        } else {
            self.mainScrollView = UIScrollView()
            self.mainScrollView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(self.mainScrollView)
            NSLayoutConstraint.activate([
                self.mainScrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                self.mainScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                self.mainScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                self.mainScrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }
        self.mainScrollView.delegate = self
        self.mainScrollView.showsVerticalScrollIndicator = false
        
        // Main scroll view content
        let scrollContentView = UIView()
        scrollContentView.translatesAutoresizingMaskIntoConstraints = false
        self.mainScrollView.addSubview(scrollContentView)
        
        // Main stack view
        mainStackView = UIStackView()
        mainStackView.axis = .vertical
        mainStackView.spacing = 24
        mainStackView.alignment = .leading
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        scrollContentView.addSubview(mainStackView)
        
        // Title
        let titleLabel = UILabel()
        titleLabel.text = "Вітаємо в Дія 👋"
        titleLabel.font = UIFont.systemFont(ofSize: 30, weight: .regular)
        titleLabel.textColor = .black
        mainStackView.addArrangedSubview(titleLabel)
        
        // Username field
        let usernameContainer = createTextFieldContainer(
            label: "Логін",
            placeholder: "Ваш логін",
            textField: &usernameTextField
        )
        mainStackView.addArrangedSubview(usernameContainer)
        
        // Password field
        let passwordContainer = createPasswordFieldContainer()
        mainStackView.addArrangedSubview(passwordContainer)
        
        // Forgot password button
        forgotPasswordButton = UIButton(type: .system)
        forgotPasswordButton.setTitle("Забули пароль?", for: .normal)
        forgotPasswordButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        forgotPasswordButton.setTitleColor(.black, for: .normal)
        forgotPasswordButton.addTarget(self, action: #selector(forgotPasswordTapped), for: .touchUpInside)
        mainStackView.addArrangedSubview(forgotPasswordButton)
        
        // Server status
        serverStatusStackView = createServerStatusView()
        mainStackView.addArrangedSubview(serverStatusStackView)
        
        // Login button
        loginButton = UIButton(type: .system)
        loginButton.setTitle("Увійти", for: .normal)
        loginButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.backgroundColor = .black
        loginButton.layer.cornerRadius = 16
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        loginButton.heightAnchor.constraint(equalToConstant: 56).isActive = true
        mainStackView.addArrangedSubview(loginButton)
        
        // Spacer
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.heightAnchor.constraint(equalToConstant: 100).isActive = true
        mainStackView.addArrangedSubview(spacer)
        
        // Registration section
        registrationStackView = createRegistrationSection()
        mainStackView.addArrangedSubview(registrationStackView)
        
        // Constraints
        NSLayoutConstraint.activate([
            scrollContentView.topAnchor.constraint(equalTo: self.mainScrollView.topAnchor),
            scrollContentView.leadingAnchor.constraint(equalTo: self.mainScrollView.leadingAnchor),
            scrollContentView.trailingAnchor.constraint(equalTo: self.mainScrollView.trailingAnchor),
            scrollContentView.bottomAnchor.constraint(equalTo: self.mainScrollView.bottomAnchor),
            scrollContentView.widthAnchor.constraint(equalTo: self.mainScrollView.widthAnchor),
            
            mainStackView.topAnchor.constraint(equalTo: scrollContentView.topAnchor, constant: 64),
            mainStackView.leadingAnchor.constraint(equalTo: scrollContentView.leadingAnchor, constant: 24),
            mainStackView.trailingAnchor.constraint(equalTo: scrollContentView.trailingAnchor, constant: -24),
            mainStackView.bottomAnchor.constraint(equalTo: scrollContentView.bottomAnchor, constant: -32)
        ])
        
        // Hide old content if exists
        contentView?.isHidden = true
        loadingView?.isHidden = true
        authInfoLabel?.isHidden = true
        readPleaseLabel?.isHidden = true
        personalDataLabel?.isHidden = true
        checkmarksView?.isHidden = true
        authMethodsListView?.isHidden = true
        titleLabel?.isHidden = true
        appVersion?.isHidden = true
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
        
        passwordTextField = UITextField()
        passwordTextField.placeholder = "Ваш пароль"
        passwordTextField.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        passwordTextField.isSecureTextEntry = true
        passwordTextField.autocapitalizationType = .none
        passwordTextField.autocorrectionType = .no
        passwordTextField.backgroundColor = UIColor.white.withAlphaComponent(0.7)
        passwordTextField.layer.cornerRadius = 16
        passwordTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        passwordTextField.leftViewMode = .always
        passwordTextField.translatesAutoresizingMaskIntoConstraints = false
        passwordTextField.heightAnchor.constraint(equalToConstant: 56).isActive = true
        
        showPasswordButton = UIButton(type: .system)
        showPasswordButton.setImage(UIImage(systemName: "eye"), for: .normal)
        showPasswordButton.tintColor = .gray
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
    
    private func createServerStatusView() -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.alignment = .center
        
        serverStatusIndicator = UIView()
        serverStatusIndicator.backgroundColor = .orange
        serverStatusIndicator.layer.cornerRadius = 4
        serverStatusIndicator.translatesAutoresizingMaskIntoConstraints = false
        serverStatusIndicator.widthAnchor.constraint(equalToConstant: 8).isActive = true
        serverStatusIndicator.heightAnchor.constraint(equalToConstant: 8).isActive = true
        
        serverStatusLabel = UILabel()
        serverStatusLabel.text = "Offline режим"
        serverStatusLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        serverStatusLabel.textColor = UIColor.black.withAlphaComponent(0.6)
        
        stackView.addArrangedSubview(serverStatusIndicator)
        stackView.addArrangedSubview(serverStatusLabel)
        
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
        
        registrationButton = UIButton(type: .system)
        registrationButton.setTitle("Перейти до бота", for: .normal)
        registrationButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        registrationButton.setTitleColor(.black, for: .normal)
        registrationButton.backgroundColor = UIColor.white.withAlphaComponent(0.7)
        registrationButton.layer.cornerRadius = 16
        registrationButton.addTarget(self, action: #selector(registrationButtonTapped), for: .touchUpInside)
        registrationButton.translatesAutoresizingMaskIntoConstraints = false
        registrationButton.heightAnchor.constraint(equalToConstant: 56).isActive = true
        
        let arrowImage = UIImageView(image: UIImage(systemName: "arrow.right"))
        arrowImage.tintColor = .black
        arrowImage.translatesAutoresizingMaskIntoConstraints = false
        registrationButton.addSubview(arrowImage)
        
        NSLayoutConstraint.activate([
            arrowImage.trailingAnchor.constraint(equalTo: registrationButton.trailingAnchor, constant: -16),
            arrowImage.centerYAnchor.constraint(equalTo: registrationButton.centerYAnchor)
        ])
        
        container.addArrangedSubview(textStack)
        container.addArrangedSubview(registrationButton)
        
        return container
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
    
    @objc private func forgotPasswordTapped() {
        if let url = URL(string: "https://t.me/diiatest24bot") {
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
        loginButton.isEnabled = isAvailable
        loginButton.alpha = isAvailable ? 1.0 : 0.5
    }
    
    func setServerStatus(_ isOnline: Bool) {
        serverStatusIndicator.backgroundColor = isOnline ? .green : .orange
        serverStatusLabel.text = isOnline ? "Сервер підключено" : "Offline режим"
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
