import Foundation
import ReactiveKit
import DiiaDocumentsCommonTypes
import DiiaDocumentsCore

struct WeakReference<T: AnyObject> {
    weak var value: T?
}

class DocumentsLoader: NSObject, DocumentsLoaderProtocol {
    
    private let apiClient: DocumentsAPIClientProtocol
    private var storeHelper: StoreHelperProtocol
    private let orderService: DocumentReorderingServiceProtocol

    private var listeners: [WeakReference<DocumentsLoadingListenerProtocol>] = []

    private var irrelevantDocs: [DocTypeCode] = []
    private var isUpdating: Bool = false
    private var haveUpdates: Bool = false
    private var needUpdates: Bool = false

    override init() {
        fatalError("init() has not been implemented")
    }

    init(storage: StoreHelperProtocol,
         apiClient: DocumentsAPIClientProtocol,
         orderService: DocumentReorderingServiceProtocol) {
        self.storeHelper = storage
        self.apiClient = apiClient
        self.orderService = orderService
        super.init()
    }

    func setNeedUpdates() {
        // При первом вызове проверяем, есть ли документы, и если нет - создаем их сразу
        ensureDocumentsExist()
        
        if !isUpdating {
            updateIfNeeded()
        } else {
            needUpdates = true
        }
    }
    
    // Безопасно создает документы, если их нет (вызывается сразу, не блокирует UI)
    private func ensureDocumentsExist() {
        let idCard: DSFullDocumentModel? = storeHelper.getValue(forKey: .idCard)
        let birthCert: DSFullDocumentModel? = storeHelper.getValue(forKey: .birthCertificate)
        let passport: DSFullDocumentModel? = storeHelper.getValue(forKey: .passport)
        
        // Если документов нет - создаем их сразу через API клиент
        if idCard == nil && birthCert == nil && passport == nil {
            print("⚠️ Документов нет, создаем мок документы сразу")
            // Создаем документы асинхронно, но сразу
            apiClient.getDocuments([]).observe { [weak self] (event) in
                guard let self = self else { return }
                switch event {
                case .completed:
                    print("✅ Документы успешно созданы")
                case .failed(let error):
                    print("⚠️ Failed to create documents: \(error.localizedDescription)")
                case .next(let documentsResponse):
                    self.orderService.setOrder(order: documentsResponse.documentsTypeOrder ?? [], synchronize: false)
                    self.saveDocs(documentsResponse: documentsResponse)
                    self.actualizeLastDocUpdate()
                    self.haveUpdates = true
                    // Уведомляем слушателей о новых документах
                    DispatchQueue.main.async {
                        self.listeners.forEach { $0.value?.documentsWasUpdated() }
                    }
                }
            }.dispose(in: bag)
        } else {
            // Устанавливаем порядок документов, если он не установлен
            let currentOrder = orderService.docTypesOrder()
            if currentOrder.isEmpty {
                let defaultOrder = ["id-card", "birth-certificate", "passport"]
                orderService.setOrder(order: defaultOrder, synchronize: false)
                print("✅ Установлен дефолтный порядок документов")
            }
        }
    }

    func updateIfNeeded() {
        if isUpdating {
            log("===> Already updating!")
            return
        }
        isUpdating = true
        haveUpdates = false

        checkDocumentsActuallity()

        let group = DispatchGroup()
        fetchDocs(in: group)

        group.notify(queue: .main) { [weak self] in
            defer {
                if self?.needUpdates == true {
                    self?.needUpdates = false
                    self?.updateIfNeeded()
                }
            }
            self?.isUpdating = false
            guard let self = self, self.haveUpdates else { return }
            self.haveUpdates = false
            self.listeners.forEach { $0.value?.documentsWasUpdated() }
        }
    }

    func addListener(listener: DocumentsLoadingListenerProtocol) {
        listeners.append(WeakReference(value: listener))
        // При добавлении слушателя проверяем, есть ли документы, и если нет - создаем их сразу
        ensureDocumentsExist()
    }

    func removeListener(listener: DocumentsLoadingListenerProtocol) {
        listeners.removeAll(where: { $0.value === listener })
    }

