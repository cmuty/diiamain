import Foundation
import DiiaDocumentsCommonTypes

/// Сервис для генерации документов на основе данных пользователя из AuthManager
class UserDocumentsService {
    static let shared = UserDocumentsService()
    
    private init() {}
    
    /// Получить данные пользователя для использования в документах
    func getUserData() -> User {
        return User(from: AuthManager.shared)
    }
    
    /// Получить ФИО пользователя в формате для документов
    func getUserFullName() -> String {
        let user = getUserData()
        return "\(user.lastName) \(user.firstName) \(user.patronymic)".trimmingCharacters(in: .whitespaces)
    }
    
    /// Получить дату рождения пользователя
    func getUserBirthDate() -> String {
        return AuthManager.shared.userBirthDate
    }
    
    /// Получить РНОКПП пользователя
    func getUserTaxId() -> String {
        let user = getUserData()
        return user.taxId
    }
    
    /// Получить фото пользователя
    func getUserPhoto() -> Data? {
        return UserDefaults.standard.data(forKey: "userPhoto")
    }
    
    /// Получить фото пользователя как UIImage
    func getUserPhotoImage() -> UIImage? {
        guard let photoData = getUserPhoto() else { return nil }
        return UIImage(data: photoData)
    }
    
    /// Проверить, авторизован ли пользователь
    func isUserAuthenticated() -> Bool {
        return AuthManager.shared.isAuthenticated && !AuthManager.shared.userFullName.isEmpty
    }
}

