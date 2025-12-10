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
            let mockLink = ShareLinkModel(link: "local://mock-share-link")
            observer.next(mockLink)
            observer.completed()
            return SimpleDisposable()
        }
    }
    
    func shareDocument(docType: String, documentId: String, localization: String?) -> Signal<ShareVerificationCodesModel, NetworkError> {
        // НЕ делаем реальных запросов - возвращаем мок данные
        print("📄 SharingDocsAPIClient.shareDocument - возвращаем мок данные")
        return Signal { observer in
            // Возвращаем пустой мок ответ, чтобы не крашить приложение
            let mockCodes = ShareVerificationCodesModel(codes: [])
            observer.next(mockCodes)
            observer.completed()
            return SimpleDisposable()
        }
    }
}