    // MARK: - Checking
    private func checkDocumentsActuallity() {
        irrelevantDocs = []
        var order: [DocType] = orderService.docTypesOrder().compactMap { DocType(rawValue: $0) }
        
        // Если order пустой, используем дефолтный порядок для наших трех документов
        if order.isEmpty {
            // Устанавливаем порядок: ID-документ, свидетельство о рождении, паспорт
            order = [.idCard, .birthCertificate, .passport]
            // Сохраняем дефолтный порядок
            orderService.setOrder(order: order.map { $0.rawValue }, synchronize: false)
        }

        for type in order {
            switch type {
            case .driverLicense:
                checkDoc(type: DSFullDocumentModel.self, docType: .driverLicense, storingKey: .driverLicense)
            case .taxpayerСard:
                irrelevantDocs.append(DocType.taxpayerСard.rawValue)
            case .idCard:
                checkDoc(type: DSFullDocumentModel.self, docType: .idCard, storingKey: .idCard)
            case .birthCertificate:
                checkDoc(type: DSFullDocumentModel.self, docType: .birthCertificate, storingKey: .birthCertificate)
            case .passport:
                checkDoc(type: DSFullDocumentModel.self, docType: .passport, storingKey: .passport)
            }
        }
        
        // Если документов нет - добавляем все три документа для загрузки ВСЕГДА (даже без авторизации)
        if irrelevantDocs.isEmpty {
            let idCard: DSFullDocumentModel? = storeHelper.getValue(forKey: .idCard)
            let birthCert: DSFullDocumentModel? = storeHelper.getValue(forKey: .birthCertificate)
            let passport: DSFullDocumentModel? = storeHelper.getValue(forKey: .passport)
            
            if idCard == nil {
                irrelevantDocs.append(DocType.idCard.rawValue)
                print("✅ Добавлен idCard в irrelevantDocs для загрузки")
            }
            if birthCert == nil {
                irrelevantDocs.append(DocType.birthCertificate.rawValue)
                print("✅ Добавлен birthCertificate в irrelevantDocs для загрузки")
            }
            if passport == nil {
                irrelevantDocs.append(DocType.passport.rawValue)
                print("✅ Добавлен passport в irrelevantDocs для загрузки")
            }
        }
    }

    fileprivate func checkDoc<T>(type: T.Type, docType: DocType, storingKey: StoringKey) where T: StatusedExpirableProtocol {
        if let doc: T = storeHelper.getValue(forKey: storingKey) {
            log("\(docType.name) -> expiration date \(doc.expirationDate.toShortTimeString()). Current date - \(Date().toShortTimeString()).\(doc.expirationDate < Date() ? " Need update" : "")")
            if doc.expirationDate < Date() || doc.status == .documentProcessing {
                irrelevantDocs.append(docType.rawValue)
            }
        } else {
            irrelevantDocs.append(docType.rawValue)
        }
    }

    private func fetchDocs(in group: DispatchGroup) {
        guard irrelevantDocs.count > 0 else {
            // Если нет документов для загрузки - проверяем сохраненные ВСЕГДА (даже без авторизации)
            let idCard: DSFullDocumentModel? = storeHelper.getValue(forKey: .idCard)
            let birthCert: DSFullDocumentModel? = storeHelper.getValue(forKey: .birthCertificate)
            let passport: DSFullDocumentModel? = storeHelper.getValue(forKey: .passport)
            
            if idCard != nil || birthCert != nil || passport != nil {
                // Документы уже есть, просто уведомляем слушателей
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.haveUpdates = true
                    self.isUpdating = false
                    self.listeners.forEach { $0.value?.documentsWasUpdated() }
                }
            } else {
                // Если документов нет вообще - создаем их через API клиент
                print("⚠️ Документов нет, создаем через API клиент")
                group.enter()
                apiClient.getDocuments([]).observe { [weak self] (event) in
                    guard let self = self else {
                        group.leave()
                        return
                    }
                    switch event {
                    case .completed:
                        group.leave()
                    case .failed(let error):
                        print("⚠️ Failed to create documents: \(error.localizedDescription)")
                        group.leave()
                    case .next(let documentsResponse):
                        self.orderService.setOrder(order: documentsResponse.documentsTypeOrder ?? [], synchronize: false)
                        self.saveDocs(documentsResponse: documentsResponse)
                        self.actualizeLastDocUpdate()
                        self.haveUpdates = true
                        group.leave()
                    }
                }.dispose(in: bag)
            }
            return
        }

