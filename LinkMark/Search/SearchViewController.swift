//
//  SearchViewController.swift
//  LinkMark
//
//  Created by 김정윤 on 1/9/24.
//

import UIKit
import RealmSwift
import Combine
import SafariServices

class SearchViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    
    var vm: SearchViewModel! // ! 안해주면 init 붉은줄~
    var subscriptions = Set<AnyCancellable>()
    
    typealias Item = UrlList
    
    enum Section {
        case main
    }
    
    var datasource: UICollectionViewDiffableDataSource<Section, Item>!
    
    // 서치바 정의
    let searchController = UISearchController(searchResultsController: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSerchBarAndNavi()
        hideKeyBoardWhenTappedScreen()
        vm = SearchViewModel()
        configureCollectionView()
        collectionView.setEmptyMessage("제목, 메모, URL에", "검색어가 포함된 결과가 나타나요", vc: "Search")
        bind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureCollectionView()
        search()
    }
    
    /// **컬렉션뷰 구성**
    private func configureCollectionView() {
        datasource = UICollectionViewDiffableDataSource(collectionView: collectionView, cellProvider: { collectionView, indexPath, item in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SearchCell", for: indexPath) as? SearchCell else { return nil }
            cell.configure(item)
            cell.safariBtn.tag = indexPath.row
            // 사파리 버튼에 함수 넣어주기
            cell.safariBtn.addTarget(self, action: #selector(self.safariBtnTapped(sender:)), for: .touchUpInside)
            cell.bookmarkBtn.tag = indexPath.row
            cell.bookmarkBtn.addTarget(self, action: #selector(self.bookmarkBtnTapped(sender:)), for: .touchUpInside)
            
            return cell
        })
        
        // 레이아웃 구성
        collectionView.collectionViewLayout = layout()
        
        // snapshot 구성
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.main])
        snapshot.appendItems([], toSection: .main)
        datasource.apply(snapshot)
        
        // 사용자의 터치 감지
        collectionView.delegate = self
    }
    
    /// **컬렉션뷰 레이아웃**
    private func layout() -> UICollectionViewCompositionalLayout {
        
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(110))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(110))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        
        return UICollectionViewCompositionalLayout(section: section)
    }
    
    /// ** 컬렉션뷰에 데이터 보여주기 및 상세보기 불러오기**
    private func bind() {
        // output => data
        vm.$searchResults
            .receive(on: RunLoop.main)
            .sink { results in
                var snapshot = self.datasource.snapshot()
                snapshot.appendItems(results, toSection: .main)
                self.datasource.apply(snapshot, animatingDifferences: false)
            }.store(in: &subscriptions)
        
        // input => user interaction
        vm.selectedItem
            .receive(on: RunLoop.main)
            .sink { item in
                let sb = UIStoryboard(name: "Detail", bundle: nil)
                let vc = sb.instantiateViewController(withIdentifier: "DetailViewController") as! DetailViewController
                vc.urlItems.send(item)
                self.navigationController?.pushViewController(vc, animated: true)
            }.store(in: &subscriptions)
    }
    
    // UI 구성 및 버튼 탭 했을 때
    /// **검색**
    /// - 검색어 이용해서 데이터 찾아 결과에 따른 뷰 세팅
    /// - 결과가 없다면 emptyView
    /// - 결과가 있다면 emptyView 삭제
    private func search() {
        guard let keyword = searchController.searchBar.text, !keyword.isEmpty else { return }
        //print("appear: \(keyword)")
        // 제목/URL/메모에 해당 키워드가 들어가는 결과가 있다면 true, 아니라면 false
        let result = vm.searchItems(keyword: keyword)
        if result {
            collectionView.restore()
        } else {
            collectionView.setEmptyMessage("", "검색 결과가 없어요", vc: "Search")
        }
    }
    
    /// **서치바 / 네비바 세팅**
    private func setupSerchBarAndNavi() {
        searchController.hidesNavigationBarDuringPresentation = false // 검색하는동안 네비게이션 보이게
        searchController.searchBar.placeholder = "검색어를 입력해주세요" // 검색어 입력칸에 안내 문구
        searchController.searchBar.becomeFirstResponder() // 검색창으로 왔을 때, 오토포커스
        self.navigationItem.searchController = searchController
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        searchController.searchBar.tintColor = .lightGray
        navigationController?.navigationBar.tintColor = .lightGray
    }
    
    /// **버튼을 누르면 사용자가 선택한 항목의 인덱스 가져와 웹으로 띄움**
    @objc func safariBtnTapped(sender: UIButton) {
        let url = vm.selectUrl(at: sender.tag)
        let safari = SFSafariViewController(url: url)
        self.present(safari, animated: true)
    }
    
    /// **북마크 태그 이용해서 북마크 표시**
    @objc func bookmarkBtnTapped(sender: UIButton) {
        vm.bookmarkToggle(at: sender.tag)
        var snapshot = datasource.snapshot()
        snapshot.reconfigureItems([vm.searchResults[sender.tag]])
        datasource.apply(snapshot)
    }
    
    // 키보드 관련 이벤트
    /// 입력 시작(이벤트 시작)을 알림
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    /// 화면 눌렀을 때 키보드 내려가게
    func hideKeyBoardWhenTappedScreen() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapHandler))
        // 터치 시, 현재 뷰의 터치를 취소
        // 기본값은 true이며, 상호작용이 필요하면 false로 처리
        tapGesture.cancelsTouchesInView = false
        searchController.searchBar.showsCancelButton = false // Cancel 버튼 숨기기
        view.addGestureRecognizer(tapGesture)
    }
    
    /// 입력이 끝남(이벤트가 끝남)을 알려줌
    @objc func tapHandler() {
        searchController.searchBar.endEditing(true)
    }
}

// 검색창 눌렀을 때
extension SearchViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        configureCollectionView()
        collectionView.restore()
        collectionView.setEmptyMessage("제목, 메모, URL에", "검색어가 포함된 결과가 나타나요", vc: "Search")
    }
}

// 검색(엔터) 시
extension SearchViewController: UISearchBarDelegate{
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        search()
    }
}

extension SearchViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // detail view 열기 위한 아이템 보내기 
        vm.didSelect(at: indexPath)
    }
}


