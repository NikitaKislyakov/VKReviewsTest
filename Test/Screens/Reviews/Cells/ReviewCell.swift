import UIKit

/// Конфигурация ячейки. Содержит данные для отображения в ячейке.
struct ReviewCellConfig {

    /// Идентификатор для переиспользования ячейки.
    static let reuseId = String(describing: ReviewCellConfig.self)

    /// Идентификатор конфигурации. Можно использовать для поиска конфигурации в массиве.
    let id: UUID
    /// Текст отзыва.
    let reviewText: NSAttributedString
    /// Максимальное отображаемое количество строк текста. По умолчанию 3.
    var maxLines = 3
    /// Время создания отзыва.
    let created: NSAttributedString
    /// Замыкание, вызываемое при нажатии на кнопку "Показать полностью...".
    let onTapShowMore: (UUID) -> Void
    /// Аватар пользователя
    var avatarImage: UIImage?
    /// Имя пользователя
    let userName: NSAttributedString
    /// Иконка рейтинга пользователя
    let ratingImage: UIImage
    /// Массив фотографий пользователя
    var userImages: [UIImage]

    /// Объект, хранящий посчитанные фреймы для ячейки отзыва.
    fileprivate let layout = ReviewCellLayout()

}

// MARK: - TableCellConfig

extension ReviewCellConfig: TableCellConfig {

    /// Метод обновления ячейки.
    /// Вызывается из `cellForRowAt:` у `dataSource` таблицы.
    func update(cell: UITableViewCell) {
        guard let cell = cell as? ReviewCell else { return }
        
        cell.reviewTextLabel.attributedText = reviewText
        cell.reviewTextLabel.numberOfLines = maxLines
        cell.createdLabel.attributedText = created
        cell.avatarImageView.image = avatarImage
        cell.userNameLabel.attributedText = userName
        cell.ratingImageView.image = ratingImage
        
        cell.config = self
    }

    /// Метод, возвращаюший высоту ячейки с данным ограничением по размеру.
    /// Вызывается из `heightForRowAt:` делегата таблицы.
    func height(with size: CGSize) -> CGFloat {
        layout.height(config: self, maxWidth: size.width)
    }

}

// MARK: - Private

private extension ReviewCellConfig {

    /// Текст кнопки "Показать полностью...".
    static let showMoreText = "Показать полностью..."
        .attributed(font: .showMore, color: .showMore)

}

// MARK: - Cell

final class ReviewCell: UITableViewCell {

    fileprivate var config: Config?

    fileprivate let reviewTextLabel = UILabel()
    fileprivate let createdLabel = UILabel()
    fileprivate let showMoreButton = UIButton()
    fileprivate let avatarImageView = UIImageView()
    fileprivate let userNameLabel = UILabel()
    fileprivate let ratingImageView = UIImageView()
    fileprivate let photosCollectionView: UICollectionView = makePhotosCollectionView()
    
    private var userImages: [UIImage] = []

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let layout = config?.layout else { return }

        avatarImageView.frame = layout.avatarFrame
        userNameLabel.frame = layout.userNameFrame
        ratingImageView.frame = layout.ratingFrame
        reviewTextLabel.frame = layout.reviewTextLabelFrame
        createdLabel.frame = layout.createdLabelFrame
        showMoreButton.frame = layout.showMoreButtonFrame
        photosCollectionView.frame = layout.collectionViewFrame
    }

}

// MARK: – Internal

extension ReviewCell {
    
    func configure(with images: [UIImage]) {
        self.userImages = images
        photosCollectionView.reloadData()
    }
    
}

// MARK: – UICollectionViewDataSource

extension ReviewCell: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return config?.userImages.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCell.reuseId, for: indexPath) as? PhotoCell else {
            return UICollectionViewCell()
        }
        guard let image = config?.userImages[indexPath.item] else { return UICollectionViewCell() }
        cell.configure(with: image)
        return cell
    }
}

// MARK: - Private

private extension ReviewCell {
    
    static func makePhotosCollectionView() -> UICollectionView {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 50, height: 60)
        layout.minimumLineSpacing = 8

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        return collectionView
    }

    func setupCell() {
        setupAvatarImageView()
        setupUserNameLabel()
        setupRatingImageView()
        setupCollectionView()
        setupReviewTextLabel()
        setupCreatedLabel()
        setupShowMoreButton()
    }
    
    func setupUserNameLabel() {
        contentView.addSubview(userNameLabel)
    }
    
    func setupAvatarImageView() {
        contentView.addSubview(avatarImageView)
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = Layout.avatarCornerRadius
        avatarImageView.clipsToBounds = true
    }
    
    func setupRatingImageView() {
        contentView.addSubview(ratingImageView)
        ratingImageView.contentMode = .scaleAspectFit
    }

    func setupReviewTextLabel() {
        contentView.addSubview(reviewTextLabel)
        reviewTextLabel.lineBreakMode = .byWordWrapping
    }

    func setupCreatedLabel() {
        contentView.addSubview(createdLabel)
    }

    func setupShowMoreButton() {
        contentView.addSubview(showMoreButton)
        showMoreButton.contentVerticalAlignment = .fill
        showMoreButton.setAttributedTitle(Config.showMoreText, for: .normal)
        
        showMoreButton.addTarget(self, action: #selector(didTapShowMore), for: .touchUpInside)
    }
    
    func setupCollectionView() {
        contentView.addSubview(photosCollectionView)
        photosCollectionView.dataSource = self
        photosCollectionView.register(PhotoCell.self, forCellWithReuseIdentifier: PhotoCell.reuseId)
    }
    
    @objc func didTapShowMore() {
        guard let config = config else { return }
        config.onTapShowMore(config.id)
    }
}

