//
//  BookMarkViewController.swift
//  LinkMark
//
//  Created by 김정윤 on 1/9/24.
//

import UIKit
import RealmSwift
import Combine
import SafariServices

class BookMarkViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    typealias Item = UrlList
    
    var datasource: UICollectionViewDiffableDataSource<Section, Item>!
    
    enum Section {
        case main
    }
    
    var vm: BookMarkViewModel!
    
    var subscriptions = Set<AnyCancellable>()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        vm = BookMarkViewModel(items: [])
        vm.sendItems()
        setNavigationUI()
        configureCollectionViewAndBind()
    }
    
    /// **컬렉션뷰 구성**
    private func configureCollectionView() {
        datasource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView, cellProvider: { collectionView, indexPath, item in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BookMarkCell", for: indexPath) as? BookMarkCell else { return nil }
            cell.configure(item: item)
            
            cell.safariBtn.tag = indexPath.row
            cell.safariBtn.addTarget(self, action: #selector(self.safariBtnTapped(sender:)), for: .touchUpInside)
            
            cell.bookmarkBtn.tag = indexPath.row
            cell.bookmarkBtn.addTarget(self, action: #selector(self.bookmarkBtnTapped(sender:)), for: .touchUpInside)
            
            return cell
        })
        collectionView.collectionViewLayout = layout()
        collectionView.delegate = self
        
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.main])
        snapshot.appendItems([], toSection: .main)
        datasource.apply(snapshot)
    }
    
    /// **컬렉션뷰 레이아웃**
    private func layout() -> UICollectionViewCompositionalLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(100))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(100))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
        group.interItemSpacing = .fixed(10)
        
        let section = NSCollectionLayoutSection(group: group)
        
        return UICollectionViewCompositionalLayout(section: section)
    }
    
    /// **컬렉션뷰에 데이터 보여주기 및 상세보기 불러오기 **
    private func bind() {
        // output : data -> 데이터 가져와 collectionview 보여주기
        vm.items
            .receive(on: RunLoop.main)
            .sink { item in
                var snapshot = self.datasource.snapshot()
                snapshot.deleteItems(item)
                snapshot.appendItems(item, toSection: .main)
                self.datasource.apply(snapshot, animatingDifferences: false)
            }.store(in: &subscriptions)
        
        // input : user interaction -> 누른 링크의 상세뷰로 넘어가기
        vm.selectedItem
            .compactMap{ $0 }
            .receive(on: RunLoop.main)
            .sink { [unowned self] item in
                let sb = UIStoryboard(name: "Detail", bundle: nil)
                let vc = sb.instantiateViewController(withIdentifier: "DetailViewController") as! DetailViewController
                vc.urlItems.send(item)
                navigationController?.pushViewController(vc, animated: true)
            }.store(in: &subscriptions)
    }
    
    /// **컬렉션뷰 구성 -> 컬렉션뷰 데이터 보여주기**
    /// - 현재 즐겨찾기 중인 URL이 하나도 없다면 emptyView 보여주기
    /// - 아니라면 emptyView 지우기
    private func configureCollectionViewAndBind() {
        if vm.items.value.count == 0 {
            collectionView.setEmptyMessage("즐겨찾기 된 URL이 없어요", "", vc: "BookMark")
        } else {
            collectionView.restore()
        }
        configureCollectionView()
        bind()
    }

    
    // 네비게이션 구성 및 버튼 탭 했을 때
    /// **네비게이션 구성**
    func setNavigationUI() {
        navigationItem.backButtonTitle = ""
        navigationController?.navigationBar.tintColor = .black
    }
    
    /// **사파리 버튼을 누르면 사용자가 선택한 항목의 인덱스 가져와 웹으로 띄움**
    @objc func safariBtnTapped(sender: UIButton) {
        //print("\(sender.tag) 버튼의 Tag로 index값을 받아서 데이터 처리")
        let url = vm.selectUrl(at: sender.tag)
        let safari = SFSafariViewController(url: url)
        self.present(safari, animated: true)
    }
    
    /// **즐겨찾기 상태 변화 주기**
    @objc func bookmarkBtnTapped(sender: UIButton) {
        vm.bookmarkStateChange(at: sender.tag)
        vm.sendItems()
        configureCollectionViewAndBind()
    }
}

extension BookMarkViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        vm.didSelect(at: indexPath)
    }
}
