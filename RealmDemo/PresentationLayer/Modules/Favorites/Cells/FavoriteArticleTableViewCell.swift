//
//  FavoriteArticleTableViewCell.swift
//  RealmDemo
//
//  Created by Саидов Тимур on 11.06.2022.
//

import UIKit

class FavoriteArticleTableViewCell: UITableViewCell {

    struct ViewModel: ViewModelProtocol {
        let title: String
        let description: String?
        let publishedAt: String
        let url: String
        var isFavorite: Bool
        
        init(title: String, description: String?, publishedAt: String, url: String, isFavorite: Bool) {
            self.title = title
            self.description = description
            self.publishedAt = publishedAt
            self.url = url
            self.isFavorite = isFavorite
        }
        
        init(model: ArticleTableViewCell.ViewModel) {
            self.title = model.title
            self.description = model.description
            self.publishedAt = model.publishedAt
            self.url = model.url
            self.isFavorite = model.isFavorite
        }
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
    
    private var viewModel: ViewModel?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.titleLabel.text = ""
        self.descriptionLabel.text = ""
        self.publishedDateLabel.text = ""
        self.descriptionLabel.isHidden = false
    }
    
    private func setupView() {
        self.contentView.addSubview(self.stackView)
        self.stackView.addArrangedSubview(self.titleLabel)
        self.stackView.addArrangedSubview(self.descriptionLabel)
        self.contentView.addSubview(self.publishedDateLabel)
        
        let stackViewConstraints = self.stackViewConstraints()
        let publishedDateLabelConstraints = self.publishedDateLabelConstraintsForFavoritesState()
        
        NSLayoutConstraint.activate(
            stackViewConstraints +
            publishedDateLabelConstraints
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
    
    private func publishedDateLabelConstraintsForFavoritesState() -> [NSLayoutConstraint] {
        let topAnchor = self.publishedDateLabel.topAnchor.constraint(equalTo: self.stackView.bottomAnchor, constant: 10)
        let leftAnchor = self.publishedDateLabel.leftAnchor.constraint(equalTo: self.stackView.leftAnchor)
        let rightAnchor = self.publishedDateLabel.rightAnchor.constraint(equalTo: self.stackView.rightAnchor)
        let heightAnchor = self.publishedDateLabel.heightAnchor.constraint(equalToConstant: 20)
        let bottomAnchor = self.publishedDateLabel.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -10)
        
        return [
            topAnchor, leftAnchor, rightAnchor, heightAnchor, bottomAnchor
        ]
    }
}

extension FavoriteArticleTableViewCell: Setupable {
    
    func setup(with viewModel: ViewModelProtocol) {
        guard let viewModel = viewModel as? ViewModel else { return }
        
        self.viewModel = viewModel
        
        self.titleLabel.text = viewModel.title == .empty
        ? "Untitled"
        : viewModel.title
        self.descriptionLabel.text = viewModel.description
        self.publishedDateLabel.text = viewModel.publishedAt
        
        if self.descriptionLabel.text == .empty {
            self.descriptionLabel.isHidden = true
        }
    }
}
