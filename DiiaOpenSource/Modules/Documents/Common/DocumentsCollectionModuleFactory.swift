import Foundation
import DiiaNetwork
import ReactiveKit
import DiiaDocumentsCommonTypes
import DiiaDocumentsCore

extension DocumentsCoreNetworkContext {
    static func create() -> DocumentsCoreNetworkContext {
        // ВАЖНО: Используем пустой host, чтобы не делать реальных запросов к серверу Diia
        // Все запросы к документам идут через мок API клиент
        print("✅ DocumentsCoreNetworkContext.create - используем мок host (без реальных запросов)")
        return .init(session: NetworkConfiguration.default.session,
                    host: "", // Пустой host - не делаем реальных запросов
                    headers: ["App-Version": AppConstants.App.appVersion,
                              "Platform-Type": AppConstants.App.platform,
                              "Platform-Version": AppConstants.App.iOSVersion,
                              "mobile_uid": AppConstants.App.mobileUID,
                              "User-Agent": AppConstants.App.userAgent])
    }
}
struct DocumentsCollectionModuleFactory {
    static func create(holder: DocumentCollectionHolderProtocol) -> DocumentsCollectionModule {
        
        let reorderingConfig = DocumentsReorderingConfiguration(createReorderingModule: { DocumentsReorderingModule() },
                                                                documentsReorderingService: DocumentReorderingService.shared)
        return  .init(context: .init(network: .create(),
                                     documentsLoader: ServicesProvider.shared.documentsLoader,
                                     docProvider: DocumentsProcessor(),
                                     documentsStackRouterCreate: {
                                        DocumentsStackRouter(docType: $0, docProvider: DocumentsProcessor())
                                     },
                                     actionFabricAllowedCodes: [DocType.driverLicense.docCode],
                                     documentsReorderingConfiguration: reorderingConfig,
                                     pushNotificationsSharingSubject: PassthroughSubject<Void, Never>(),
                                     addDocumentsActionProvider: AddDocumentsActionProvider(),
                                     imageNameProvider: DSImageNameResolver.instance,
                                     screenBrightnessService: ScreenBrightnessHelper.shared),
                      holder: holder
        )
    }
}