// MARK: - Layout

/// Класс, в котором происходит расчёт фреймов для сабвью ячейки отзыва.
/// После расчётов возвращается актуальная высота ячейки.
private final class ReviewCellLayout {

    // MARK: - Размеры

    fileprivate static let avatarSize = CGSize(width: 36.0, height: 36.0)
    fileprivate static let avatarCornerRadius = 18.0
    fileprivate static let photoCornerRadius = 8.0

    private static let photoSize = CGSize(width: 55.0, height: 66.0)
    private static let showMoreButtonSize = Config.showMoreText.size()

    // MARK: - Фреймы

    private(set) var reviewTextLabelFrame = CGRect.zero
    private(set) var showMoreButtonFrame = CGRect.zero
    private(set) var createdLabelFrame = CGRect.zero
    private(set) var avatarFrame = CGRect.zero
    private(set) var userNameFrame = CGRect.zero
    private(set) var ratingFrame = CGRect.zero
    private(set) var collectionViewFrame = CGRect.zero

    // MARK: - Отступы

    /// Отступы от краёв ячейки до её содержимого.
    private let insets = UIEdgeInsets(top: 9.0, left: 12.0, bottom: 9.0, right: 12.0)

    /// Горизонтальный отступ от аватара до имени пользователя.
    private let avatarToUsernameSpacing = 10.0
    /// Вертикальный отступ от имени пользователя до вью рейтинга.
    private let usernameToRatingSpacing = 6.0
    /// Вертикальный отступ от вью рейтинга до текста (если нет фото).
    private let ratingToTextSpacing = 6.0
    /// Вертикальный отступ от вью рейтинга до фото.
    private let ratingToPhotosSpacing = 10.0
    /// Горизонтальные отступы между фото.
    private let photosSpacing = 8.0
    /// Вертикальный отступ от фото (если они есть) до текста отзыва.
    private let photosToTextSpacing = 10.0
    /// Вертикальный отступ от текста отзыва до времени создания отзыва или кнопки "Показать полностью..." (если она есть).
    private let reviewTextToCreatedSpacing = 6.0
    /// Вертикальный отступ от кнопки "Показать полностью..." до времени создания отзыва.
    private let showMoreToCreatedSpacing = 6.0

    // MARK: - Расчёт фреймов и высоты ячейки

    /// Возвращает высоту ячейку с данной конфигурацией `config` и ограничением по ширине `maxWidth`.
    func height(config: Config, maxWidth: CGFloat) -> CGFloat {
        let width = maxWidth - insets.left - insets.right

        var maxY = insets.top
        var showShowMoreButton = false
                    
        avatarFrame = CGRect(
            x: insets.left,
            y: maxY,
            width: Self.avatarSize.width,
            height: Self.avatarSize.height
        )
        
        userNameFrame = CGRect(x: avatarFrame.maxX + avatarToUsernameSpacing, y: maxY, width: width, height: 20)
        
        maxY = userNameFrame.maxY + usernameToRatingSpacing
        
        ratingFrame = CGRect(
            x: userNameFrame.minX,
            y: userNameFrame.maxY + usernameToRatingSpacing,
            width: 80,
            height: 16
        )
        
        maxY = ratingFrame.maxY + ratingToPhotosSpacing
        
        if config.userImages.count > 0 {
            collectionViewFrame = CGRect(
                x: userNameFrame.minX,
                y: maxY,
                width: width,
                height: 60
            )
            
            maxY = collectionViewFrame.maxY + photosToTextSpacing
        } else {
            maxY = ratingFrame.maxY + ratingToTextSpacing
        }
        
        if !config.reviewText.isEmpty() {
            let textWidth = maxWidth - userNameFrame.minX - insets.right

            // Высота текста
            let textBoundingRect = config.reviewText.boundingRect(
                width: textWidth
            ).size.height

            let fontLineHeight = config.reviewText.font()?.lineHeight ?? .zero
            
            // Определение высоты текста в случае, если нажата кнопка "Показать полностью..."
            let currentTextHeight: CGFloat
                if config.maxLines == 0 {
                    currentTextHeight = textBoundingRect
                } else {
                    currentTextHeight = min(textBoundingRect, fontLineHeight * 3)
                }
            
            // Кнопка "Показать полностью...", если текст обрезается
            showShowMoreButton = config.maxLines != .zero && textBoundingRect > currentTextHeight

            reviewTextLabelFrame = CGRect(
                x: userNameFrame.minX,
                y: maxY,
                width: textWidth,
                height: ceil(min(currentTextHeight, textBoundingRect)) 
            )

            maxY = reviewTextLabelFrame.maxY + reviewTextToCreatedSpacing
        } else {
            reviewTextLabelFrame = .zero
            if config.userImages.count > 0 {
                maxY = collectionViewFrame.maxY + photosToTextSpacing
            } else {
                maxY = ratingFrame.maxY + ratingToTextSpacing
            }
           
        }

        if showShowMoreButton {
            showMoreButtonFrame = CGRect(
                origin: CGPoint(x: userNameFrame.minX, y: maxY),
                size: Self.showMoreButtonSize
            )
            maxY = showMoreButtonFrame.maxY + showMoreToCreatedSpacing
        } else {
            showMoreButtonFrame = .zero
        }
        
        createdLabelFrame = CGRect(
            origin: CGPoint(x: userNameFrame.minX, y: maxY),
            size: config.created.boundingRect(width: width).size
        )

        return createdLabelFrame.maxY + insets.bottom
    }

}

// MARK: - Typealias

fileprivate typealias Config = ReviewCellConfig
fileprivate typealias Layout = ReviewCellLayout
