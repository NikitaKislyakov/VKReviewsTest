import UIKit

final class PhotoNetworkService {
    
    typealias GetPhotoResult = Result<UIImage?, GetPhotoError>

    enum GetPhotoError: Error {
        case badURL
        case badData(Error)
    }
    
    private let cacheManager: PhotoCacheManager
    
    init(cacheManager: PhotoCacheManager) {
        self.cacheManager = cacheManager
    }

    /// Загружает либо использует закэшированное изображение и возвращает через `completion`
    func loadImage(from url: URL, completion: @escaping (GetPhotoResult) -> Void) {
        
        let imageName = url.lastPathComponent
        
        if let cachedImage = cacheManager.getImage(imageName: imageName) {
            DispatchQueue.main.async {
                completion(.success(cachedImage))
            }
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async { completion(.failure(.badData(error))) } 
                return
            }

            guard let data = data, let image = UIImage(data: data) else {
                DispatchQueue.main.async { completion(.failure(.badURL)) }
                return
            }
            
            cacheManager.saveImage(image, imageName: imageName)

            DispatchQueue.main.async {
                completion(.success(image))
            }
        }.resume()
    }
}

// Класс для предоставления фото из Assets

final class PhotoProvider {
    static let shared = PhotoProvider()
    
    func providePhotos(for count: Int) -> [UIImage] {
        guard count > 0 else { return [] }
        
        var photos: [UIImage] = []
        for number in 1...count {
            photos.append(UIImage(named: "IMG_000\(number)")!)
        }
        return photos
    }
}
