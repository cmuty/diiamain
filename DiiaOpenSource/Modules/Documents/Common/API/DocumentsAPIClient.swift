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
        let serverSignal = request<DocumentsResponse>(.getDocuments(filter: types))
        
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
                        print("⚠️ Сохранённых документов нет, возвращаем пустой моковый ответ")

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
        
        return serverSignal
    }
}

