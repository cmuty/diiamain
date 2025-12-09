import Foundation
import ReactiveKit
import DiiaNetwork
import DiiaDocumentsCommonTypes

public protocol DocumentsAPIClientProtocol {
    func getDocuments(_ types: [DocTypeCode]) -> Signal<DocumentsResponse, NetworkError>
}

class DocumentsAPIClient: ApiClient<DocumentsAPI>, DocumentsAPIClientProtocol {
    func getDocuments(_ types: [DocTypeCode] = []) -> Signal<DocumentsResponse, NetworkError> {
        // Полностью отвязаны от сервера - сразу возвращаем мок документы
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
            } else {
                // Если документов нет, но пользователь авторизован - создаем их
                if AuthManager.shared.isAuthenticated {
                    print("⚠️ Документы не найдены, создаем мок документы")
                    if let firstName = UserDefaults.standard.string(forKey: "documentUserFirstName"),
                       let lastName = UserDefaults.standard.string(forKey: "documentUserLastName"),
                       let patronymic = UserDefaults.standard.string(forKey: "documentUserPatronymic"),
                       let birthDate = UserDefaults.standard.string(forKey: "documentUserBirthDate"),
                       let taxId = UserDefaults.standard.string(forKey: "documentUserTaxId") {
                        
                        // Создаем User из сохраненных данных
                        let user = User(
                            firstName: firstName,
                            lastName: lastName,
                            patronymic: patronymic,
                            birthDate: birthDate,
                            taxId: taxId,
                            photoName: "user_photo"
                        )
                        
                        // Создаем мок JSON
                        let mockJSON = NetworkManager.shared.createMockDocumentsJSON(user: user)
                        
                        if let jsonData = mockJSON.data(using: .utf8),
                           let mockResponse = try? JSONDecoder().decode(DocumentsResponse.self, from: jsonData) {
                            
                            // Сохраняем документы
                            if let idCard = mockResponse.idCard {
                                storeHelper.save(idCard, type: DSFullDocumentModel.self, forKey: .idCard)
                            }
                            if let birthCert = mockResponse.birthCertificate {
                                storeHelper.save(birthCert, type: DSFullDocumentModel.self, forKey: .birthCertificate)
                            }
                            if let passport = mockResponse.passport {
                                storeHelper.save(passport, type: DSFullDocumentModel.self, forKey: .passport)
                            }
                            
                            observer.next(mockResponse)
                            observer.completed()
                            return SimpleDisposable()
                        }
                    }
                }
                
                // Если не удалось создать документы, возвращаем пустой ответ
                print("⚠️ Не удалось создать документы, возвращаем пустой ответ")
                let mockResponse = DocumentsResponse(
                    driverLicense: nil,
                    idCard: nil,
                    birthCertificate: nil,
                    passport: nil,
                    documentsTypeOrder: ["id-card", "birth-certificate", "passport"]
                )
                observer.next(mockResponse)
                observer.completed()
            }
            return SimpleDisposable()
        }
    }
}

