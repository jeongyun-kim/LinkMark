//  HomeViewController.swift
//  LinkMark


import UIKit
import Combine
import SafariServices
import RealmSwift
import Toast

class HomeViewController: UIViewController{
    @IBOutlet weak var filterBtn: UIButton!
    @IBOutlet weak var addBtn: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var modeBtn: UIButton!
    
    // Item 정의
    enum Item: Hashable {
        case url(UrlList)
        case tag(Tag)
    }

    // Section 정의
    enum Section: Int {
        case tagFilter
        case main
    }
    
    // datasource 정의
    var datasource: UICollectionViewDiffableDataSource<Section, Item>!
    
    // subscription 정의
    var subscriptions = Set<AnyCancellable>()
    
    // vieModel 불러오기
    var vm: HomeViewModel!
    
    enum Mode {
        case view
        case select
    }
    
    let ms = Methods()
    
    // 현재 필터링 상태 : 최신순 = false / 오래된 순 = true
    var filterState: Bool = false
    
    // 삭제할 아이템 저장하는 배열: [인덱스 : 해당 아이템의 id]
    var dictSelectedIndexPath: [IndexPath: UUID] = [:]
    
    /// **Mode 별 세팅**
    var eMode: Mode = .view {
        didSet {
            switch eMode {
            case .view:
                setEmptyMessageView_And_UrlsCollectionView()
                // 선택 모드 -> 뷰 모드로 진입 시
                DispatchQueue.main.async { [unowned self] in
                    self.filterBtn.isHidden = false
                    self.addBtn.isHidden = false
                    // 취소 -> 선택
                    self.modeBtn.setTitle("선택", for: .normal)
                    // 삭제 플로팅 버튼 없애기
                    self.floatingBtn.removeFromSuperview()
                    // 선택된 아이템들 목록 삭제
                    self.dictSelectedIndexPath.removeAll()
                    // 여러 아이템 선택하지 못하도록 false
                    self.collectionView.allowsMultipleSelection = false
                }
            case .select:
               configureCollectionView()
               bind()
                DispatchQueue.main.async { [unowned self] in
                    self.filterBtn.isHidden = true
                    self.addBtn.isHidden = true
                    // 선택 -> 취소
                    self.modeBtn.setTitle("취소", for: .normal)
                    // 여러 아이템 선택할 수 있음
                    self.collectionView.allowsMultipleSelection = true
                    // 삭제 플로팅 버튼 띄우기
                    self.view.addSubview(floatingBtn)
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configurePopUpMenu()
        setupUI()
        configureRefreshControl()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setEmptyMessageView_And_UrlsCollectionView()
    }
    
    /// **데이터가 있는지 없는지에 따른 뷰 그리기**
    /// - viewMode에서 사용
    /// - collectionView Message Setting + collectionViewSetting(configureCollectionView + bind)
    func setEmptyMessageView_And_UrlsCollectionView() {
        vm = HomeViewModel(items: [], tags: [])
        vm.sendAllItems(filterState: filterState) // 현재 필터링 상태에 맞는 아이템 전송
        // 데이터가 없을 때, 비어있음을 표현하는 메시지뷰 보여주기
        if vm.items.value.count == 0 { // 필터링 전 모든 링크 데이터의 개수가 0개라면
            collectionView.setEmptyMessage("저장된 URL이 없어요", "상단의 버튼을 통해 URL을 추가해보세요", vc: "Home")
            modeBtn.isHidden = true
        } else {
            collectionView.restore()
            modeBtn.isHidden = false
        }
        // URL리스트 컬렉션뷰 구성 및 출력
        configureCollectionView()
        let animation = ms.lottieView(view: self.view, name: "home_loading")
        animation.isHidden = false
        animation.play()
        bind()
        animation.isHidden = true
        animation.stop()
        
    }

    /// **Mode, Section에 따른 CollectionView 구성**
    private func configureCollectionView() {
        datasource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView, cellProvider: { collectionView, indexPath, item in
            let section = Section(rawValue: indexPath.section)
            var value: Any
            switch item {
            case .tag(let item):
                value = item
            case .url(let item):
                value = item
            }
            switch section {
            case .main:
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "UrlListCell", for: indexPath) as? UrlListCell
                else { return UICollectionViewCell() }
                switch (self.eMode) {
                case .view:
                    cell.configure(item: value as! UrlList, mode: .view)
                    // 사파리 불러오는 버튼에 인덱스 값 주기
                    cell.safariBtn.tag = indexPath.row
                    // 사파리 버튼에 함수 넣어주기
                    cell.safariBtn.addTarget(self, action: #selector(self.safariBtnTapped(sender:)), for: .touchUpInside)
                    // 북마크 버튼에 인덱스 값 주기
                    cell.bookmarkBtn.tag = indexPath.row
                    // 북마크 버튼에 함수 넣어주기
                    cell.bookmarkBtn.addTarget(self, action: #selector(self.bookmarkBtnTapped(sender: )), for: .touchUpInside)
                    return cell
                case .select:
                    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "UrlListCell", for: indexPath) as? UrlListCell
                    else { return UICollectionViewCell() }
                    cell.configure(item: value as! UrlList, mode: .select)
                    return cell
                }
            case .tagFilter:
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HomeFilterTagCell", for: indexPath) as? HomeFilterTagCell else { return UICollectionViewCell() }
                cell.configure(item: value as! Tag)
                cell.filterTagLabelBtn.tag = indexPath.row
                cell.filterTagLabelBtn.addTarget(self, action: #selector(self.tagBtnTapped(sender: )), for: .touchUpInside)
                return cell
            default: return UICollectionViewCell()
            }})
        
        // 각 섹션별 레이아웃 생성
        func layout() -> UICollectionViewLayout {
            let layout = UICollectionViewCompositionalLayout { [unowned self] section, env in
                switch section {
                case 0: return self.tagListLayout()
                case 1: return self.UrlListLayout()
                default: return nil
                }
            }
            layout.register(TagListBackgroundView.self, forDecorationViewOfKind: "backgroundDecorationView")
            return layout
        }
        // 레이아웃 불러오기
        collectionView.collectionViewLayout = layout()

        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.tagFilter, .main])
        snapshot.appendItems([], toSection: .main)
        snapshot.appendItems([], toSection: .tagFilter)
        datasource.apply(snapshot, animatingDifferences: false)
        
        // 사용자가 어떤 아이템을 터치하는지 감지하기 위해
        collectionView.delegate = self
    }
    
    // 각 섹션 별 레이아웃
    /// **태그 리스트 레이아웃**
    private func tagListLayout() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .estimated(1), heightDimension: .estimated(1))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .absolute(8000), heightDimension: .estimated(1))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        group.interItemSpacing = .fixed(10)
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = .init(top: 7, leading: 16, bottom: 7, trailing: 16)
        section.orthogonalScrollingBehavior = .continuous
        // 섹션의 백그라운드 컬러 변경
        if vm.tags.value.count >= 1 {
            let sectionBackground = NSCollectionLayoutDecorationItem.background(elementKind: "backgroundDecorationView")
            section.decorationItems = [sectionBackground]
        }
        return section
    }
    
    ///**링크 리스트 레이아웃**
    private func UrlListLayout() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(110))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(110))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
        group.interItemSpacing = .fixed(10)
        
        let section = NSCollectionLayoutSection(group: group)
        return section
    }
    
    
    /// **각 섹션에 데이터 보여주기 및 상세보기 불러오기**
    private func bind() {
        // output : collectionView Setting
        // - Urls
        vm.items
            .receive(on: RunLoop.main)
            .sink { items in
                var snapshot = self.datasource.snapshot()
                for item in items {
                    snapshot.deleteItems([.url(item)])
                    snapshot.appendItems([.url(item)], toSection: .main)
                }
                self.datasource.apply(snapshot, animatingDifferences: false)
            }.store(in: &subscriptions)
        // - filterTags
        vm.tags
            .receive(on: RunLoop.main)
            .sink { tags in
                var snapshot = self.datasource.snapshot()
                for tag in tags {
                    snapshot.deleteItems([.tag(tag)])
                    snapshot.appendItems([.tag(tag)], toSection: .tagFilter)
                }
                self.datasource.apply(snapshot, animatingDifferences: false)
            }.store(in: &subscriptions)
        
        // input(User Interaction) -> DetailView
        vm.selectedItem
            .receive(on: RunLoop.main)
            .sink{ [unowned self] urlItem in
                let sb = UIStoryboard(name: "Detail", bundle: nil)
                let vc = sb.instantiateViewController(withIdentifier: "DetailViewController") as! DetailViewController
                vc.urlItems.send(urlItem)
                vc.filterState = filterState
                // 창 띄우기
                navigationController?.pushViewController(vc, animated: true)
            }.store(in: &subscriptions)
    }
    
    // UI구성 및 버튼 탭 했을 때
    /// **기본 UI 구성**
    private func setupUI() {
        // 네비게이션 백버튼 지우기
        navigationItem.backButtonTitle = ""
        navigationController?.navigationBar.tintColor = .black
        // 앱의 포인트 컬러 -> UIColor
        let customColor = UIColor(hue: 0.7139, saturation: 0.4, brightness: 1, alpha: 1.0)
        // 버튼이 선택되었을 때(highlight) 컬러 세팅
        let addHighlightImage = UIImage(systemName: "plus.square.dashed")?.withTintColor(customColor, renderingMode: .alwaysOriginal)
        let filterHighlightImage = UIImage(systemName: "line.3.horizontal")?.withTintColor(customColor, renderingMode: .alwaysOriginal)
        // 버튼 선택시 컬러 포인트 컬러로 변경
        addBtn.setImage(addHighlightImage, for: .highlighted)
        filterBtn.setImage(filterHighlightImage, for: .highlighted)
    }

    /// **필터링 기능 popUpMenu 구성**
    private func configurePopUpMenu() {
        let popUPBtnClosure = {  [unowned self] (action: UIAction) in
            if action.title ==  "최신순" {
                self.filterState = false
            } else {
                self.filterState = true
            }
            self.setEmptyMessageView_And_UrlsCollectionView()
        }
        let asc = UIAction(title: "최신순", handler: popUPBtnClosure)
        let desc = UIAction(title: "오래된 순", handler: popUPBtnClosure)
        filterBtn.menu = UIMenu(children: [asc, desc])
        filterBtn.showsMenuAsPrimaryAction = true
        filterBtn.changesSelectionAsPrimaryAction = true
    }
    
    /// ** 삭제 버튼(플로팅 버튼) 생성**
    lazy var floatingBtn: UIButton = {
        let button = UIButton()
        // 버튼의 backgroundColor 및 스타일, 이미지 지정 가능
        var config = UIButton.Configuration.filled()
        // backgroundColor 변경
        config.baseBackgroundColor = UIColor(hue: 0.7139, saturation: 0.4, brightness: 1, alpha: 1.0)
        // 버튼의 코너스타일
        config.cornerStyle = .capsule
        // 버튼 내 이미지 변경
        config.image = UIImage(systemName: "trash.fill")?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 17, weight: .medium))
        // 버튼 스타일 적용
        button.configuration = config
        // 플로팅 버튼 뒤 그림자 생성
        // 그림자의 블러 정도
        button.layer.shadowRadius = 10
        // 플로팅 버튼의 그림자 투명도 지정
        button.layer.shadowOpacity = 0.35
        // 버튼에 액션 넣기
        button.addTarget(self, action: #selector(floatingBtnTapped), for: .touchUpInside)
        return button
         }()
    
    /// **삭제 버튼(플로팅 버튼) 눌렀을 때**
    @objc func floatingBtnTapped() {
        // 알림창 제목 및 메시지 설정
        let alert = ms.alertSetTitle(title: "정말 삭제하시겠습니까?", message: "삭제한 링크는 복구할 수 없어요🥺")
        // 액션 추가(취소, 확인)
        let cancelAction = UIAlertAction(title: "취소", style: .cancel)
        // 확인 누르면 아이디가 들어있는 배열돌면서 해당 아이디의 아이템들 삭제
        let confirmAction = UIAlertAction(title: "확인", style: .default, handler: { [unowned self] _ in
            self.vm.deleteItems(dictSelectedIndexPath: dictSelectedIndexPath)
            self.dismiss(animated: true)
            self.eMode = .view
        })
        // 액션 폰트 컬러 변경
        cancelAction.setValue(UIColor(hue: 0.7083, saturation: 0.34, brightness: 1, alpha: 1.0), forKey: "titleTextColor")
        confirmAction.setValue(UIColor(hue: 0.7194, saturation: 0.41, brightness: 1, alpha: 1.0), forKey: "titleTextColor")
        // 액션 추가
        alert.addAction(cancelAction)
        alert.addAction(confirmAction)
        // 알림창 띄우기
        present(alert, animated: true)
    }
    
    /// **뷰가 서브뷰의 배치를 다 했다는 소식을 뷰 컨트롤러에게 알림**
    /// - 플로팅버튼 그리기
    override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            floatingBtn.frame = CGRect(x: view.frame.size.width - 90, y: view.frame.size.height - 190, width: 60, height: 60)
        }
    
    /// **모드 변경**
    @IBAction func modeChangeBtnTapped(_ sender: Any) {
        // 누를때마다 모드 변경
        // 지금 현재 모드가 뷰 모드(true)라면 선택 모드로 전환
        // 현재 모드가 선택 모드(false)라면 뷰 모드로 전환
        eMode = eMode == .view ? .select : .view
    }

    /// **북마크 버튼을 누르면 사용자가 선택한 항목의 인덱스를 가져와 즐겨찾기 등록/해제**
    ///<- 스냅샷 변경
    @objc func bookmarkBtnTapped(sender: UIButton) {
        // 현재 항목의 인덱스를 viewModel로 보내 해당 아이템의 즐겨찾기 상태 변경
        vm.bookmarkStateChange(at: sender.tag)
        // 현재의 스냅샷
        var snapshot = datasource.snapshot()
        // 해당 인덱스의 스냅샷만 변경
        snapshot.reconfigureItems([.url(vm.items.value[sender.tag])])
        // 스냅샷 새로 보내 보여주는 표시 변경
        datasource.apply(snapshot, animatingDifferences: false)
    }
    
    /// **태그 목록 내 태그 선택 시**
    @objc func tagBtnTapped(sender: UIButton) {
        let sb = UIStoryboard(name: "FilteredTag", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "FilteredTagViewController") as! FilteredTagViewController
        vc.tag = vm.getTag(at: sender.tag)
        let filteredItems = vm.getFilteredItems(tag: vm.getTag(at: sender.tag))
        if filteredItems.count > 0 {
            navigationController?.pushViewController(vc, animated: true)
        } else {
            ms.toastMessage(message: "저장된 목록이 없어요", view: self.view)
        }
    }
    
    /// **사파리 이동(화살표) 버튼을 누르면 사용자가 선택한 항목의 인덱스 가져와 웹으로 띄움**
    @objc func safariBtnTapped(sender: UIButton) {
        //vm.getURL(at: sender.tag)
        let url = vm.selectUrl(at: sender.tag)
        let safari = SFSafariViewController(url: url)
       self.present(safari, animated: true)
    }
    
    /// **URL 추가 버튼 선택 시**
    @IBAction func addBtnTapped(_ sender: Any) {
        let sb = UIStoryboard(name: "AddUrl", bundle: nil)
        let vc = sb.instantiateViewController(identifier: "AddUrlViewController") as! AddUrlViewController
        navigationController?.pushViewController(vc, animated: true)
    }
    
    /// **새로고침**
    private func configureRefreshControl() {
        collectionView.refreshControl = UIRefreshControl()
        collectionView.refreshControl?.addTarget(self, action: #selector(handleRefreshControl), for: .valueChanged)
        }
        
    // 2. 새로고침하는데 사용되는 메서드
    @objc func handleRefreshControl() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [unowned self] in
            // Realm으로부터 변경된 데이터 가져오기
            self.vm.sendAllItems(filterState: filterState)
            setEmptyMessageView_And_UrlsCollectionView()
            self.collectionView.refreshControl?.endRefreshing()
        }
    }
}

// 사용자가 어떤 링크정보를 선택하고 해제했는지
extension HomeViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // 모드에 따라 다르게
        switch eMode {
        // 선택 모드
        case .select:
            // 뷰모델로 선택한 아이템 인덱스 보내서 해당 아이템의 아이디 가져오기
            // 선택된 아이템 딕셔너리에 인덱스: 아이디로 저장
            let id = vm.getIdToDelete(at: indexPath)
            dictSelectedIndexPath[indexPath] = id
        // 뷰 모드
        // viewModel의 selectedItem(publisher)에 사용자가 선택한 아이템 데이터 보내기위해 어떤 아이템이 선택되었는지 메서드로 인덱스 값을 보냄
        // 해당 메서드는 받아온 인덱스값을 이용해 urlList의 해당 번째 아이템을 가져와 selectedItem(publisher)에 넘겨준 후
        // 현 뷰컨트롤러의 bind 내 vm.selectedItem을 통해 해당 아이템의 정보를 뿌려줌
        case .view:
            vm.didSelect(at: indexPath)
        }
    }
    // 선택해제한 아이템은 딕셔너리에서 지우기
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        dictSelectedIndexPath.removeValue(forKey: indexPath)
    }
}