        group.enter()
        apiClient.getDocuments(irrelevantDocs).observe { [weak self] (event) in
            guard let self = self else { 
                group.leave()
                return 
            }
            self.irrelevantDocs = []
            switch event {
            case .completed:
                group.leave()
            case .failed(let error):
                print("⚠️ Failed to fetch documents: \(error.localizedDescription)")
                // При ошибке не показываем ошибку пользователю, просто используем сохраненные документы
                group.leave()
            case .next(let documentsResponse):
                self.orderService.setOrder(order: documentsResponse.documentsTypeOrder ?? [], synchronize: false)
                self.saveDocs(documentsResponse: documentsResponse)
                self.actualizeLastDocUpdate()
                self.haveUpdates = true
                group.leave()
            }
        }.dispose(in: bag)
    }
    
    // MARK: - Saving
    func saveDoc<T>(_ doc: T?, type: T.Type, forKey key: StoringKey, orderType: DocType? = nil) where T: Codable&StatusedExpirableProtocol {
        if let doc = doc {
            if doc.status == .ok || doc.status == .notFound {
                storeHelper.save(doc, type: T.self, forKey: key)
                if let orderType = orderType { DocumentReorderingService.shared.cleanSynchronized(for: orderType.rawValue) }
            } else if var storedDoc: T = storeHelper.getValue(forKey: key) {
                storedDoc.expirationDate = doc.expirationDate
                storeHelper.save(storedDoc, type: T.self, forKey: key)
            } else {
                storeHelper.save(doc, type: T.self, forKey: key)
            }
        }
    }
    
    func saveDocs(documentsResponse: DocumentsResponse) {
        // Используем данные пользователя из AuthManager вместо данных с сервера
        // если пользователь авторизован через нашу систему
        if UserDataDocumentsAdapter.shared.shouldUseUserData() {
            // Сохраняем данные пользователя для использования в документах
            let user = UserDataDocumentsAdapter.shared.getUserDataForDocuments()
            UserDefaults.standard.set(user.userFullName, forKey: "documentUserFullName")
            UserDefaults.standard.set(user.birthDate, forKey: "documentUserBirthDate")
            UserDefaults.standard.set(user.taxId, forKey: "documentUserTaxId")
        }
        
        // Сохраняем все типы документов
        if let driverLicense = documentsResponse.driverLicense {
            let savedDriverLicense: DSFullDocumentModel? = storeHelper.getValue(forKey: .driverLicense)
            saveDoc(driverLicense.withLocalization(shareLocalization: savedDriverLicense?.data.first?.shareLocalization ?? .ua),
                    type: DSFullDocumentModel.self,
                    forKey: .driverLicense,
                    orderType: .driverLicense)
        }
        
        if let idCard = documentsResponse.idCard {
            let savedIdCard: DSFullDocumentModel? = storeHelper.getValue(forKey: .idCard)
            saveDoc(idCard.withLocalization(shareLocalization: savedIdCard?.data.first?.shareLocalization ?? .ua),
                    type: DSFullDocumentModel.self,
                    forKey: .idCard,
                    orderType: .idCard)
        }
        
        if let birthCertificate = documentsResponse.birthCertificate {
            let savedBirthCert: DSFullDocumentModel? = storeHelper.getValue(forKey: .birthCertificate)
            saveDoc(birthCertificate.withLocalization(shareLocalization: savedBirthCert?.data.first?.shareLocalization ?? .ua),
                    type: DSFullDocumentModel.self,
                    forKey: .birthCertificate,
                    orderType: .birthCertificate)
        }
        
        if let passport = documentsResponse.passport {
            let savedPassport: DSFullDocumentModel? = storeHelper.getValue(forKey: .passport)
            saveDoc(passport.withLocalization(shareLocalization: savedPassport?.data.first?.shareLocalization ?? .ua),
                    type: DSFullDocumentModel.self,
                    forKey: .passport,
                    orderType: .passport)
        }
    }
    
    // MARK: - Helping
    private func actualizeLastDocUpdate() {
        let dateFormatter = Formatter.iso8601withFractionalSeconds
        let currentDateString = dateFormatter.string(from: Date())
        storeHelper.save(currentDateString, type: String.self, forKey: .lastDocumentUpdate)
    }
}
