import Foundation
import ReactiveKit
import DiiaNetwork
import DiiaDocumentsCommonTypes

public protocol DocumentsAPIClientProtocol {
    func getDocuments(_ types: [DocTypeCode]) -> Signal<DocumentsResponse, NetworkError>
}

class DocumentsAPIClient: ApiClient<DocumentsAPI>, DocumentsAPIClientProtocol {
    func getDocuments(_ types: [DocTypeCode] = []) -> Signal<DocumentsResponse, NetworkError> {
        // Сначала пробуем получить документы с сервера
        let serverSignal = request(.getDocuments(filter: types))
        
        // Если пользователь авторизован, возвращаем мок документы при ошибке
        if AuthManager.shared.isAuthenticated {
            return serverSignal.recover { error -> Signal<DocumentsResponse, NetworkError> in
                // Если API недоступен, возвращаем мок документы
                print("⚠️ Documents API недоступен, используем мок данные")
                return Signal { observer in
                    // Проверяем, есть ли уже сохраненные документы
                    let storeHelper = StoreHelper.instance
                    let savedIdCard: DSFullDocumentModel? = storeHelper.getValue(forKey: .idCard)
                    let savedBirthCert: DSFullDocumentModel? = storeHelper.getValue(forKey: .birthCertificate)
                    let savedPassport: DSFullDocumentModel? = storeHelper.getValue(forKey: .passport)
                    
                    if savedIdCard != nil && savedBirthCert != nil && savedPassport != nil {
                        print("✅ Используем сохраненные документы")
                        let mockResponse = DocumentsResponse(
                            driverLicense: nil,
                            idCard: savedIdCard,
                            birthCertificate: savedBirthCert,
                            passport: savedPassport,
                            documentsTypeOrder: ["id-card", "birth-certificate", "passport"]
                        )
                        observer.next(mockResponse)
                        observer.completed()
                    } else {
                        // Создаем новые мок документы через JSON
                        let user = User(from: AuthManager.shared)
                        let mockJSON = NetworkManager.shared.createMockDocumentsJSON(user: user)
                        
                        if let jsonData = mockJSON.data(using: .utf8),
                           let mockResponse = try? JSONDecoder().decode(DocumentsResponse.self, from: jsonData) {
                            // Сохраняем все документы
                            if let idCard = mockResponse.idCard {
                                storeHelper.save(idCard, type: DSFullDocumentModel.self, forKey: .idCard)
                                print("✅ Создан и сохранен ID-документ")
                            }
                            if let birthCert = mockResponse.birthCertificate {
                                storeHelper.save(birthCert, type: DSFullDocumentModel.self, forKey: .birthCertificate)
                                print("✅ Создано и сохранено свидетельство о рождении")
                            }
                            if let passport = mockResponse.passport {
                                storeHelper.save(passport, type: DSFullDocumentModel.self, forKey: .passport)
                                print("✅ Создан и сохранен паспорт")
                            }
                            print("✅ Созданы все мок документы для \(user.userFullName)")
                            observer.next(mockResponse)
                        } else {
                            print("❌ Не удалось создать мок документы")
                            let mockResponse = DocumentsResponse(
                                driverLicense: nil,
                                idCard: nil,
                                birthCertificate: nil,
                                passport: nil,
                                documentsTypeOrder: ["id-card", "birth-certificate", "passport"]
                            )
                            observer.next(mockResponse)
                        }
                        observer.completed()
                    }
                    return SimpleDisposable()
                }
            }
        }
        
        return serverSignal
    }
}

