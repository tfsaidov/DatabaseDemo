//
//  ViewController.swift
//  RealmDemo
//
//  Created by Саидов Тимур on 04.06.2022.
//

import UIKit

final class NewsViewController: UIViewController {
    
    private enum State {
        case loading
        case loaded(data: [News.Article])
        case error(_ error: NetworkError)
    }
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "DefaultCell")
        tableView.register(ArticleTableViewCell.self, forCellReuseIdentifier: "ArticleCell")
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.allowsSelection = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .gray
        indicator.isHidden = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    private lazy var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
    
    private let networkService: NetworkServiceProtocol = NetworkService()
    
    private var state: State = .loading
    
    private let dataType: SceneDelegate.DataType
    
    init(dataType: SceneDelegate.DataType) {
        self.dataType = dataType
        super.init(nibName: nil, bundle: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(removeArticleFromFavorites(_:)),
                                               name: .didRemoveArticleFromFavorites,
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
        self.obtainData()
    }
    
    private func setupNavigationBar() {
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationItem.title = "News"
    }
    
    private func setupView() {
        self.view.backgroundColor = .white
        
        self.view.addSubview(self.tableView)
        self.view.addSubview(self.activityIndicator)

        let tableViewConstraints = self.tableViewConstraints()
        let activityIndicatorConstaints = self.activityIndicatorConstaints()
        
        NSLayoutConstraint.activate(
            tableViewConstraints +
            activityIndicatorConstaints
        )
    }
    
    private func tableViewConstraints() -> [NSLayoutConstraint] {
        let topConstraint = self.tableView.topAnchor.constraint(equalTo: self.view.topAnchor)
        let leftConstraint = self.tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor)
        let rightConstraint = self.tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
        let bottomConstraint = self.tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        
        return [
            topConstraint, leftConstraint, rightConstraint, bottomConstraint
        ]
    }
    
    private func activityIndicatorConstaints() -> [NSLayoutConstraint] {
        let centerYConstraint = self.activityIndicator.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
        let centerXConstraint = self.activityIndicator.centerXAnchor.constraint(equalTo: self.view.centerXAnchor)
        
        return [
            centerYConstraint, centerXConstraint
        ]
    }
    
    private func obtainData() {
        let completion: (Result<Data, NetworkError>) -> Void = { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let data):
                do {
                    let news = try self.parse(News.self, from: data)
                    
                    guard let articles = self.filterData(news.articles) else {
                        self.stopAnimating()
                        self.state = .error(.parseError(reason: "Could't filter received data"))
                        return
                    }
                    
                    self.stopAnimating()
                    self.state = .loaded(data: articles)
                    self.tableView.reloadData()
                } catch let error {
                    self.stopAnimating()
                    
                    if let error = error as? NetworkError {
                        self.state = .error(error)
                    } else {
                        self.state = .error(.unknownError)
                    }
                }
            case .failure(let error):
                self.stopAnimating()
                self.state = .error(error)
            }
        }
        
        self.dataType == .request
        ? self.fetchNews(completion: completion)
        : self.fetchMockData(completion: completion)
    }
    
    private func fetchNews(completion: @escaping (Result<Data, NetworkError>) -> Void) {
        let endPoint = self.urlComponents()
        if let url = endPoint.url {
            self.startAnimating()
            self.sendRequest(for: url, completion: completion)
        } else {
            completion(.failure(.unknownError))
        }
    }
    
    private func urlComponents() -> URLComponents {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "newsapi.org"
        urlComponents.path = "/v2/everything"
        urlComponents.queryItems = [
            URLQueryItem(name: "q", value: "apple"),
            URLQueryItem(name: "sortBy", value: "publishedAt"),
            URLQueryItem(name: "apiKey", value: "11d4c3f8230e4f5ab460aabaf3a06f57"),
        ]
        return urlComponents
    }
    
    private func sendRequest(for url: URL, completion: @escaping (Result<Data, NetworkError>) -> Void) {
        self.networkService.request(url: url) { result in
            switch result {
            case .success(let data):
//                print("🍏", String(data: data, encoding: .utf8))
                completion(.success(data))
            case .failure(let error):
//                print("🍎", error)
                completion(.failure(error))
            }
        }
    }
    
    private func parse<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            let model = try self.decoder.decode(T.self, from: data)
