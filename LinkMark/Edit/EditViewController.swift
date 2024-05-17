//
//  EditViewController.swift
//  LinkMark
//
//  Created by 김정윤 on 1/14/24.
//

import UIKit
import Combine
import RealmSwift

class EditViewController: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var tagTextField: UITextField!
    @IBOutlet weak var memoTextCnt: UILabel!
    @IBOutlet weak var memoView: UIView!
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var urlTextField: UITextField!
    @IBOutlet weak var loadBtn: UIButton!
    @IBOutlet weak var memoTextView: UITextView!
    var vm: EditViewModel!
    
    typealias Item = Tag
    
    enum Section {
        case main
    }
    
    var datasource: UICollectionViewDiffableDataSource<Section, Item>!
    
    var subscriptions = Set<AnyCancellable>()
    
    let ms = Methods()
    
    // 링크 데이터
    let items = CurrentValueSubject<UrlList, Never>(UrlList(image: nil, title: "", url: "", saveDate: Date(), tags: List<Tag>()))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        vm = EditViewModel(tags: [])
        vm.sendTags()
        vm.selectedTags = items.value.tags // 상세보기 중이던 링크가 가진 태그 정보들(리스트) 보내기
        vm.selectedTagsToDict() // 보낸 리스트 형식의 태그들을 딕셔너리 형태로 변환
        configureCollectionView()
        itemsBind()
        tagsBind()
    }
    
    /// **컬렉션뷰 구성**
    private func configureCollectionView() {
        datasource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView, cellProvider: { collectionView, indexPath, item in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EditTagCell", for: indexPath) as? EditTagCell else { return nil }
            cell.configure(item, tags: self.vm.selectedTags) // 현재의 태그랑 편집하려는 링크가 가진 태그 목록 보내기
            cell.deleteBtn.tag = indexPath.row
            cell.deleteBtn.addTarget(self, action: #selector(self.deleteTag(sender: )), for: .touchUpInside)
            return cell
        })
        collectionView.collectionViewLayout = layout()
        
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.main])
        snapshot.appendItems([], toSection: .main)
        datasource.apply(snapshot, animatingDifferences: false)
        
        collectionView.delegate = self
        collectionView.allowsMultipleSelection = true
    }
    
    /// **컬렉션뷰 레이아웃**
    func layout() -> UICollectionViewCompositionalLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(35))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(35))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
        //group.interItemSpacing = .fixed(10)
        
        let section = NSCollectionLayoutSection(group: group)
        
        return UICollectionViewCompositionalLayout(section: section)
    }
    
    /// **URL 데이터 및 태그 데이터 불러오기 **
    func itemsBind() {
        items
            .receive(on: RunLoop.main)
            .sink { item in
                self.titleTextField.text = item.title
                self.urlTextField.text = item.url
                self.thumbnailImageView.image = UIImage(data: item.image!)
                self.memoTextView.text = item.memo
                let textCnt = item.memo?.count
                self.memoTextCnt.text = "(\(textCnt!)/500)"
            }.store(in: &subscriptions)
    }
    func tagsBind() {
        vm.tags
            .receive(on: RunLoop.main)
            .sink { tags in
                var snapshot = self.datasource.snapshot()
                snapshot.deleteItems(tags)
                snapshot.appendItems(tags, toSection: .main)
                self.datasource.apply(snapshot, animatingDifferences: false)
            }.store(in: &subscriptions)
    }
    
    // UI 구성 및 버튼 탭 했을 때
    /// **기본 UI 세팅**
    private func setupUI() {
        // 네비게이션에 저장 버튼 추가
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "저장", style: .plain, target: self, action: #selector(saveData))
        navigationItem.title = "URL 편집"
        // 썸네일 코너 깎기
        thumbnailImageView.layer.masksToBounds = true
        thumbnailImageView.layer.cornerRadius = 12
        // 메모 적는 칸 세팅
        memoView.layer.borderWidth = 1
        memoView.layer.borderColor = UIColor.systemGray5.cgColor
        memoView.layer.cornerRadius = 6
        // TextView delegate 설정 <- 글자수 제한
        memoTextView.delegate = self
        // 메모 적는 칸에 수정 제안 제거
        memoTextView.autocorrectionType = .no
        memoTextView.spellCheckingType = .no
        // 링크 불러오기 버튼 세팅
        loadBtn.layer.masksToBounds = true
        loadBtn.layer.cornerRadius = 10
        loadBtn.isEnabled = true
        // 제목 입력칸에 placehorder
        titleTextField.placeholder = "제목을 입력해주세요"
        // 링크 입력 칸 delegate
        tagTextField.delegate = self
        tagTextField.placeholder = "태그를 등록해주세요 (10자)"
        // 링크 수정 불가
        urlTextField.isEnabled = false
        loadBtn.isEnabled = false
        urlTextField.textColor = .systemGray
    }
    
    /// **태그 삭제**
    @objc func deleteTag(sender: UIButton) {
        vm.deleteTag(indexPath: sender.tag)
        configureCollectionView()
        tagsBind()
    }
    
    /// **URL 데이터 저장**
    @objc func saveData() {
        if titleTextField.text != "" {
            vm.saveData(id: items.value.id, title: titleTextField.text!, memo: memoTextView.text)
        }
        else {
            ms.alert(for: "제목을 입력해주세요", vc: self)
        }
        // 저장되면 홈으로 바로 돌아가기
        navigationController?.popToRootViewController(animated: true)
    }
    
    // 키보드 이벤트 관련
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func hideKeyBoardWhenTappedScreen() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapHandler))
        // 터치 시, 현재 뷰의 터치를 취소
        // 기본값은 true이며, 상호작용이 필요하면 false로 처리
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc func tapHandler() {
        self.view.endEditing(true)
    }
}

extension EditViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        vm.selectOrDeselectTag(at: indexPath)
        configureCollectionView()
        tagsBind()
    }
}

// 메모 입력 칸에 글자수 제한(500자)
extension EditViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let currentText = memoTextView.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return false }
        let changedText = currentText.replacingCharacters(in: stringRange, with: text)
        memoTextCnt.text = "(\(changedText.count)/500)"
        return changedText.count <= 499
    }
}

// 태그 입력 칸 글자수 제한 및 엔터 눌렀을 때
extension EditViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = tagTextField.text ?? ""
        guard let stringRange = Range(range, in: currentText) else {
            return false }
        let changedText = currentText.replacingCharacters(in: stringRange, with: string)
        return changedText.count <= 10
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let addedTagNames = vm.getAddedTagsNames()
        guard let tagName = tagTextField.text else { return false }
        if addedTagNames.contains(tagName) {
            ms.alert(for: "이미 동일한 이름의 태그가 있어요", vc: self)
        } else if addedTagNames.count >= 15 {
            ms.alert(for: "태그는 15개까지만 저장할 수 있어요", vc: self)
        } else if tagName == "" {
            ms.alert(for: "태그명을 입력해주세요", vc: self)
        } else {
            vm.saveTag(tagName: tagName)
            // 최근 등록순으로 보여주기
            vm.sendTags()
            tagTextField.text = ""
        }
        return true
    }
}

