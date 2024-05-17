//
//  AddViewController.swift
//  LinkMark
//
//  Created by 김정윤 on 1/14/24.
//

import UIKit
import Lottie
import RealmSwift
import Realm
import Combine
import LinkPresentation
import WebKit

class AddUrlViewController:  UIViewController {
    @IBOutlet weak var tagTextField: UITextField!
    @IBOutlet weak var memoView: UIView!
    // 썸네일 이미지 뷰 - 기본은 불러오기, 사진으로 수정도 가능
    @IBOutlet weak var thumbnailImageView: UIImageView!
    // 메모 입력 칸
    @IBOutlet weak var memoTextView: UITextView!
    // 링크 불러오기 버튼
    @IBOutlet weak var loadButton: UIButton!
    // 링크 입력 칸
    @IBOutlet weak var urlTextField: UITextField!
    // 제목 칸
    @IBOutlet weak var titleTextField: UITextField!
    // 메모 칸 입력수
    @IBOutlet weak var textCnt: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    
    typealias Item = Tag
    
    enum Section {
        case main
    }
    
    var datasource: UICollectionViewDiffableDataSource<Section, Item>!
    
    var vm: AddViewModel!
    
    var subscriptions = Set<AnyCancellable>()
    
    let ms = Methods()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        vm = AddViewModel(tags: [])
        vm.sendTags()
        configureCollectionView()
        bind()
    }
    
    /// **태그 컬렉션뷰 구성**
    func configureCollectionView() {
        datasource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView, cellProvider: { collectionView, indexPath, item in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TagCell", for: indexPath) as? TagCell else { return UICollectionViewCell() }
            cell.configure(item, tags: self.vm.selectedTags)
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
    
    /// ** 태그 컬렉션뷰 레이아웃**
    func layout() -> UICollectionViewCompositionalLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(35))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(35))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        
        return UICollectionViewCompositionalLayout(section: section)
    }

    /// **태그 컬렉션뷰에 태그 목록 불러오기 **
    func bind() {
        vm.tags
            .receive(on: RunLoop.main)
            .sink { item in
                var snapshot = self.datasource.snapshot()
                snapshot.deleteItems(item)
                snapshot.appendItems(item, toSection: .main)
                self.datasource.apply(snapshot, animatingDifferences: false)
            }.store(in: &subscriptions)
    }
    
    
    /// **TextField 각 항목별로 다르게**
    /// - Parameters:
    ///   - textField: 텍스트 필드 종류 (태그, 그 외)
    ///   - placeHolder: 텍스트 필드에 삽입할 placeHolder
    private func setupTextField(textField: UITextField, placeHolder: String) {
        textField.autocorrectionType = .no
        textField.spellCheckingType = .no
        textField.placeholder = placeHolder
        switch (textField) {
            case tagTextField:
                textField.delegate = self
            default:
                textField.enablesReturnKeyAutomatically = true
            }
        }
    
    // UI 구성 및 버튼 탭 했을 때
    /// **기본 UI 세팅**
    private func setupUI() {
        // large title 숨기기
        self.navigationItem.largeTitleDisplayMode = .never
        // 네비게이션에 저장 버튼 추가
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "저장", style: .plain, target: self, action: #selector(saveData))
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
        memoTextView.isScrollEnabled = true
        // 링크 불러오기 버튼 세팅
        loadButton.layer.masksToBounds = true
        loadButton.layer.cornerRadius = 10
        // textField들 세팅
        setupTextField(textField: urlTextField, placeHolder: "불러올 URL을 입력하세요")
        setupTextField(textField: titleTextField, placeHolder: "제목을 입력해주세요")
        setupTextField(textField: tagTextField, placeHolder: "태그를 등록해주세요 (10자)")
    }

    /// **URL 데이터 저장**
    @objc func saveData() {
        //print("저장 누름!")
        if urlTextField.text == "" {
            ms.alert(for: "URL을 입력해주세요", vc: self)
        }
        else if loadButton.isEnabled == true {
            ms.alert(for: "URL을 불러와주세요", vc: self)
        }
        else if titleTextField.text == "" {
            ms.alert(for: "제목을 입력해주세요", vc: self)
        } else {
            guard let title = titleTextField.text else { return }
            guard let url = urlTextField.text else { return ms.alert(for: "URL을 입력해주세요", vc: self) }
            guard let image = thumbnailImageView.image else { return }
            guard let imageData: Data = image.jpegData(compressionQuality: 0.9) else { return }
            guard let memo = memoTextView.text else { return }
            vm.saveItem(thumbnailImage: imageData, title: title, url: url, memo: memo)
            navigationController?.popViewController(animated: true)
        }
    }
    
    /// **메타데이터 및 아이콘 불러오기**
    @IBAction func loadBtnTapped(_ sender: Any) {
        if urlTextField.text == "" { // URL칸이 비어있다면 URL을 입력해달라는 팝업
            ms.alert(for: "URL을 입력해주세요", vc: self)
        } else { // URL칸이 비어있지 않다면
            // URL칸의 텍스트를 인코딩하여 URL형태로 변경
            guard let url = URL(string: urlTextField.text!.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!) else { return }
            // 인코딩한 URL이 만약 유효하지 않다면 URL을 확인해달라는 팝업
            if !UIApplication.shared.canOpenURL(url) {
                ms.alert(for: "URL을 확인해주세요", vc: self)
            }
            // 인코딩한 URL이 유효하다면 메타데이터 불러오기
            else {
                let animation = Methods().lottieView(view: self.view, name: "loading")
                Task {
                    animation.isHidden = false
                    animation.play()
                    self.urlTextField.textColor = .systemGray
                    self.urlTextField.isEnabled = false
                    self.loadButton.isEnabled = false
                    
                    // 메타데이터 불러오기
                    do {
                        let metadata = try await LPLoader().load(for: url)
                        self.titleTextField.text = metadata.title
                        
                        // 아이콘 불러오기
                        // 1차적으로 imageProvider 이용해서 썸네일 가져오기
                        // -> 없다면(에러발생 시) iconProvider이용해서 아이콘 가져오기
                        // -> 아이콘도 없다면 썸네일 불러올 수 없다는 팝업 띄우기
                        do {
                            let thumbnail = try await LPLoader().thumbnail(metadata: metadata)
                            self.thumbnailImageView.image = thumbnail
                        } catch {
                            switch error {
                            default:
                                do {
                                    let icon = try await LPLoader().favicon(metadata: metadata)
                                    self.thumbnailImageView.image = icon
                                } catch {
                                    switch error {
                                    case LPLoaderCase.faviconCouldNotBeLoaded:
                                        ms.alert(for: "썸네일을 불러올 수 없어요", vc: self)
                                    case LPLoaderCase.faviconDataInvalid:
                                        ms.alert(for: "불러올 썸네일이 없어요", vc: self)
                                    default:
                                        ms.alert(for: "썸네일을 불러올 수 없어요", vc: self)
                                    }
                                }
                            }
                        }
                    } catch {
                        switch error {
                        case LPLoaderCase.metadataLoadingFailed: ms.alert(for: "데이터를 불러오는데 실패했어요", vc: self)
                        default: break
                        }
                    }
                    animation.stop()
                    animation.isHidden = true
                }
            }
        }
    }
    
    
    /// **태그 삭제**
    /// - Parameter sender: 현재 선택한 태그의 indexPath
    @objc func deleteTag(sender: UIButton) {
        vm.deleteTag(indexPath: sender.tag)
        configureCollectionView()
        bind()
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

extension AddUrlViewController: UICollectionViewDelegate {
    // 태그 선택 / 해제
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        vm.selectOrDeselectTag(indexPath: indexPath)
        configureCollectionView()
        bind()
    }
}

extension AddUrlViewController: UITextViewDelegate {
    // 메모 입력 칸에 글자수 제한(500)
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let currentText = memoTextView.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return false }
        let changedText = currentText.replacingCharacters(in: stringRange, with: text)
        textCnt.text = "(\(changedText.count)/500)"
        return changedText.count <= 499
    }
}


extension AddUrlViewController: UITextFieldDelegate {
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
            // 최근 등록순으로 보여주기
            vm.sendTags()
            tagTextField.text = ""
        }
        return true
    }
}

/// **현재 응답받는 UI를 알아내기 위해 사용(textfield, textview 등)**
extension UIResponder {
    private struct Static {
        static weak var responder: UIResponder?
    }
    static var currentResponder: UIResponder? {
        Static.responder = nil
        UIApplication.shared.sendAction(#selector(UIResponder._trap), to: nil, from: nil, for: nil)
        return Static.responder
    }
    @objc private func _trap() {
        Static.responder = self
    }
}