//            print("🍏", dump(model))
            return model
        } catch let error {
//            print("🍎", error)
            throw NetworkError.parseError(reason: error.localizedDescription)
        }
    }
    
    private func fetchMockData(completion: @escaping (Result<Data, NetworkError>) -> Void) {
        self.startAnimating()
        if let path = Bundle.main.path(forResource: "news", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .alwaysMapped)
//                let jsonObj = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
//                print("🍏", String(data: data, encoding: .utf8))
                completion(.success(data))
            } catch let error {
//                print("🍎", error)
                completion(.failure(.parseError(reason: error.localizedDescription)))
            }
        } else {
//            print("🍎 Invalid filename/path.")
            completion(.failure(.unknownError))
        }
    }
    
    private func filterData<T>(_ data: T) -> T? {
        if let articles = data as? [News.Article] {
            let filterArticles = articles.filter({ $0.publishedAtString?.isEmpty == false && $0.publishedAtString?.isFirstCharacterWhitespace == false })
            return filterArticles as? T
        }
        
        if let articlesViewModel = data as? [ArticleTableViewCell.ViewModel] {
            let filterArticlesViewModel = articlesViewModel.filter({ !$0.publishedAt.isEmpty && !$0.publishedAt.isFirstCharacterWhitespace })
            return filterArticlesViewModel as? T
        }
        
        return nil
    }
    
    private func startAnimating() {
        self.activityIndicator.isHidden = false
        self.activityIndicator.startAnimating()
    }
    
    private func stopAnimating() {
        self.activityIndicator.isHidden = false
        self.activityIndicator.stopAnimating()
    }
    
    @objc private func removeArticleFromFavorites(_ notification: NSNotification) {
        guard self.isViewLoaded else { return }
        
        if let deletedFromFavoritesArticle = notification.userInfo?["deletedFromFavoritesArticle"] as? News.Article {
            switch self.state {
            case .loading, .error:
                break
            case .loaded(let data):
                guard
                    var detectedArticle = data.first(where: { $0 == deletedFromFavoritesArticle }),
                    let detectedArticleIndex = data.firstIndex(where: { $0 == deletedFromFavoritesArticle })
                else { return }
                
                var newData = data
                detectedArticle.isFavorite.toggle()
                newData[detectedArticleIndex] = detectedArticle
                self.state = .loaded(data: newData)
                
                guard let cell = tableView.cellForRow(at: IndexPath(row: detectedArticleIndex, section: 0)) as? ArticleTableViewCell else { return }
                let viewModel = ArticleTableViewCell.ViewModel(title: detectedArticle.title,
                                                               description: detectedArticle.description,
                                                               publishedAt: detectedArticle.publishedAt,
                                                               url: detectedArticle.url,
                                                               isFavorite: detectedArticle.isFavorite)
                cell.change(with: viewModel)
            }
        }
    }
}

extension NewsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch self.state {
        case .loading, .error:
            return 0
        case .loaded(let articles):
            return articles.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch self.state {
        case .loading, .error:
            let cell = tableView.dequeueReusableCell(withIdentifier: "DefaultCell", for: indexPath)
            return cell
        case .loaded(let articles):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "ArticleCell", for: indexPath) as? ArticleTableViewCell else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "DefaultCell", for: indexPath)
                return cell
            }
            
            let article = articles[indexPath.row]
            let model = ArticleTableViewCell.ViewModel(title: article.title,
                                                       description: article.description,
                                                       publishedAt: article.publishedAtString ?? .empty,
                                                       url: article.url,
                                                       isFavorite: article.isFavorite)
            cell.delegate = self
            cell.setup(with: model)
            return cell
        }
    }
}

extension NewsViewController: ArticleTableViewCellDelefate {
    
    func wasLikedArticle(with url: String) {
        switch self.state {
        case .loading, .error:
            break
        case .loaded(let data):
            var newData = data
            
            guard
                var filterArticle = newData.first(where: { $0.url == url }),
                let index = newData.firstIndex(where: { $0.url == url })
            else { return }
            
            filterArticle.isFavorite.toggle()
            newData[index] = filterArticle
            self.state = .loaded(data: newData)
            
            let userInfo = ["article": filterArticle]
            NotificationCenter.default.post(name: .wasLikedArticle, object: nil, userInfo: userInfo)
        }
    }
}
