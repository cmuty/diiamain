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
    
    // Создать мок JSON для документов с данными пользователя
    func createMockDocumentsJSON(user: User) -> String {
        // Форматируем дату рождения
        let birthDateParts = user.birthDate.components(separatedBy: ".")
        let birthYear = birthDateParts.count == 3 ? birthDateParts[2] : "2008"
        let birthMonth = birthDateParts.count == 3 ? birthDateParts[1] : "01"
        let birthDay = birthDateParts.count == 3 ? birthDateParts[0] : "07"
        
        // Вычисляем даты
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        // ISO8601 формат для expirationDate
        let isoFormatter = DateFormatter()
        isoFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        isoFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        // Даты для ID-документа (выдан недавно, действует долго)
        let idIssueDate = calendar.date(byAdding: .year, value: -1, to: Date()) ?? Date()
        let idExpiryDate = calendar.date(byAdding: .year, value: 10, to: idIssueDate) ?? Date()
        let idIssueDateString = formatter.string(from: idIssueDate)
        let idExpiryDateString = formatter.string(from: idExpiryDate)
        let idExpirationDateString = isoFormatter.string(from: idExpiryDate)
        
        // Даты для паспорта (выдан в 14 лет, действует 8 лет)
        let passportIssueDate = calendar.date(byAdding: .year, value: -2, to: Date()) ?? Date()
        let passportExpiryDate = calendar.date(byAdding: .year, value: 8, to: passportIssueDate) ?? Date()
        let passportIssueDateString = formatter.string(from: passportIssueDate)
        let passportExpiryDateString = formatter.string(from: passportExpiryDate)
        let passportExpirationDateString = isoFormatter.string(from: passportExpiryDate)
        
        // Номер паспорта
        let passportNumber = StaticDataGenerator.shared.getPassportNumber()
        
        // Создаем мок JSON для всех трех документов
        let mockJSON = """
        {
            "idCard": {
                "data": [
                    {
                        "docNumber": "\(user.taxId)",
                        "docData": {
                            "fName": "\(user.firstName)",
                            "lName": "\(user.lastName)",
                            "mName": "\(user.patronymic)",
                            "birthday": "\(birthYear)-\(birthMonth)-\(birthDay)",
                            "birthPlace": "\(user.birthPlace)",
                            "docNumber": "\(user.taxId)",
                            "dateIssue": "\(idIssueDateString)",
                            "dateExpiry": "\(idExpiryDateString)",
                            "validUntil": null,
                            "status": "ok",
                            "expirationDate": "\(idExpirationDateString)"
                        },
                        "shareLocalization": {
                            "ua": {
                                "fName": "\(user.firstName)",
                                "lName": "\(user.lastName)",
                                "mName": "\(user.patronymic)",
                                "birthday": "\(user.birthDate)",
                                "birthPlace": "\(user.birthPlace)",
                                "docNumber": "\(user.taxId)",
                                "dateIssue": "\(idIssueDateString)",
                                "dateExpiry": "\(idExpiryDateString)"
                            }
                        }
                    }
                ]
            },
            "birthCertificate": {
                "data": [
                    {
                        "docNumber": "\(StaticDataGenerator.shared.getCertificateNumber())",
                        "docData": {
                            "fName": "\(user.firstName)",
                            "lName": "\(user.lastName)",
                            "mName": "\(user.patronymic)",
                            "birthday": "\(birthYear)-\(birthMonth)-\(birthDay)",
                            "birthPlace": "\(user.birthPlace)",
                            "docNumber": "\(StaticDataGenerator.shared.getCertificateNumber())",
                            "validUntil": null,
                            "status": "ok",
                            "expirationDate": "2099-12-31T23:59:59.999Z"
                        },
                        "shareLocalization": {
                            "ua": {
                                "fName": "\(user.firstName)",
                                "lName": "\(user.lastName)",
                                "mName": "\(user.patronymic)",
                                "birthday": "\(user.birthDate)",
                                "birthPlace": "\(user.birthPlace)",
                                "docNumber": "\(StaticDataGenerator.shared.getCertificateNumber())"
                            }
                        }
                    }
                ]
            },
            "passport": {
                "data": [
                    {
                        "docNumber": "\(passportNumber)",
                        "docData": {
                            "fName": "\(user.firstName)",
                            "lName": "\(user.lastName)",
                            "mName": "\(user.patronymic)",
                            "birthday": "\(birthYear)-\(birthMonth)-\(birthDay)",
                            "birthPlace": "\(user.birthPlace)",
                            "docNumber": "\(passportNumber)",
                            "dateIssue": "\(passportIssueDateString)",
                            "dateExpiry": "\(passportExpiryDateString)",
                            "department": "ДМС України",
                            "validUntil": null,
                            "status": "ok",
                            "expirationDate": "\(passportExpirationDateString)"
                        },
                        "shareLocalization": {
                            "ua": {
                                "fName": "\(user.firstName)",
                                "lName": "\(user.lastName)",
                                "mName": "\(user.patronymic)",
                                "birthday": "\(user.birthDate)",
                                "birthPlace": "\(user.birthPlace)",
                                "docNumber": "\(passportNumber)",
                                "dateIssue": "\(passportIssueDateString)",
                                "dateExpiry": "\(passportExpiryDateString)",
                                "department": "ДМС України"
                            }
                        }
                    }
                ]
            },
            "documentsTypeOrder": ["id-card", "birth-certificate", "passport"]
        }
        """
        
        return mockJSON
    }
}

