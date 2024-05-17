//
//  TagManageViewController.swift
//  LinkMark
//
//  Created by 김정윤 on 4/18/24.
//

import UIKit
import Combine

class TagManageViewController: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var tagTextField: UITextField!
    
    let ms = Methods()
    
    typealias Item = Tag
    
    enum Section {
        case main
    }
    
    var datasource: UICollectionViewDiffableDataSource<Section, Item>!
    
    var subscriptions = Set<AnyCancellable>()
    
    var vm: SettingViewModel!
    
    var toDeleteTagsDict: [UUID: Tag] = [:]
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupUI()
        vm = SettingViewModel(tags: [])
        vm.sendTags()
        configureCollectionView()
        bind()
        hideKeyBoardWhenTappedScreen()
    }
    
    /// **태그 컬렉션뷰 구성**
    func configureCollectionView() {
        datasource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView, cellProvider: { collectionView, indexPath, item in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TagManageCell", for: indexPath) as? TagManageCell else { return nil }
            cell.configure(item: item)
            cell.tagNameBtn.tag = indexPath.row
            cell.tagNameBtn.addTarget(self, action: #selector(self.tagNameBtnTapped(sender: )), for: .touchUpInside)
            return cell
        })
        var snapshot = datasource.snapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems([], toSection: .main)
        datasource.apply(snapshot)
        
        collectionView.allowsMultipleSelection = true
        collectionView.delegate = self
        collectionView.collectionViewLayout = layout()
    }
    
    /// **컬렉션뷰 레이아웃**
    func layout() -> UICollectionViewCompositionalLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(40))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(2000))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
        group.interItemSpacing = .fixed(10)
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = .init(top: 10, leading: 0, bottom: 10, trailing: 0)
        return UICollectionViewCompositionalLayout(section: section)
    }
    
    /// **컬렉션뷰에 데이터 보여주기**
    func bind() {
        vm.tags
            .receive(on: RunLoop.main)
            .sink { [unowned self] tags in
                var snapshot = self.datasource.snapshot()
                snapshot.deleteItems(tags)
                snapshot.appendItems(tags, toSection: .main)
                self.datasource.apply(snapshot, animatingDifferences: true)
            }.store(in: &subscriptions)
    }

    // 기본 UI 구성 및 버튼 탭 했을 때
    /// **기본 UI 구성**
    private func setupUI() {
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.title = "태그 관리"
        navigationItem.backButtonTitle = ""
        navigationController?.navigationBar.tintColor = .black
        tagTextField.placeholder = "태그를 등록하세요 (10자)"
        tagTextField.autocorrectionType = .no
        tagTextField.spellCheckingType = .no
        tagTextField.delegate = self
    }
    
    /// **태그명 수정**
    @objc func tagNameBtnTapped(sender: UIButton) {
        let tagName = vm.getTag(sender.tag).tagName
        let alert = ms.alertSetTitle(title: "태그명 수정", message: "10자가 넘으면 10자까지만 저장돼요☺️")
        alert.addTextField { textField in
            textField.text = tagName
        }
        let saveAction = UIAlertAction(title: "저장", style: .default) {
            action in
            if let textField = alert.textFields?.first {
                let tagName = textField.text!
                let addedTagNames = self.vm.getAddedTagsNames()
                if tagName != "" {
                    if addedTagNames.contains(tagName) {
                        self.ms.alert(for: "이미 동일한 이름의 태그가 있어요", vc: self)
                    }
                    else {
                        var newTagName = ""
                        if tagName.count >= 11 {
                            newTagName = String(tagName.prefix(10))
                        } else {
                            newTagName = tagName
                        }
                        let tag = self.vm.getTag(sender.tag)
                        self.vm.editTag(tag: tag, newTagName: newTagName)
                        self.configureCollectionView()
                        self.bind()
                        self.ms.alert(for: "태그명 수정 완료", vc: self)
                    }
                } else {
                    self.ms.alert(for: "태그명을 입력하세요", vc: self)
                }
            }
        }
        let cancelAction = UIAlertAction(title: "취소", style: .cancel)
        // 액션 폰트 컬러 변경
        cancelAction.setValue(UIColor(hue: 0.7083, saturation: 0.34, brightness: 1, alpha: 1.0), forKey: "titleTextColor")
        saveAction.setValue(UIColor(hue: 0.7194, saturation: 0.41, brightness: 1, alpha: 1.0), forKey: "titleTextColor")
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true)
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
    
    /// **삭제 버튼(플로팅 버튼) 생성**
    lazy var floatingBtn: UIButton = {
        let button = UIButton()
        // 버튼의 backgroundColor 및 스타일, 이미지 지정 가능
        var config = UIButton.Configuration.filled()
        // backgroundColor 변경
        config.baseBackgroundColor = UIColor(hue: 0.7139, saturation: 0.4, brightness: 1, alpha: 1.0)
        // 버튼의 코너스타일
        config.cornerStyle = .medium
        button.configuration = config
        // 플로팅 버튼 뒤 그림자 생성
        // 그림자의 블러 정도
        button.layer.shadowRadius = 10
        // 플로팅 버튼의 그림자 투명도 지정
        button.layer.shadowOpacity = 0.3
        button.alpha = 0
        button.setTitle("삭제", for: .normal)
        // 버튼에 액션 넣기
        button.addTarget(self, action: #selector(floatingBtnTapped), for: .touchUpInside)
        return button
         }()
    
    /// **삭제 버튼 눌렀을 때**
    @objc func floatingBtnTapped(sender: UIButton) {
        if floatingBtn.alpha == 1.0 { // 삭제 버튼이 눈에 보일 때
            // 알림창 제목 및 메시지 설정
            let alert = ms.alertSetTitle(title: "선택한 태그들을 \n삭제하시겠습니까?", message: "")
            // 액션 추가(취소, 확인)
            let cancelAction = UIAlertAction(title: "취소", style: .cancel)
            // 확인 누르면 아이디가 들어있는 배열돌면서 해당 아이디의 아이템들 삭제
            let confirmAction = UIAlertAction(title: "확인", style: .default, handler: { [unowned self] _ in
                vm.deleteTags(toDeleteTagsDict)
                toDeleteTagsDict.removeAll()
                configureCollectionView()
                bind()
                self.dismiss(animated: true)
                self.floatingBtn.alpha = 0
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
    }
    
    /// **플로팅버튼 그리기**
    override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
        floatingBtn.frame = CGRect(x: 20, y: self.view.frame.maxY-160, width: UIScreen.main.bounds.width-40, height: 55)
        }
}

extension TagManageViewController: UITextFieldDelegate {
    // 태그 등록 칸에 글자수 제한(10)
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = tagTextField.text ?? ""
        guard let stringRange = Range(range, in: currentText) else {
            return false }
        let changedText = currentText.replacingCharacters(in: stringRange, with: string)
        return changedText.count <= 10
    }
    
    // 태그 등록 엔터 시
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
            tagTextField.text = ""
        }
        return true
    }
}

extension TagManageViewController: UICollectionViewDelegate {
    // 태그 선택 시
    // 플로팅 버튼 띄우고 컬렉션뷰 bottom 제약조건 추가
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let tag = vm.getTag(indexPath.row)
        toDeleteTagsDict[tag.id] = tag
        self.view.addSubview(self.floatingBtn)
        UIView.animate(withDuration: 0.4) { () -> Void in
            self.floatingBtn.alpha = 1.0
            collectionView.snp.makeConstraints {
                $0.bottom.equalToSuperview().offset(-180)
            }
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        // 태그 선택 해제 시
        toDeleteTagsDict.removeValue(forKey: vm.getTag(indexPath.row).id)
        if toDeleteTagsDict.count == 0 { // 선택된 태그가 0개 일 대
            UIView.animate(withDuration: 0.4) {
                self.floatingBtn.alpha = 0 // 플로팅 버튼 투명하게 하고
                collectionView.snp.removeConstraints() // 추가했던 제약조건 제거
            }
        }
    }
}
