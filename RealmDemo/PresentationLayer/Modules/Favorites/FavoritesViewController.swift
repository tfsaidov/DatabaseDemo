//
//  FavoritesViewController.swift
//  RealmDemo
//
//  Created by Саидов Тимур on 11.06.2022.
//

import UIKit

class FavoritesViewController: UIViewController {
    
    private enum State {
        case empty
        case hasModel(model: [News.Article])
        case mock(_ model: [ArticleTableViewCell.ViewModel])
    }

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "DefaultCell")
        tableView.register(FavoriteArticleTableViewCell.self, forCellReuseIdentifier: "ArticleCell")
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.allowsSelection = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    private var state: State = .empty
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(wasLikedArticle(_:)),
                                               name: .wasLikedArticle,
                                               object: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupNavigationBar()
        self.setupView()
    }
    
    private func setupNavigationBar() {
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationItem.title = "Favorites"
    }
    
    private func setupView() {
        self.view.backgroundColor = .white
        
        self.view.addSubview(self.tableView)

        let topConstraint = self.tableView.topAnchor.constraint(equalTo: self.view.topAnchor)
        let leftConstraint = self.tableView.leftAnchor.constraint(equalTo: self.view.leftAnchor)
        let rightConstraint = self.tableView.rightAnchor.constraint(equalTo: self.view.rightAnchor)
        let bottomConstraint = self.tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)

        NSLayoutConstraint.activate([
            topConstraint, leftConstraint, rightConstraint, bottomConstraint
        ])
    }

    @objc private func wasLikedArticle(_ notification: NSNotification) {
        guard self.isViewLoaded else { return }
        
        if let article = notification.userInfo?["article"] as? News.Article {
            switch self.state {
            case .empty:
                if article.isFavorite {
                    let model = [article]
                    self.state = .hasModel(model: model)
                    self.tableView.beginUpdates()
                    self.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .fade)
                    self.tableView.endUpdates()
                }
            case .hasModel(let model):
                var newModel = model
                
                if article.isFavorite {
                    newModel.append(article)
                    self.state = .hasModel(model: newModel)
                    let lastIndex = newModel.count - 1
                    self.tableView.beginUpdates()
                    self.tableView.insertRows(at: [IndexPath(row: lastIndex, section: 0)], with: .fade)
                    self.tableView.endUpdates()
                } else {
                    guard let index = model.firstIndex(where: { $0 == article }) else { return }
                    
                    newModel.remove(at: index)
                    self.state = .hasModel(model: newModel)
                    self.tableView.beginUpdates()
                    self.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .fade)
                    self.tableView.endUpdates()
                }
            case .mock:
                break
            }
        } else if let article = notification.userInfo?["article"] as? ArticleTableViewCell.ViewModel {
            switch self.state {
            case .empty:
                if article.isFavorite {
                    let model = [article]
                    self.state = .mock(model)
                    self.tableView.beginUpdates()
                    self.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .fade)
                    self.tableView.endUpdates()
                }
            case .hasModel:
                break
            case .mock(let model):
                var newModel = model
                
                if article.isFavorite {
                    newModel.append(article)
                    self.state = .mock(newModel)
                    let lastIndex = newModel.count - 1
                    self.tableView.beginUpdates()
                    self.tableView.insertRows(at: [IndexPath(row: lastIndex, section: 0)], with: .fade)
                    self.tableView.endUpdates()
                } else {
                    guard let index = model.firstIndex(where: { $0.url == article.url }) else { return }
                    
                    newModel.remove(at: index)
                    self.state = .mock(newModel)
                    self.tableView.beginUpdates()
                    self.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .fade)
                    self.tableView.endUpdates()
                }
            }
        }
    }
}

extension FavoritesViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch self.state {
        case .empty:
            return 0
        case .hasModel(let model):
            return model.count
        case .mock(let model):
            return model.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch self.state {
        case .empty:
            let cell = tableView.dequeueReusableCell(withIdentifier: "DefaultCell", for: indexPath)
            return cell
        case .hasModel(let model):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "ArticleCell", for: indexPath) as? FavoriteArticleTableViewCell else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "DefaultCell", for: indexPath)
                return cell
            }
            
            let article = model[indexPath.row]
            let model = FavoriteArticleTableViewCell.ViewModel(title: article.title,
                                                               description: article.description,
                                                               publishedAt: article.publishedAtString ?? .empty,
                                                               url: article.url,
                                                               isFavorite: article.isFavorite)
            cell.setup(with: model)
            return cell
        case .mock(let model):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "ArticleCell", for: indexPath) as? FavoriteArticleTableViewCell else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "DefaultCell", for: indexPath)
                return cell
            }
            
            let model = FavoriteArticleTableViewCell.ViewModel(model: model[indexPath.row])
            cell.setup(with: model)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let shareAction = UIContextualAction(style: .normal, title: nil) { (action, view, completion) in
            completion(true)
        }
        shareAction.image = UIImage(systemName: "arrowshape.turn.up.right")
        shareAction.backgroundColor = .systemBlue
        return UISwipeActionsConfiguration(actions: [shareAction])
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        switch self.state {
        case .empty:
            return nil
        case .hasModel(let model):
            let deleteAction = UIContextualAction(style: .destructive, title: nil) { [weak self] (_, _, completion) in
                guard let self = self else { return }
                
                var newModel = model
                let deletedArticle = model[indexPath.row]
                newModel.remove(at: indexPath.row)
                self.state = .hasModel(model: newModel)
                
                self.tableView.beginUpdates()
                self.tableView.deleteRows(at: [indexPath], with: .fade)
                self.tableView.endUpdates()
                
                let userInfo = ["deletedFromFavoritesArticle": deletedArticle]
                NotificationCenter.default.post(name: .didRemoveArticleFromFavorites, object: nil, userInfo: userInfo)
                completion(true)
            }
            deleteAction.image = UIImage(systemName: "trash")
            return UISwipeActionsConfiguration(actions: [deleteAction])
        case .mock(let model):
            let deleteAction = UIContextualAction(style: .destructive, title: nil) { [weak self] (_, _, completion) in
                guard let self = self else { return }
                
                var newModel = model
                let deletedArticle = model[indexPath.row]
                newModel.remove(at: indexPath.row)
                self.state = .mock(newModel)
                
                self.tableView.beginUpdates()
                self.tableView.deleteRows(at: [indexPath], with: .fade)
                self.tableView.endUpdates()
                
                let userInfo = ["deletedFromFavoritesArticle": deletedArticle]
                NotificationCenter.default.post(name: .didRemoveArticleFromFavorites, object: nil, userInfo: userInfo)
                completion(true)
            }
            deleteAction.image = UIImage(systemName: "trash")
            return UISwipeActionsConfiguration(actions: [deleteAction])
        }
    }
}
