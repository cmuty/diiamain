import Foundation
import ReactiveKit
import DiiaNetwork
import DiiaDocumentsCommonTypes

public protocol DocumentsAPIClientProtocol {
    func getDocuments(_ types: [DocTypeCode]) -> Signal<DocumentsResponse, NetworkError>
}

class DocumentsAPIClient: ApiClient<DocumentsAPI>, DocumentsAPIClientProtocol {
    func getDocuments(_ types: [DocTypeCode] = []) -> Signal<DocumentsResponse, NetworkError> {
        // Полностью отвязаны от сервера - всегда возвращаем мок документы
        return Signal { observer in
            let storeHelper = StoreHelper.instance
            let savedIdCard: DSFullDocumentModel? = storeHelper.getValue(forKey: .idCard)
            let savedBirthCert: DSFullDocumentModel? = storeHelper.getValue(forKey: .birthCertificate)
            let savedPassport: DSFullDocumentModel? = storeHelper.getValue(forKey: .passport)
            
            // Если документы уже сохранены, используем их
            if let idCard = savedIdCard, let birthCert = savedBirthCert, let passport = savedPassport {
                print("✅ Используем сохраненные документы")
                let mockResponse = DocumentsResponse(
                    driverLicense: nil,
                    idCard: idCard,
                    birthCertificate: birthCert,
                    passport: passport,
                    documentsTypeOrder: ["id-card", "birth-certificate", "passport"]
                )
                observer.next(mockResponse)
                observer.completed()
                return SimpleDisposable()
            }
            
            // Если документов нет - создаем их ВСЕГДА, даже без авторизации
            print("⚠️ Документы не найдены, создаем мок документы с дефолтными данными")
            
            // Пытаемся использовать данные пользователя, если они есть
            let user: User
            if let firstName = UserDefaults.standard.string(forKey: "documentUserFirstName"),
               let lastName = UserDefaults.standard.string(forKey: "documentUserLastName"),
               let patronymic = UserDefaults.standard.string(forKey: "documentUserPatronymic"),
               let birthDate = UserDefaults.standard.string(forKey: "documentUserBirthDate"),
               let taxId = UserDefaults.standard.string(forKey: "documentUserTaxId") {
                // Используем сохраненные данные пользователя
                user = User(
                    firstName: firstName,
                    lastName: lastName,
                    patronymic: patronymic,
                    birthDate: birthDate,
                    taxId: taxId,
                    photoName: "user_photo"
                )
            } else {
                // Используем дефолтные мок данные
                user = User.mock
                print("✅ Используем дефолтные мок данные: \(user.userFullName)")
            }
            
            // Создаем мок JSON
            let mockJSON = NetworkManager.shared.createMockDocumentsJSON(user: user)
            
            guard let jsonData = mockJSON.data(using: .utf8),
                  let mockResponse = try? JSONDecoder().decode(DocumentsResponse.self, from: jsonData) else {
                print("❌ Не удалось создать мок документы")
                // Возвращаем пустой ответ вместо краша
                let emptyResponse = DocumentsResponse(
                    driverLicense: nil,
                    idCard: nil,
                    birthCertificate: nil,
                    passport: nil,
                    documentsTypeOrder: ["id-card", "birth-certificate", "passport"]
                )
                observer.next(emptyResponse)
                observer.completed()
                return SimpleDisposable()
            }
            
            // Сохраняем документы
            if let idCard = mockResponse.idCard {
                storeHelper.save(idCard, type: DSFullDocumentModel.self, forKey: .idCard)
                print("✅ Создан ID-документ")
            }
            if let birthCert = mockResponse.birthCertificate {
                storeHelper.save(birthCert, type: DSFullDocumentModel.self, forKey: .birthCertificate)
                print("✅ Создано свидетельство о рождении")
            }
            if let passport = mockResponse.passport {
                storeHelper.save(passport, type: DSFullDocumentModel.self, forKey: .passport)
                print("✅ Создан паспорт")
            }
            
            // Устанавливаем порядок документов
            let orderService = DocumentReorderingService.shared
            let expectedOrder = ["id-card", "birth-certificate", "passport"]
            orderService.setOrder(order: expectedOrder, synchronize: false)
            print("✅ Установлен порядок документов: \(expectedOrder.joined(separator: ", "))")
            
            observer.next(mockResponse)
            observer.completed()
            return SimpleDisposable()
        }
    }
}

