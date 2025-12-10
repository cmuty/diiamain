import UIKit
import DiiaMVPModule
import DiiaCommonTypes
import DiiaDocumentsCommonTypes
import DiiaDocumentsCore
import DiiaDocuments

class DocumentsProcessor {
    private let storeHelper: StoreHelperProtocol
    
    init(storeHelper: StoreHelperProtocol = StoreHelper.instance) {
        self.storeHelper = storeHelper
    }
    
    func documents(with order: [DocTypeCode], actionView: BaseView?) -> [MultiDataType<DocumentModel>] {
        print("📄 DocumentsProcessor.documents вызван с порядком: \(order)")
        
        let docTypesOrder: [DocType] = order.compactMap({ DocType(rawValue: $0)})
        print("📄 Обработанные типы документов: \(docTypesOrder.map { $0.rawValue })")
        
        let documents = docTypesOrder.compactMap { docType -> MultiDataType<DocumentModel>? in
            switch docType {
            case .driverLicense:
                let driverLicense: DSFullDocumentModel? = storeHelper.getValue(forKey: .driverLicense)
                let cards = processDriverLicenses(licenses: driverLicense)
                print("📄 Водительские права: \(cards.count) карточек")
                return makeMultiple(cards: cards)
            case .taxpayerСard:
                return nil
            case .idCard:
                let idCard: DSFullDocumentModel? = storeHelper.getValue(forKey: .idCard)
                print("📄 ID-документ: \(idCard != nil ? "найден" : "НЕ НАЙДЕН")")
                let cards = processGenericDocument(document: idCard, docType: .idCard)
                print("📄 ID-документ: \(cards.count) карточек создано")
                return makeMultiple(cards: cards)
            case .birthCertificate:
                let birthCert: DSFullDocumentModel? = storeHelper.getValue(forKey: .birthCertificate)
                print("📄 Свидетельство о рождении: \(birthCert != nil ? "найдено" : "НЕ НАЙДЕНО")")
                let cards = processGenericDocument(document: birthCert, docType: .birthCertificate)
                print("📄 Свидетельство о рождении: \(cards.count) карточек создано")
                return makeMultiple(cards: cards)
            case .passport:
                let passport: DSFullDocumentModel? = storeHelper.getValue(forKey: .passport)
                print("📄 Паспорт: \(passport != nil ? "найден" : "НЕ НАЙДЕН")")
                let cards = processGenericDocument(document: passport, docType: .passport)
                print("📄 Паспорт: \(cards.count) карточек создано")
                return makeMultiple(cards: cards)
            }
        }
        
        print("📄 Итого документов для отображения: \(documents.count)")
        return documents
    }
    
    private func makeMultiple(cards: [DocumentModel]) -> MultiDataType<DocumentModel>? {
        if cards.isEmpty {
            return nil
        } else if cards.count == 1 {
            return .single(cards[0])
        } else {
            return .multiple(cards)
        }
    }
    
    private func reorderIfNeeded(documents: [DocumentModel], orderIds: [String]) -> [DocumentModel] {
        if !orderIds.isEmpty {
            var newDocs = documents
            for id in orderIds.reversed() {
                if let index = newDocs.firstIndex(where: { $0.orderIdentifier == id }) {
                    let document = newDocs.remove(at: index)
                    newDocs.insert(document, at: 0)
                }
            }
            return newDocs
        }
        return documents
    }
    
    private func processDriverLicenses(licenses: DSFullDocumentModel?) -> [DocumentModel] {
        guard let licenses = licenses, !licenses.data.isEmpty else {
            print("⚠️ processDriverLicenses: водительские права не найдены или пусты")
            return []
        }
        
        // Используем compactMap для безопасной обработки
        let documents: [DocumentModel] = licenses.data.compactMap { docData -> DocumentModel? in
            guard docData.docData.validUntil == nil else {
                print("⚠️ Водительские права истекли, пропускаем")
                return nil
            }
            
            // Безопасно создаем ViewModel
            return DriverLicenseViewModelFactory().createViewModel(model: docData)
        }
        
        return reorderIfNeeded(documents: documents, orderIds: DocumentReorderingService.shared.order(for: DocType.driverLicense.rawValue))
    }
    
    // Обработка общих документов (ID-документ, свидетельство о рождении, паспорт)
    private func processGenericDocument(document: DSFullDocumentModel?, docType: DocType) -> [DocumentModel] {
        guard let document = document else {
            print("⚠️ processGenericDocument: документ \(docType.rawValue) не найден")
            return []
        }
        
        // Проверяем, что данные не пустые
        guard !document.data.isEmpty else {
            print("⚠️ processGenericDocument: документ \(docType.rawValue) имеет пустой массив data")
            return []
        }
        
        print("✅ processGenericDocument: обрабатываем \(docType.rawValue), данных: \(document.data.count)")
        
        // Создаем ViewModel для каждого типа документа с правильным docType
        // Используем compactMap для безопасной обработки и фильтрации невалидных документов
        let documents: [DocumentModel] = document.data.compactMap { docData -> DocumentModel? in
            // Проверяем, что docData валиден
            guard docData.docData.validUntil == nil else {
                print("⚠️ Документ \(docType.rawValue) истек, пропускаем")
                return nil
            }
            
            print("📄 Создаем ViewModel для \(docType.rawValue)")
            
            // Используем фабрику для создания ViewModel, но с правильным docType через контекст
            // Создаем контекст с правильным docType для каждого документа
            let context = DriverLicenseContext(
                model: docData,
                docType: docType, // Используем правильный тип документа
                reservePhotoService: DocumentsReservePhotoService(),
                sharingApiClient: SharingDocsAPIClient(),
                ratingOpener: RatingServiceOpener(),
                faqOpener: FaqOpener(),
                appRouter: AppRouter.instance,
                replacementModule: nil,
                docReorderingModule: { DocumentsReorderingModule() },
                docStackReorderingModule: { DocumentsStackReorderingModule(docType: docType) },
                storeHelper: DriverLicenseDocumentStorageImpl(storage: StoreHelper.instance),
                urlHandler: URLOpenerImpl()
            )
            
            return DriverLicenseViewModel(context: context)
        }
        
        print("✅ processGenericDocument: создано \(documents.count) ViewModel для \(docType.rawValue)")
        return reorderIfNeeded(documents: documents, orderIds: DocumentReorderingService.shared.order(for: docType.rawValue))
    }
}

extension DocumentsProcessor: DocumentsProvider { }
