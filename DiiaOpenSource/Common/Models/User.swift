import Foundation

struct User {
    let firstName: String
    let lastName: String
    let patronymic: String
    let birthDate: String
    let taxId: String
    let photoName: String
    let birthPlace: String
    let residenceAddress: StaticDataGenerator.ResidenceAddress
    
    // Создаём User из данных AuthManager
    init(from authManager: AuthManager) {
        // Парсим ФИО из full_name (формат: "Прізвище Ім'я По батькові")
        let nameParts = authManager.userFullName.components(separatedBy: " ")
        
        if nameParts.count >= 3 {
            self.lastName = nameParts[0]
            self.firstName = nameParts[1]
            self.patronymic = nameParts[2...].joined(separator: " ")
        } else if nameParts.count == 2 {
            self.lastName = nameParts[0]
            self.firstName = nameParts[1]
            self.patronymic = ""
        } else if nameParts.count == 1 {
            self.lastName = nameParts[0]
            self.firstName = ""
            self.patronymic = ""
        } else {
            // Fallback на username
            self.lastName = authManager.userName
            self.firstName = ""
            self.patronymic = ""
        }
        
        self.birthDate = authManager.userBirthDate
        self.taxId = StaticDataGenerator.shared.getRNOKPP()
        self.birthPlace = StaticDataGenerator.shared.getBirthPlace()
        self.residenceAddress = StaticDataGenerator.shared.getResidenceAddress()
        self.photoName = "user_photo"
    }
    
    // Direct initializer для тестов и fallback
    init(firstName: String, lastName: String, patronymic: String, birthDate: String, taxId: String, photoName: String, birthPlace: String = "Україна, Харківська обл., м. Харків", residenceAddress: StaticDataGenerator.ResidenceAddress? = nil) {
        self.firstName = firstName
        self.lastName = lastName
        self.patronymic = patronymic
        self.birthDate = birthDate
        self.taxId = taxId
        self.birthPlace = birthPlace
        self.residenceAddress = residenceAddress ?? StaticDataGenerator.ResidenceAddress(
            region: "Харківська",
            city: "Харків",
            district: "Харківський",
            streetType: "пров.",
            streetName: "Білостоцький",
            buildingNumber: "47"
        )
        self.photoName = photoName
    }
    
    // Mock для превью и тестов
    static let mock = User(
        firstName: "Богдан",
        lastName: "Зарва",
        patronymic: "Олегович",
        birthDate: "07.01.2010",
        taxId: "4018401651",
        photoName: "user_photo",
        birthPlace: "Україна, Харківська обл., м. Харків"
    )
    
    // Получить фото пользователя из UserDefaults
    func getPhoto() -> Data? {
        return UserDefaults.standard.data(forKey: "userPhoto")
    }
    
    // Получить полное ФИО
    var userFullName: String {
        return "\(lastName) \(firstName) \(patronymic)".trimmingCharacters(in: .whitespaces)
    }
}

