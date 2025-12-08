import Foundation

class NetworkManager {
    static let shared = NetworkManager()
    
    // API Base URL - використовуйте IP адресу вашого комп'ютера
    // Щоб дізнатись IP: відкрийте PowerShell і введіть: ipconfig
    // Або використовуйте ngrok URL (без :8000 на кінці!)
    // private let baseURL = "http://192.168.0.104:8000"  // локальна мережа
    private let baseURL = "https://diia-backend.onrender.com"  // ngrok - працює!
    
    // Fallback credentials для offline режиму
    private let offlineCredentials: [String: String] = [
        "cmutyy": "password123",
        "test": "test123"
    ]
    
    // Mock данные для offline тестування (якщо немає кешу)
    private func getMockUserData(username: String) -> UserData? {
        switch username {
        case "cmutyy":
            return UserData(
                id: 1,
                full_name: "Зарва Богдан Олегович",
                birth_date: "07.01.2008",
                login: "cmutyy",
                subscription_active: true,
                subscription_type: "premium",
                last_login: nil,
                registered_at: "2024-10-23T16:48:00"
            )
        case "test":
            return UserData(
                id: 2,
                full_name: "Тестовий Користувач Петрович",
                birth_date: "01.01.2000",
                login: "test",
                subscription_active: true,
                subscription_type: "basic",
                last_login: nil,
                registered_at: "2024-10-20T10:30:00"
            )
        default:
            return nil
        }
    }
    
    struct LoginResponse: Codable {
        let success: Bool
        let message: String
        let user: UserData?
    }
    
    struct UserData: Codable {
        let id: Int
        let full_name: String
        let birth_date: String
        let login: String
        let subscription_active: Bool
        let subscription_type: String
        let last_login: String?
        let registered_at: String?
        
        enum CodingKeys: String, CodingKey {
            case id
            case full_name
            case birth_date
            case login
            case subscription_active
            case subscription_type
            case last_login
            case registered_at
        }
    }
    
    struct LoginRequest: Codable {
        let login: String
        let password: String
    }
    
    func login(username: String, password: String) async -> (success: Bool, message: String, userData: UserData?) {
        // Спочатку пробуємо підключитися до API
        if let result = await tryAPILogin(username: username, password: password) {
            return result
        }
        
        // Перевіряємо локально збережені дані (пріоритет)
        if let userData = UserDefaults.standard.data(forKey: "cachedUserData_\(username)"),
           let cachedUser = try? JSONDecoder().decode(UserData.self, from: userData),
           let cachedPassword = UserDefaults.standard.string(forKey: "cachedPassword_\(username)"),
           cachedPassword == password {
            print("✅ Using cached user data")
            return (true, "Локальна авторизація успішна", cachedUser)
        }
        
        // Якщо API недоступний, перевіряємо offline credentials + mock data
        if let storedPassword = offlineCredentials[username], storedPassword == password {
            print("✅ Using offline credentials with mock data")
            let mockUser = getMockUserData(username: username)
            return (true, "Offline авторизація успішна", mockUser)
        }
        
        return (false, "Невірний логін або пароль", nil)
    }
    
    private func tryAPILogin(username: String, password: String) async -> (success: Bool, message: String, userData: UserData?)? {
        guard let url = URL(string: "\(baseURL)/api/auth/login") else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("1", forHTTPHeaderField: "ngrok-skip-browser-warning")
        request.timeoutInterval = 5.0 // 5 секунд timeout
        
        let loginRequest = LoginRequest(login: username, password: password)
        
        do {
            request.httpBody = try JSONEncoder().encode(loginRequest)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return nil
            }
            
            if httpResponse.statusCode == 200 {
                let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
                
                if loginResponse.success, let userData = loginResponse.user {
                    // Кешуємо дані для offline використання
                    cacheUserData(username: username, password: password, userData: userData)
                    return (true, loginResponse.message, userData)
                } else {
                    return (false, loginResponse.message, nil)
                }
            }
        } catch {
            print("API Login error: \(error.localizedDescription)")
            return nil
        }
        
        return nil
    }
    
    private func cacheUserData(username: String, password: String, userData: UserData) {
        if let encoded = try? JSONEncoder().encode(userData) {
            UserDefaults.standard.set(encoded, forKey: "cachedUserData_\(username)")
            UserDefaults.standard.set(password, forKey: "cachedPassword_\(username)")
        }
    }
    
    func checkServerHealth() async -> Bool {
        guard let url = URL(string: "\(baseURL)/api/health") else {
            return false
        }
        
        var request = URLRequest(url: url)
        request.setValue("1", forHTTPHeaderField: "ngrok-skip-browser-warning")
        request.timeoutInterval = 3.0
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 200
            }
        } catch {
            print("Server health check failed: \(error.localizedDescription)")
        }
        
        return false
    }
    
    func downloadUserPhoto(userId: Int) async -> Data? {
        guard let url = URL(string: "\(baseURL)/api/photo/\(userId)") else {
            print("Invalid photo URL")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.setValue("1", forHTTPHeaderField: "ngrok-skip-browser-warning")
        request.timeoutInterval = 10.0
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("Failed to download photo: invalid response")
                return nil
            }
            
            print("✅ Photo downloaded: \(data.count) bytes")
            return data
        } catch {
            print("❌ Photo download error: \(error.localizedDescription)")
            return nil
        }
    }
}

