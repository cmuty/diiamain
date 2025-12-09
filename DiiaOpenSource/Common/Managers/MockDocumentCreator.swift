import Foundation
import DiiaDocumentsCommonTypes

/// Сервис для создания мок документов с данными пользователя
class MockDocumentCreator {
    static let shared = MockDocumentCreator()
    
    private init() {}
    
    /// Создать мок JSON для водительских прав с данными пользователя
    func createMockDriverLicenseJSON(user: User) -> String {
        // Форматируем дату рождения для документа (DD.MM.YYYY -> YYYY-MM-DD для некоторых полей)
        let birthDateParts = user.birthDate.components(separatedBy: ".")
        let birthYear = birthDateParts.count == 3 ? birthDateParts[2] : "2008"
        let birthMonth = birthDateParts.count == 3 ? birthDateParts[1] : "01"
        let birthDay = birthDateParts.count == 3 ? birthDateParts[0] : "07"
        
        // Вычисляем дату выдачи (например, 3 года назад от сегодня)
        let calendar = Calendar.current
        let issueDate = calendar.date(byAdding: .year, value: -3, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let issueDateString = formatter.string(from: issueDate)
        
        // Вычисляем дату окончания (через 10 лет от даты выдачи)
        let expiryDate = calendar.date(byAdding: .year, value: 10, to: issueDate) ?? Date()
        let expiryDateString = formatter.string(from: expiryDate)
        
        // Создаем мок JSON для водительских прав
        let mockJSON = """
        {
            "data": [
                {
                    "docNumber": "ААА123456",
                    "docData": {
                        "fName": "\(user.firstName)",
                        "lName": "\(user.lastName)",
                        "mName": "\(user.patronymic)",
                        "birthday": "\(birthYear)-\(birthMonth)-\(birthDay)",
                        "birthPlace": "\(user.birthPlace)",
                        "docNumber": "ААА123456",
                        "dateIssue": "\(issueDateString)",
                        "dateExpiry": "\(expiryDateString)",
                        "department": "ДПС України",
                        "categories": ["B", "C"],
                        "validUntil": null,
                        "status": "ok"
                    },
                    "shareLocalization": {
                        "ua": {
                            "fName": "\(user.firstName)",
                            "lName": "\(user.lastName)",
                            "mName": "\(user.patronymic)",
                            "birthday": "\(user.birthDate)",
                            "birthPlace": "\(user.birthPlace)",
                            "docNumber": "ААА123456",
                            "dateIssue": "\(issueDateString)",
                            "dateExpiry": "\(expiryDateString)",
                            "department": "ДПС України",
                            "categories": ["B", "C"]
                        }
                    }
                }
            ]
        }
        """
        
        return mockJSON
    }
    
    /// Создать мок DSFullDocumentModel из JSON
    func createMockDriverLicense(user: User) -> DSFullDocumentModel? {
        let jsonString = createMockDriverLicenseJSON(user: user)
        guard let jsonData = jsonString.data(using: .utf8) else {
            print("❌ Failed to create JSON data for mock document")
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            let document = try decoder.decode(DSFullDocumentModel.self, from: jsonData)
            print("✅ Created mock driver license for \(user.userFullName)")
            return document
        } catch {
            print("❌ Failed to decode mock document: \(error.localizedDescription)")
            // Если декодирование не удалось, попробуем создать через другой способ
            return createSimpleMockDriverLicense(user: user)
        }
    }
    
    /// Создать простой мок документ если JSON декодирование не работает
    private func createSimpleMockDriverLicense(user: User) -> DSFullDocumentModel? {
        // Попробуем создать минимальный JSON который точно декодируется
        let simpleJSON = """
        {
            "data": [
                {
                    "docNumber": "ААА123456",
                    "docData": {
                        "fName": "\(user.firstName)",
                        "lName": "\(user.lastName)",
                        "mName": "\(user.patronymic)",
                        "birthday": "\(user.birthDate)",
                        "docNumber": "ААА123456",
                        "status": "ok"
                    }
                }
            ]
        }
        """
        
        guard let jsonData = simpleJSON.data(using: .utf8) else { return nil }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(DSFullDocumentModel.self, from: jsonData)
        } catch {
            print("❌ Failed to create simple mock document: \(error.localizedDescription)")
            return nil
        }
    }
}

