final class ReviewsScreenFactory {

    /// Создаёт контроллер списка отзывов, проставляя нужные зависимости.
    func makeReviewsController() -> ReviewsViewController {
        let reviewsProvider = ReviewsProvider()
        let cacheManager = PhotoCacheManager()
        let avatarNetworkService = PhotoNetworkService(cacheManager: cacheManager)
        let viewModel = ReviewsViewModel(reviewsProvider: reviewsProvider, networkService: avatarNetworkService)
        let controller = ReviewsViewController(viewModel: viewModel)
        return controller
    }

}
