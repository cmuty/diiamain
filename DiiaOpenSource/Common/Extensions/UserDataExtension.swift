import Foundation

/// Расширение для удобного доступа к данным пользователя в любом месте приложения
extension UserDefaults {
    
    /// Получить ФИО пользователя для документов
    var documentUserFullName: String? {
        return string(forKey: "documentUserFullName")
    }
    
    /// Получить дату рождения пользователя для документов
    var documentUserBirthDate: String? {
        return string(forKey: "documentUserBirthDate")
    }
    
    /// Получить РНОКПП пользователя для документов
    var documentUserTaxId: String? {
        return string(forKey: "documentUserTaxId")
    }
    
    /// Получить имя пользователя для документов
    var documentUserFirstName: String? {
        return string(forKey: "documentUserFirstName")
    }
    
    /// Получить фамилию пользователя для документов
    var documentUserLastName: String? {
        return string(forKey: "documentUserLastName")
    }
    
    /// Получить отчество пользователя для документов
    var documentUserPatronymic: String? {
        return string(forKey: "documentUserPatronymic")
    }
    
    /// Получить данные пользователя как объект User
    var documentUser: User? {
        guard let fullName = documentUserFullName,
              let birthDate = documentUserBirthDate,
              let taxId = documentUserTaxId else {
            return nil
        }
        
        let nameParts = fullName.components(separatedBy: " ")
        let firstName = nameParts.count > 1 ? nameParts[1] : ""
        let lastName = nameParts.count > 0 ? nameParts[0] : ""
        let patronymic = nameParts.count > 2 ? nameParts[2...].joined(separator: " ") : ""
        
        return User(
            firstName: firstName,
            lastName: lastName,
            patronymic: patronymic,
            birthDate: birthDate,
            taxId: taxId,
            photoName: "user_photo"
        )
    }
}

/// Глобальный helper для получения данных пользователя
struct UserDataHelper {
    /// Получить текущего пользователя для использования в документах
    static func getCurrentUser() -> User {
        // Сначала пробуем получить из UserDefaults (если уже сохранено)
        if let user = UserDefaults.standard.documentUser {
            return user
        }
        
        // Иначе создаем из AuthManager
        return User(from: AuthManager.shared)
    }
    
    /// Получить ФИО пользователя
    static func getUserFullName() -> String {
        return getCurrentUser().userFullName
    }
    
    /// Получить дату рождения пользователя
    static func getUserBirthDate() -> String {
        return AuthManager.shared.userBirthDate.isEmpty ? getCurrentUser().birthDate : AuthManager.shared.userBirthDate
    }
    
    /// Получить РНОКПП пользователя
    static func getUserTaxId() -> String {
        return getCurrentUser().taxId
    }
    
    /// Получить фото пользователя
    static func getUserPhoto() -> Data? {
        return UserDefaults.standard.data(forKey: "userPhoto")
    }
    
    /// Проверить, есть ли данные пользователя
    static func hasUserData() -> Bool {
        return AuthManager.shared.isAuthenticated && !AuthManager.shared.userFullName.isEmpty
    }
}

