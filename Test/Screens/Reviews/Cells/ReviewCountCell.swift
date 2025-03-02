import UIKit

struct ReviewCountCellConfig {
    
    /// Идентификатор для переиспользования ячейки.
    static let reuseId = String(describing: ReviewCountCellConfig.self)
    
    /// Количество отзывов
    let reviewCount: Int
    
    /// Объект, хранящий посчитанные фреймы для ячейки количества отзывов.
    fileprivate let layout = ReviewCountCellLayout()
    
}

// MARK: - TableCellConfig

extension ReviewCountCellConfig: TableCellConfig {
    
    /// Метод обновления ячейки.
    /// Вызывается из `cellForRowAt:` у `dataSource` таблицы.
    func update(cell: UITableViewCell) {
        guard let cell = cell as? ReviewCountCell else { return }
        let text = ("\(reviewCount) отзывов").attributed(font: .reviewCount, color: .reviewCount)
        cell.reviewCountTextLabel.attributedText = text
        cell.reviewCountTextLabel.textAlignment = .center
        
        cell.config = self
    }
    
    /// Метод, возвращаюший высоту ячейки с данным ограничением по размеру.
    /// Вызывается из `heightForRowAt:` делегата таблицы.
    func height(with size: CGSize) -> CGFloat {
        layout.height(config: self, maxWidth: size.width)
    }
    
}

// MARK: – Cell

final class ReviewCountCell: UITableViewCell {
    
    fileprivate var config: Config?
    
    fileprivate let reviewCountTextLabel = UILabel()
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        guard let layout = config?.layout, reviewCountTextLabel.frame != layout.reviewCountTextLabelFrame else { return }
        
        reviewCountTextLabel.frame = layout.reviewCountTextLabelFrame
    }
    
}

// MARK: – Private

private extension ReviewCountCell {
    func setupCell() {
        setupReviewCountTextLabel()
    }
    
    func setupReviewCountTextLabel() {
        contentView.addSubview(reviewCountTextLabel)
    }
}

// MARK: - Layout

/// Класс, в котором происходит расчёт фреймов для сабвью ячейки отзыва.
/// После расчётов возвращается актуальная высота ячейки.

private final class ReviewCountCellLayout {
    
    // MARK: - Размеры
    
    fileprivate static let reviewCountLabelHeight: CGFloat = 20
    
    // MARK: - Фреймы
    
    private(set) var reviewCountTextLabelFrame = CGRect.zero
    
    // MARK: - Отступы
    
    /// Отступы от краёв ячейки до её содержимого.
    private let insets = UIEdgeInsets(top: 9.0, left: 12.0, bottom: 9.0, right: 12.0)
    
    // MARK: - Расчёт фреймов и высоты ячейки
    
    /// Возвращает высоту ячейки с данной конфигурацией `config` и ограничением по ширине `maxWidth`.
    func height(config: Config, maxWidth: CGFloat) -> CGFloat {
        let width = maxWidth - insets.left - insets.right
        
        let x = (maxWidth - width) / 2
        
        let maxY = insets.top
        
        reviewCountTextLabelFrame = CGRect(x: x, y: maxY, width: width, height: Self.reviewCountLabelHeight)
        
        return reviewCountTextLabelFrame.maxY + insets.bottom
    }
    
}

// MARK: - Typealias

fileprivate typealias Config = ReviewCountCellConfig
fileprivate typealias Layout = ReviewCountCellLayout


