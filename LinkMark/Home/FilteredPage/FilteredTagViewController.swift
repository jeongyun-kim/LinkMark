//
//  FilteredTagViewController.swift
//  LinkMark
//
//  Created by 김정윤 on 4/9/24.
//

import UIKit
import RealmSwift
import Combine
import SafariServices

class FilteredTagViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    enum Mode {
        case view
        case select
    }

    typealias Item = UrlList
    
    enum Section {
        case main
    }
    
    var subscriptions = Set<AnyCancellable>()
    
    var datasource: UICollectionViewDiffableDataSource<Section, Item>!
    
    var tag = Tag(tagName: "", saveDate: Date())
    
    var vm: HomeViewModel!
    
    // 삭제할 아이템 저장하는 배열: [인덱스 : 해당 아이템의 id]
    var dictSelectedIndexPath: [IndexPath: UUID] = [:]
    
    /// **Mode 별 세팅**
    var eMode: Mode = .view {
        didSet {
            switch eMode {
            case .view:
                configureCollectionView()
                collectionView.allowsMultipleSelection = false
                let filteredItems = vm.getFilteredItems(tag: tag)
                if filteredItems.count == 0 { // 삭제 후 해당 태그가 포함되는 링크가 하나도 없다면
                    navigationController?.popToRootViewController(animated: true) // 홈뷰로 돌아오기
                } else { // 데이터 업데이트
                    vm.items.send(filteredItems)
                    // 삭제 플로팅 버튼 없애기
                    self.floatingBtn.removeFromSuperview()
                    // 선택된 아이템들 목록 삭제
                    self.dictSelectedIndexPath.removeAll()
                    bind() // 업데이트 된 데이터 불러오기
                }
            case .select:
                configureCollectionView()
                bind()
                collectionView.allowsMultipleSelection = true
                view.addSubview(floatingBtn)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupUI()
        configureCollectionView()
        vm = HomeViewModel(items: [], tags: [])
        vm.items.send(vm.getFilteredItems(tag: tag))
        bind()
    }

    /// **CollectionView 구성**
    func configureCollectionView() {
        datasource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView, cellProvider: { collectionView, indexPath, item in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "UrlListCell", for: indexPath) as? UrlListCell
            else { return nil }
            switch self.eMode {
            case .view:
                cell.configure(item: item, mode: .view)
                cell.bookmarkBtn.tag = indexPath.row
                cell.bookmarkBtn.addTarget(self, action: #selector(self.bookmarkStateChange(sender: )), for: .touchUpInside)
                cell.safariBtn.tag = indexPath.row
                cell.safariBtn.addTarget(self, action: #selector(self.safariBtnTapped(sender: )), for: .touchUpInside)
            case .select:
                cell.configure(item: item, mode: .select)
            }
            return cell
        })
        collectionView.collectionViewLayout = layout()
        collectionView.delegate = self
        var snapshot = datasource.snapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems([], toSection: .main)
        datasource.apply(snapshot, animatingDifferences: false)
    }
    
    /// **컬렉션뷰 레이아웃**
    func layout() -> UICollectionViewCompositionalLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(110))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(110))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        return UICollectionViewCompositionalLayout(section: section)
    }
    
    /// **컬렉션뷰에 데이터 보여주기 및 상세보기 불러오기**
    func bind(){
        // output : collectionview setting
        vm.items
            .receive(on: RunLoop.main)
            .sink { [unowned self] item in
                var snapshot = self.datasource.snapshot()
                snapshot.deleteItems(item)
                snapshot.appendItems(item, toSection: .main)
                self.datasource.apply(snapshot, animatingDifferences: false)
            }.store(in: &subscriptions)
        // input : collectionview -> detail view
        vm.selectedItem
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink{ [unowned self] item in
                let sb = UIStoryboard(name: "Detail", bundle: nil)
                let vc = sb.instantiateViewController(withIdentifier: "DetailViewController") as! DetailViewController
                vc.urlItems.send(item)
                // 창 띄우기
                navigationController?.pushViewController(vc, animated: true)
            }.store(in: &subscriptions)
    }
    
    // UI 구성 및 버튼 선택 시
    /// **기본 UI 구성**
    func setupUI() {
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.title = tag.tagName
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "선택", style: .plain, target: self, action: #selector(eModeStateChange))
    }
    
    /// **사파리 버튼 클릭 후 창 띄우기**
    @objc func safariBtnTapped(sender: UIButton) {
        let url = vm.selectUrl(at: sender.tag)
        let safari = SFSafariViewController(url: url)
       self.present(safari, animated: true)
    }
    
    /// **즐겨찾기 등록 / 해제**
    @objc func bookmarkStateChange(sender: UIButton) {
        vm.bookmarkStateChange(at: sender.tag)
        var snapshot = datasource.snapshot()
        snapshot.reconfigureItems([vm.items.value[sender.tag]])
        datasource.apply(snapshot, animatingDifferences: false)
    }
    
    /// **모드 변경 및 모드 별 네비게이션 우측 버튼 타이틀 변경**
    @objc func eModeStateChange() {
        if eMode == .view {
            eMode = .select
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "취소", style: .plain, target: self, action: #selector(eModeStateChange))
        } else {
            eMode = .view
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "선택", style: .plain, target: self, action: #selector(eModeStateChange))
        }
    }
    
    ///**삭제 버튼  구성**
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
    
    /// **삭제 버튼 눌렀을 때**
    @objc func floatingBtnTapped() {
        // 알림창 제목 및 메시지 설정
        let title: String = "정말 삭제하시겠습니까?"
        let message: String = "삭제한 링크는 복구할 수 없어요🥺"
        let titleColor = UIColor(hue: 0.7306, saturation: 0.54, brightness: 1, alpha: 1.0)
        let messageColor = UIColor.lightGray
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        // 제목 및 메시지 컬러 변경
        alert.setValue(NSAttributedString(string: title, attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16, weight: .bold), NSAttributedString.Key.foregroundColor : titleColor]), forKey: "attributedTitle")
        alert.setValue(NSAttributedString(string: message, attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 14, weight: .regular), NSAttributedString.Key.foregroundColor : messageColor]), forKey: "attributedMessage")
        alert.view.subviews.first?.subviews.first?.subviews.first?.backgroundColor = .white // 배경색 변경
        // 액션 추가(취소, 확인)
        let cancelAction = UIAlertAction(title: "취소", style: .cancel)
        // 확인 누르면 아이디가 들어있는 배열돌면서 해당 아이디의 아이템들 삭제
        let confirmAction = UIAlertAction(title: "확인", style: .default, handler: { [unowned self] _ in
            self.vm.deleteItems(dictSelectedIndexPath: dictSelectedIndexPath)
            self.dismiss(animated: true)
            eModeStateChange()
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
    
    /// **삭제 버튼 그리기**
    override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            floatingBtn.frame = CGRect(x: view.frame.size.width - 90, y: view.frame.size.height - 190, width: 60, height: 60)
        }
}

extension FilteredTagViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch eMode {
        case .view:
            vm.didSelect(at: indexPath)
        case .select:
            let id = vm.getIdToDelete(at: indexPath)
            dictSelectedIndexPath[indexPath] = id
        }
    }
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        dictSelectedIndexPath.removeValue(forKey: indexPath)
    }
}
