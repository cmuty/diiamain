# Интеграция данных пользователя с сервера

## Обзор

Система интегрирована для использования данных пользователя из вашего сервера (`https://diia-backend.onrender.com`) вместо данных с оригинального сервера Diia.

## Основные компоненты

### 1. AuthManager (`Common/Managers/AuthManager.swift`)
Управляет состоянием авторизации и данными пользователя:
- `isAuthenticated` - статус авторизации
- `userFullName` - полное ФИО пользователя (формат: "Прізвище Ім'я По батькові")
- `userBirthDate` - дата рождения (формат: "dd.MM.yyyy")
- `userId` - ID пользователя с сервера

### 2. NetworkManager (`Common/Managers/NetworkManager.swift`)
Обеспечивает взаимодействие с вашим сервером:
- Авторизация через логин/пароль
- Загрузка фотографии пользователя
- Проверка статуса сервера

### 3. User Model (`Common/Models/User.swift`)
Модель пользователя для использования в документах:
```swift
let user = User(from: AuthManager.shared)
// Используйте:
// user.firstName, user.lastName, user.patronymic
// user.birthDate, user.taxId (РНОКПП)
// user.getPhoto() - получить фото
```

### 4. StaticDataGenerator (`Common/Utilities/StaticDataGenerator.swift`)
Генерирует статические данные на основе данных пользователя:
- РНОКПП, номер паспорта, УНЗР
- Место рождения, адрес проживания
- Данные родителей (для свидетельства о рождении)

### 5. UserDataHelper (`Common/Extensions/UserDataExtension.swift`)
Глобальный helper для получения данных пользователя:
```swift
// Получить текущего пользователя
let user = UserDataHelper.getCurrentUser()

// Получить ФИО
let fullName = UserDataHelper.getUserFullName()

// Получить дату рождения
let birthDate = UserDataHelper.getUserBirthDate()

// Получить РНОКПП
let taxId = UserDataHelper.getUserTaxId()

// Получить фото
let photo = UserDataHelper.getUserPhoto()
```

## Использование в документах

### Пример использования данных пользователя:

```swift
import Foundation

// В любом месте приложения, где нужно получить данные пользователя:
let user = UserDataHelper.getCurrentUser()

// Использовать данные:
let fullName = user.userFullName // "Прізвище Ім'я По батькові"
let firstName = user.firstName
let lastName = user.lastName
let patronymic = user.patronymic
let birthDate = user.birthDate
let taxId = user.taxId // РНОКПП

// Получить фото
if let photoData = user.getPhoto(), let image = UIImage(data: photoData) {
    // Использовать изображение
}
```

## Авторизация

При авторизации через логин/пароль:
1. Данные пользователя загружаются с сервера
2. Сохраняются в `AuthManager`
3. Фотография загружается и сохраняется в `UserDefaults` с ключом `"userPhoto"`
4. Данные сохраняются в `UserDefaults` для использования в документах:
   - `documentUserFullName`
   - `documentUserBirthDate`
   - `documentUserTaxId`
   - `documentUserFirstName`
   - `documentUserLastName`
   - `documentUserPatronymic`

## Генерация статических данных

Статические данные (РНОКПП, место рождения и т.д.) генерируются один раз при первом входе и сохраняются в `UserDefaults`:
- `userRNOKPP` - РНОКПП
- `userPassportNumber` - номер паспорта
- `userBirthPlace` - место рождения
- `userResidenceRegion`, `userResidenceCity` и т.д. - адрес проживания

## Проверка данных

Для проверки наличия данных пользователя:
```swift
if UserDataHelper.hasUserData() {
    // Данные пользователя доступны
    let user = UserDataHelper.getCurrentUser()
}
```

## Интеграция с документами

Данные пользователя автоматически используются при:
1. Авторизации - данные сохраняются в `UserDefaults`
2. Загрузке документов - данные доступны через `UserDataHelper`
3. Отображении документов - используйте `UserDataHelper.getCurrentUser()`

## Пример замены данных в документах

Если нужно заменить данные в существующих документах:

```swift
// Получить данные пользователя
let user = UserDataHelper.getCurrentUser()

// Использовать данные пользователя вместо данных с сервера
// Например, в view model документа:
let displayName = user.userFullName
let displayBirthDate = user.birthDate
let displayTaxId = user.taxId
```

## Важно

- Данные пользователя приоритетны над данными с оригинального сервера Diia
- Фотография загружается с вашего сервера по endpoint: `/api/photo/{userId}`
- Все данные сохраняются локально для offline использования
- Статические данные генерируются один раз и остаются постоянными

