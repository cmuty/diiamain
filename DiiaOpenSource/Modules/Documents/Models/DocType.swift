import UIKit
import DiiaDocumentsCommonTypes

enum DocType: String, Codable, CaseIterable {
    case driverLicense = "driver-license"
    case taxpayerСard = "taxpayer-card"
    case idCard = "id-card"
    case birthCertificate = "birth-certificate"
    case passport = "passport"

    init?(rawValue: String) {
        switch rawValue {
        case "driver-license", "driverLicense":
            self = .driverLicense
        case "taxpayer-card", "taxpayerСard":
            self = .taxpayerСard
        case "id-card", "idCard":
            self = .idCard
        case "birth-certificate", "birthCertificate":
            self = .birthCertificate
        case "passport":
            self = .passport
        default:
            return nil
        }
    }
    
    var name: String {
        switch self {
        case .driverLicense:
            return R.Strings.driver_document_name.localized()
        case .taxpayerСard:
            return ""
        case .idCard:
            return "ID-документ"
        case .birthCertificate:
            return "Свідоцтво про народження"
        case .passport:
            return "Паспорт громадянина України"
        }
    }

    var stackName: String {
        return name
    }

    static var allCardTypes: [DocType] {
        return DocType.allCases
    }

    var faqCategoryId: String {
        switch self {
        case .driverLicense: return "driverLicense"
        case .taxpayerСard: return ""
        case .idCard: return "idCard"
        case .birthCertificate: return "birthCertificate"
        case .passport: return "passport"
        }
    }

    func storingKey() -> StoringKey? {
        switch self {
        case .driverLicense:
            return .driverLicense
        case .taxpayerСard:
            return nil
        case .idCard:
            return .idCard
        case .birthCertificate:
            return .birthCertificate
        case .passport:
            return .passport
        }
    }
}

extension DocType: DocumentAttributesProtocol {
    var docCode: DocTypeCode { return self.rawValue }

    func warningModel() -> WarningModel? {
        return nil
    }

    var stackIconAppearance: DocumentStackIconAppearance {
        return .black
    }

    var isStaticDoc: Bool {
        return false
    }

    func isDocCodeSameAs(otherDocCode: DocTypeCode) -> Bool {
        DocType(rawValue: docCode) == DocType(rawValue: otherDocCode)
    }
}
