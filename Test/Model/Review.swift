import UIKit
/// Модель отзыва.
struct Review: Decodable {

    /// Ключи JSON-ответа, соответствующие полям структуры `Review`
    enum CodingKeys: String, CodingKey {
        case rating, text, created
        case firstName = "first_name"
        case lastName = "last_name"
        case avatarUrl = "avatar_url"
        case photoCount = "photo_count"
    }
    
    /// ID пользователя
    let id: UUID
    /// Рейтинг пользователя
    let rating: Int
    /// Текст отзыва.
    let text: String
    /// Время создания отзыва.
    let created: String
    /// Имя пользователя
    let firstName: String
    /// Фамилия пользователя
    let lastName: String
    /// URL аватара пользователя
    let avatarUrl: String?
    /// Количество фотографий пользователя
    let photoCount: Int
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.firstName = try container.decode(String.self, forKey: .firstName)
        self.lastName = try container.decode(String.self, forKey: .lastName)
        self.rating = try container.decode(Int.self, forKey: .rating)
        self.text = try container.decode(String.self, forKey: .text)
        self.created = try container.decode(String.self, forKey: .created)
        self.avatarUrl = try container.decodeIfPresent(String.self, forKey: .avatarUrl)
        self.photoCount = try container.decodeIfPresent(Int.self, forKey: .photoCount) ?? 0
    }

}
