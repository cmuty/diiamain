import Foundation
import ReactiveKit
import DiiaNetwork
import DiiaCommonTypes

class DocumentReorderingAPIClient: ApiClient<DocumentReorderingAPI> {
    
    // ВАЖНО: Полностью отвязаны от сервера - возвращаем мок данные
    override init() {
        super.init()
        print("✅ DocumentReorderingAPIClient инициализирован - используем только мок данные")
    }
    
    func sendDocumentsOrder(order: [DocType]) -> Signal<SuccessResponse, NetworkError> {
        // НЕ делаем реальных запросов - возвращаем успешный мок ответ
        print("📄 DocumentReorderingAPIClient.sendDocumentsOrder - возвращаем мок успех")
        return Signal { observer in
            let mockResponse = SuccessResponse(success: true)
            observer.next(mockResponse)
            observer.completed()
            return SimpleDisposable()
        }
    }
    
    func sendOrder(order: [String], for documentType: DocType) -> Signal<SuccessResponse, NetworkError> {
        // НЕ делаем реальных запросов - возвращаем успешный мок ответ
        print("📄 DocumentReorderingAPIClient.sendOrder - возвращаем мок успех")
        return Signal { observer in
            let mockResponse = SuccessResponse(success: true)
            observer.next(mockResponse)
            observer.completed()
            return SimpleDisposable()
        }
    }
}
