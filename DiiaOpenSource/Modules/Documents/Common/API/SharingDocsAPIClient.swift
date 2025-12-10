import ReactiveKit
import DiiaDocumentsCommonTypes
import DiiaNetwork

class SharingDocsAPIClient: ApiClient<SharingDocsAPI>, SharingDocsApiClientProtocol {
    
    // ВАЖНО: Полностью отвязаны от сервера - возвращаем мок данные
    override init() {
        super.init()
        print("✅ SharingDocsAPIClient инициализирован - используем только мок данные")
    }
    
    // MARK: - Share
    func shareDriverLicense(documentId: String, localization: String?) -> Signal<ShareLinkModel, NetworkError> {
        // НЕ делаем реальных запросов - возвращаем мок данные
        // ВАЖНО: НЕ используем реальные URL серверов Diia - только локальные мок данные
        print("📄 SharingDocsAPIClient.shareDriverLicense - возвращаем мок данные (без контакта с серверами)")
        return Signal { observer in
            // Возвращаем локальный мок ответ без контакта с серверами
            // ShareLinkModel требует: id, link, barcode, timerText, timerTime
            let mockLink = ShareLinkModel(
                id: "mock-id-\(documentId)",
                link: "local://mock-share-link", // Локальный URL, не контактирует с серверами
                barcode: nil,
                timerText: "",
                timerTime: 0
            )
            observer.next(mockLink)
            observer.completed()
            return SimpleDisposable()
        }
    }
    
    func shareDocument(docType: String, documentId: String, localization: String?) -> Signal<ShareVerificationCodesModel, NetworkError> {
        // НЕ делаем реальных запросов - возвращаем мок данные
        print("📄 SharingDocsAPIClient.shareDocument - возвращаем мок данные")
        return Signal { observer in
            // ShareVerificationCodesModel - это Codable, создаем через JSON декодирование
            let mockJSON = """
            {
                "codes": []
            }
            """
            
            if let jsonData = mockJSON.data(using: .utf8),
               let mockCodes = try? JSONDecoder().decode(ShareVerificationCodesModel.self, from: jsonData) {
                observer.next(mockCodes)
                observer.completed()
            } else {
                // Если не удалось создать через JSON, возвращаем ошибку (но не крашим)
                observer.failed(.unknown)
            }
            return SimpleDisposable()
        }
    }
}
