import UIKit

final class PhotoCacheManager {
    
    private let folderName = "Photos_сache"
    
    init() {
        createFolderIfNeeded()
    }
    
}

// MARK: – Internal

extension PhotoCacheManager {
    
    /// Сохраняет изображение в кэш
    func saveImage(_ image: UIImage, imageName: String) {
        guard let data = image.pngData(),
              let url = getImageURL(imageName: imageName)
        else { return }
        
        do {
            try data.write(to: url)
        } catch {
            print("Ошибка сохранения фото: \(error)")
        }
    }
    
    /// Загружает изображение из кэша
    func getImage(imageName: String) -> UIImage? {
        guard let url = getImageURL(imageName: imageName),
              FileManager.default.fileExists(atPath: url.path)
        else { return nil }
        
        return UIImage(contentsOfFile: url.path)
    }
    
}

// MARK: – Private

private extension PhotoCacheManager {
    
    /// Создаёт папку для хранения изображений, если её нет
    private func createFolderIfNeeded() {
        guard let url = getFolderURL() else { return }
        
        if !FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            } catch {
                print("Ошибка создания папки для кэша: \(error)")
            }
        }
    }
    
    /// Получает путь к папке
    private func getFolderURL() -> URL? {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent(folderName)
    }
    
    /// Получает путь к конкретному изображению
    private func getImageURL(imageName: String) -> URL? {
        getFolderURL()?.appendingPathComponent(imageName)
    }
    
}
