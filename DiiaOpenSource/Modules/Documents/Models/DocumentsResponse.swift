import Foundation
import DiiaCommonTypes
import DiiaDocumentsCommonTypes

// MARK: - DocumentsResponse
public struct DocumentsResponse: Codable {
    public let driverLicense: DSFullDocumentModel?
    public let idCard: DSFullDocumentModel?
    public let birthCertificate: DSFullDocumentModel?
    public let passport: DSFullDocumentModel?

    let documentsTypeOrder: [String]?

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let driverLicenseFailable = try container.decodeIfPresent(FailableDecodable<DSFullDocumentModel>.self, forKey: .driverLicense)
        driverLicense = driverLicenseFailable?.value

        let idCardFailable = try container.decodeIfPresent(FailableDecodable<DSFullDocumentModel>.self, forKey: .idCard)
        idCard = idCardFailable?.value

        let birthCertificateFailable = try container.decodeIfPresent(FailableDecodable<DSFullDocumentModel>.self, forKey: .birthCertificate)
        birthCertificate = birthCertificateFailable?.value

        let passportFailable = try container.decodeIfPresent(FailableDecodable<DSFullDocumentModel>.self, forKey: .passport)
        passport = passportFailable?.value

        documentsTypeOrder = try container.decodeIfPresent([String].self, forKey: .documentsTypeOrder)
    }
    
    // Инициализатор для создания мок-ответа
    public init(driverLicense: DSFullDocumentModel?, idCard: DSFullDocumentModel?, birthCertificate: DSFullDocumentModel?, passport: DSFullDocumentModel?, documentsTypeOrder: [String]?) {
        self.driverLicense = driverLicense
        self.idCard = idCard
        self.birthCertificate = birthCertificate
        self.passport = passport
        self.documentsTypeOrder = documentsTypeOrder
    }
}
