//
//  ArticleTableViewCell.swift
//  RealmDemo
//
//  Created by Саидов Тимур on 05.06.2022.
//

import UIKit

protocol ArticleTableViewCellDelefate: AnyObject {
    func wasLikedArticle(with url: String)
}

final class ArticleTableViewCell: UITableViewCell {
    
    struct ViewModel: ViewModelProtocol {
        let title: String
        let description: String?
        let publishedAt: String
        let url: String
        var isFavorite: Bool
    }
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 17)
        label.numberOfLines = 0
        label.setContentHuggingPriority(UILayoutPriority(1), for: .vertical)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .darkGray
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private lazy var publishedDateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 11)
        label.textColor = .darkGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var favoriteButton: UIButton = {
        let button = UIButton(type: .system)
        button.addTarget(self, action: #selector(self.didTapFavoriteButton), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private var viewModel: ViewModel?
    
    weak var delegate: ArticleTableViewCellDelefate?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.titleLabel.text = .empty
        self.descriptionLabel.text = .empty
        self.publishedDateLabel.text = .empty
        self.descriptionLabel.isHidden = false
    }
    
    private func setupView() {
        self.contentView.addSubview(self.stackView)
        self.stackView.addArrangedSubview(self.titleLabel)
        self.stackView.addArrangedSubview(self.descriptionLabel)
        self.contentView.addSubview(self.publishedDateLabel)
        self.contentView.addSubview(self.favoriteButton)
        
        let stackViewConstraints = self.stackViewConstraints()
        let publishedDateLabelConstraints = self.publishedDateLabelConstraintsForDefaultState()
        let favoriteImageViewConstraints = self.favoriteButtonConstraints()
        
        NSLayoutConstraint.activate(
            stackViewConstraints +
            publishedDateLabelConstraints +
            favoriteImageViewConstraints
        )
    }
    
    private func stackViewConstraints() -> [NSLayoutConstraint] {
        let topAnchor = self.stackView.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 10)
        let leftAnchor = self.stackView.leftAnchor.constraint(equalTo: self.contentView.leftAnchor, constant: 20)
        let rightAnchor = self.stackView.rightAnchor.constraint(equalTo: self.contentView.rightAnchor, constant: -20)
        
        return [
            topAnchor, leftAnchor, rightAnchor
        ]
    }
    
    private func publishedDateLabelConstraintsForDefaultState() -> [NSLayoutConstraint] {
        let topAnchor = self.publishedDateLabel.topAnchor.constraint(equalTo: self.favoriteButton.topAnchor)
        let leftAnchor = self.publishedDateLabel.leftAnchor.constraint(equalTo: self.stackView.leftAnchor)
        let rightAnchor = self.publishedDateLabel.rightAnchor.constraint(equalTo: self.favoriteButton.leftAnchor, constant: -20)
        let bottomAnchor = self.publishedDateLabel.bottomAnchor.constraint(equalTo: self.favoriteButton.bottomAnchor)
        
        return [
            topAnchor, leftAnchor, rightAnchor, bottomAnchor
        ]
    }
    
    private func favoriteButtonConstraints() -> [NSLayoutConstraint] {
        let topAnchor = self.favoriteButton.topAnchor.constraint(equalTo: self.stackView.bottomAnchor, constant: 10)
        let rightAnchor = self.favoriteButton.rightAnchor.constraint(equalTo: self.stackView.rightAnchor)
        let heightAnchor = self.favoriteButton.heightAnchor.constraint(equalToConstant: 20)
        let widthAnchor = self.favoriteButton.widthAnchor.constraint(equalToConstant: 20)
        let bottomAnchor = self.favoriteButton.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -10)
        
        return [
            topAnchor, rightAnchor, heightAnchor, widthAnchor, bottomAnchor
        ]
    }
    
    @objc private func didTapFavoriteButton() {
        let imageName = self.viewModel?.isFavorite == false
        ? "heart.circle.fill"
        : "heart.circle"
        UIView.animate(withDuration: 0.2) {
            self.favoriteButton.setImage(UIImage(systemName: imageName), for: .normal)
            self.favoriteButton.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        } completion: { _ in
            guard var newViewModel = self.viewModel else { return }
            
            UIView.animate(withDuration: 0.2) {
                self.favoriteButton.transform = .identity
            } completion: { _ in
                newViewModel.isFavorite.toggle()
                self.viewModel = newViewModel
                self.delegate?.wasLikedArticle(with: newViewModel.url)
            }
        }
    }
}

extension ArticleTableViewCell: Setupable {
    
    func setup(with viewModel: ViewModelProtocol) {
        guard let viewModel = viewModel as? ViewModel else { return }
        
        self.viewModel = viewModel
        
        self.titleLabel.text = viewModel.title == .empty
        ? "Untitled"
        : viewModel.title
        self.descriptionLabel.text = viewModel.description
        self.publishedDateLabel.text = viewModel.publishedAt
        let imageName = self.viewModel?.isFavorite == false
        ? "heart.circle"
        : "heart.circle.fill"
        self.favoriteButton.setImage(UIImage(systemName: imageName), for: .normal)
        
        if self.descriptionLabel.text == .empty {
            self.descriptionLabel.isHidden = true
        }
    }
}

extension ArticleTableViewCell: Changable {
    
    func change(with viewModel: ViewModelProtocol) {
        guard let viewModel = viewModel as? ViewModel else { return }
        
        self.viewModel = viewModel
        
        let imageName = self.viewModel?.isFavorite == false
        ? "heart.circle"
        : "heart.circle.fill"
        self.favoriteButton.setImage(UIImage(systemName: imageName), for: .normal)
    }
}
