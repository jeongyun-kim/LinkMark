
//  DetailViewController.swift
//  LinkMark


import UIKit
import Combine
import RealmSwift

class DetailViewController: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    // 링크
    @IBOutlet weak var urlLabel: UILabel!
    // 썸네일
    @IBOutlet weak var thumbnailImageView: UIImageView!
    // 제목
    @IBOutlet weak var titleLabel: UILabel!
    // 메모 내용
    @IBOutlet weak var memoContents: UILabel!
    // 저장 날짜
    @IBOutlet weak var saveDate: UILabel!
    
    let ms = Methods()
    
    var tagNames: [String] = []
    
    var filterState : Bool = false
    
    typealias Item = String
    
    enum Section {
        case main
    }
    
    var datasource: UICollectionViewDiffableDataSource<Section, Item>!
    
    /// **홈뷰, 즐겨찾기로부터 받아올 URL 데이터**
    let urlItems = CurrentValueSubject<UrlList, Never>(UrlList(image: nil, title: "", url: "", saveDate: Date(), tags: List<Tag>()))
    
    var subscriptions = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureCollectionView()
        bind()
        navigationSetupUI()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        let sb = UIStoryboard(name: "Home", bundle: nil)
        let vc = sb.instantiateViewController(identifier: "HomeViewController") as! HomeViewController
        vc.filterState = filterState
    }
    
    /// **컬렉션뷰 구성**
    private func configureCollectionView() {
        datasource = UICollectionViewDiffableDataSource(collectionView: collectionView, cellProvider: { collectionView, indexPath, item in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DetailViewTagCell", for: indexPath) as? DetailTagCell else { return nil }
            cell.configure(item: item)
            return cell
                    
        })
    
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.main])
        snapshot.appendItems([], toSection: .main)
        datasource.apply(snapshot)
        
        collectionView.collectionViewLayout = layout()
        collectionView.isScrollEnabled = false
    }
    
    /// **컬렉션뷰 레이아웃**
    private func layout() -> UICollectionViewCompositionalLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .estimated(1), heightDimension: .estimated(1))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(0.33))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        group.interItemSpacing = .fixed(8)
        
        let section = NSCollectionLayoutSection(group: group)
        return UICollectionViewCompositionalLayout(section: section)
    }
    
    /// **상세보기에 맞는 데이터 보여주기 **
    private func bind() {
        // OUTPUT : 전달받은 데이터 뿌려주기
        urlItems
            .receive(on: RunLoop.main)
            .sink { [unowned self] item in
                self.urlLabel.text = item.url
                self.titleLabel.text = item.title
                self.memoContents.text = item.memo
                self.thumbnailImageView.image = UIImage(data: item.image!)
                for tag in item.tags {
                    tagNames.append(tag.tagName)
                }
                var snapshot = datasource.snapshot()
                snapshot.appendItems(tagNames, toSection: .main)
                datasource.apply(snapshot)
                //let date = "\(item.saveDate)".split(separator: " ")[0]
                self.saveDate.text = "저장 날짜 : \(ms.dateToString(saveDate: item.saveDate))"
            }.store(in: &subscriptions)
    }

    // UI 구성 및 버튼 탭 했을 때
    /// **기본 UI 구성**
    private func setupUI() {
        thumbnailImageView.layer.cornerRadius = 12
        // 메모 내용에 line spacing 주기
        memoContents.setLineSpacing(lineSpacing: 4)
    }
    
    /// **navigation UI 구성**
    private func navigationSetupUI() {
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "편집", style: .plain, target: self, action: #selector(editMode))
        navigationItem.backButtonTitle = ""
    }
    
    /// **편집 뷰 불러오기**
    @objc func editMode() {
        let sb = UIStoryboard(name: "Edit", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "EditViewController") as! EditViewController
        vc.items.send(urlItems.value) // 현재의 링크 정보 보내기
        navigationController?.pushViewController(vc, animated: true)
    }
    
    /// **링크 복사 기능**
    @IBAction func copyTapped(_ sender: Any) {
        // urlLabel의 텍스트를 클립보드에 저장
        UIPasteboard.general.string = self.urlLabel.text
        ms.alert(for: "링크가 복사되었습니다", vc: self)
    }
}
