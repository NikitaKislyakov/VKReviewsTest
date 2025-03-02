import UIKit

/// Класс, описывающий бизнес-логику экрана отзывов.
final class ReviewsViewModel: NSObject {
    
    /// Замыкание, вызываемое при изменении `state`.
    var onStateChange: ((State) -> Void)?
    
    private var state: State
    private let reviewsProvider: ReviewsProvider
    private let ratingRenderer: RatingRenderer
    private let decoder: JSONDecoder
    private let networkService: PhotoNetworkService
    
    init(
        state: State = State(),
        reviewsProvider: ReviewsProvider = ReviewsProvider(),
        ratingRenderer: RatingRenderer = RatingRenderer(),
        decoder: JSONDecoder = JSONDecoder(),
        networkService: PhotoNetworkService
    ) {
        self.state = state
        self.reviewsProvider = reviewsProvider
        self.ratingRenderer = ratingRenderer
        self.decoder = decoder
        self.networkService = networkService
    }
    
}

// MARK: - Internal

extension ReviewsViewModel {
    
    typealias State = ReviewsViewModelState
    
    /// Метод получения отзывов.
    func getReviews() {
        guard state.shouldLoad else { return }
        state.shouldLoad = false
        DispatchQueue.global(qos: .userInitiated).async {
            self.reviewsProvider.getReviews(offset: self.state.offset) { [weak self] result in
                DispatchQueue.main.async {
                    self?.gotReviews(result)
                }
            }
        }
    }
    
}

// MARK: - Private

private extension ReviewsViewModel {
    
    /// Метод обработки получения отзывов.
    func gotReviews(_ result: ReviewsProvider.GetReviewsResult) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let strongSelf = self else { return }
            do {
                let data = try result.get()
                let reviews = try strongSelf.decoder.decode(Reviews.self, from: data)
                let newItems: [any TableCellConfig] = reviews.items.map(strongSelf.makeReviewItem)
                
                DispatchQueue.main.async {
                    strongSelf.state.items += newItems
                    strongSelf.state.offset += strongSelf.state.limit
                    strongSelf.state.shouldLoad = strongSelf.state.offset < reviews.count
                    
                    if !strongSelf.state.shouldLoad {
                        let countItem = strongSelf.makeReviewCountItem(reviews.count)
                        strongSelf.state.items.append(countItem)
                    }
                    
                    strongSelf.onStateChange?(strongSelf.state)
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.state.shouldLoad = true
                    print("Ошибка загрузки отзывов:", error)
                }
            }
        }
    }
    
    /// Метод, вызываемый при нажатии на кнопку "Показать полностью...".
    /// Снимает ограничение на количество строк текста отзыва (раскрывает текст).
    func showMoreReview(with id: UUID) {
        guard
            let index = state.items.firstIndex(where: { ($0 as? ReviewItem)?.id == id }),
            var item = state.items[index] as? ReviewItem
        else { return }
        item.maxLines = .zero
        state.items[index] = item
        onStateChange?(state)
    }
    
    /// Асинхронно загружает аватар пользователя и обновляет UI.
    /// - Parameter review: Объект `Review`, для которого загружается аватар.
    /// - Загружает изображение по `avatarUrl`, обновляет `avatarImage` в `state.items`
    func loadAvatar(for review: Review) {
        guard let avatarUrl = review.avatarUrl.flatMap({ URL(string: $0) }) else { return }
        
        networkService.loadImage(from: avatarUrl) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let image):
                    if let index = self.state.items.firstIndex(where: { ($0 as? ReviewCellConfig)?.id == review.id }) {
                        var updatedItem = self.state.items[index] as! ReviewCellConfig
                        updatedItem.avatarImage = image
                        self.state.items[index]
                        self.state.items[index] = updatedItem
                        self.onStateChange?(self.state)
                    }
                case .failure(let error):
                    print("Ошибка загрузки аватара: \(error)")
                    return
                }
            }
        }
    }
    
    /// Загружает и обновляет фотографии отзыва.
    /// Асинхронно загружает изображения по `photosURLs` и добавляет их в `userImages`
    /// соответствующего `ReviewCellConfig`.
    func loadPhotos(for review: Review) {
        let urlArray = review.photosURLs
        
        guard !urlArray.isEmpty else { return }
        
        
        for (index, urlString) in urlArray.enumerated() {
            guard let url = URL(string: urlString) else { continue }
            
            networkService.loadImage(from: url) { [weak self] result in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    switch result {
                    case .success(let image):
                        if let indexInState = self.state.items.firstIndex(where: { ($0 as? ReviewCellConfig)?.id == review.id }),
                           let image = image {
                            
                            var updatedItem = self.state.items[indexInState] as! ReviewCellConfig
                            
                            if index < updatedItem.userImages.count {
                                updatedItem.userImages[index] = image
                            } else {
                                updatedItem.userImages.append(image)
                            }
                            
                            self.state.items[indexInState] = updatedItem
                            self.onStateChange?(self.state)
                        }
                    case .failure(let error):
                        print("Ошибка загрузки фото: \(error)")
                    }
                }
            }
        }
    }
    
}

// MARK: - Items

private extension ReviewsViewModel {
    
    typealias ReviewItem = ReviewCellConfig
    typealias ReviewCountItem = ReviewCountCellConfig
    
    func makeReviewItem(_ review: Review) -> ReviewCellConfig {
        let reviewText = review.text.attributed(font: .text)
        let created = review.created.attributed(font: .created, color: .created)
        let firstName = review.firstName
        let lastName = review.lastName
        let userName = (firstName + " " + lastName).attributed(font: .username)
        let rating = review.rating
        let ratingImage = ratingRenderer.ratingImage(rating)
        let placeholderImage = UIImage(named: "l5w5aIHioYc")
        
        DispatchQueue.main.async { [weak self] in
            self?.loadAvatar(for: review)
            self?.loadPhotos(for: review)
        }
        
        return ReviewCellConfig(
            id: review.id,
            reviewText: reviewText,
            created: created,
            onTapShowMore: showMoreReview,
            avatarImage: placeholderImage,
            userName: userName,
            ratingImage: ratingImage,
            userImages: []
        )
    }
    
    func makeReviewCountItem(_ count: Int) -> ReviewCountItem {
        ReviewCountCellConfig(reviewCount: count)
    }
}

// MARK: - UITableViewDataSource

extension ReviewsViewModel: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        state.items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let config = state.items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: config.reuseId, for: indexPath)
        
        config.update(cell: cell)
        
        if let reviewCell = cell as? ReviewCell, let reviewConfig = config as? ReviewCellConfig {
            reviewCell.configure(with: reviewConfig.userImages)
        }
        
        return cell
    }
    
}

// MARK: - UITableViewDelegate

extension ReviewsViewModel: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        state.items[indexPath.row].height(with: tableView.bounds.size)
    }
    
    /// Метод дозапрашивает отзывы, если до конца списка отзывов осталось два с половиной экрана по высоте.
    func scrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {
        if shouldLoadNextPage(scrollView: scrollView, targetOffsetY: targetContentOffset.pointee.y) {
            getReviews()
        }
    }
    
    private func shouldLoadNextPage(
        scrollView: UIScrollView,
        targetOffsetY: CGFloat,
        screensToLoadNextPage: Double = 2.5
    ) -> Bool {
        let viewHeight = scrollView.bounds.height
        let contentHeight = scrollView.contentSize.height
        let triggerDistance = viewHeight * screensToLoadNextPage
        let remainingDistance = contentHeight - viewHeight - targetOffsetY
        return remainingDistance <= triggerDistance
    }
    
}
