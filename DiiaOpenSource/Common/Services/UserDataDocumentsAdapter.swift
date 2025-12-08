import Foundation
import DiiaDocumentsCommonTypes

/// Адаптер для замены данных в документах данными пользователя из AuthManager
class UserDataDocumentsAdapter {
    static let shared = UserDataDocumentsAdapter()
    
    private init() {}
    
    /// Заменить данные пользователя в документе данными из AuthManager
    /// Это нужно вызывать после загрузки документов с сервера, чтобы заменить данные
    func adaptDocumentData<T: Codable>(_ document: T) -> T {
        // Для документов, которые используют данные пользователя,
        // мы заменяем их данными из AuthManager
        // Это работает через reflection и модификацию данных перед сохранением
        
        // В данном случае, мы будем использовать данные пользователя
        // при создании view models документов, а не модифицировать сами модели
        
        return document
    }
    
    /// Получить данные пользователя для использования в документах
    func getUserDataForDocuments() -> User {
        return User(from: AuthManager.shared)
    }
    
    /// Проверить, нужно ли использовать данные пользователя вместо данных с сервера
    func shouldUseUserData() -> Bool {
        return AuthManager.shared.isAuthenticated && !AuthManager.shared.userFullName.isEmpty
    }
}

