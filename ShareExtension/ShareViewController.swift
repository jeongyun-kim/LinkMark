//
//  ShareViewController.swift
//  ShareExtension
//
//  Created by 김정윤 on 3/2/24.
//

import UIKit
import Social
import LinkPresentation
import RealmSwift
import MobileCoreServices
import UniformTypeIdentifiers
import Lottie
import Toast
import Realm
import Combine

class ShareViewController: UIViewController {
    @IBOutlet weak var tagTextField: UITextField!
    @IBOutlet weak var memoTextCnt: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var memoView: UIView!
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var loadBtn: UIButton!
    @IBOutlet weak var memoTextView: UITextView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var urlTextField: UITextField!
    
    let ms = Methods()
    
    var state: Bool = false
    
    var vm: ShareViewModel!
    
    var subscriptions = Set<AnyCancellable>()
    
    enum Section {
        case main
    }
    
    typealias Item = Tag
    
    var datasource: UICollectionViewDiffableDataSource<Section, Item>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        vm = ShareViewModel(tags: [])
        vm.sendTags()
        setupUI()
        setupNavigation()
        getUrl()
        configureCollectionView()
        bind()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if urlTextField.text == "" {
            let alert = ms.alertSetTitle(title: "URL을 불러오지 못했어요", message: "URL을 복사해 앱에서 추가해주세요🙏")
            // 확인 누르면 아이디가 들어있는 배열돌면서 해당 아이디의 아이템들 삭제
            let confirmAction = UIAlertAction(title: "확인", style: .default, handler: { [unowned self] _ in
                self.extensionContextDismiss()
            })
            // 액션 폰트 컬러 변경
            confirmAction.setValue(UIColor(hue: 0.7194, saturation: 0.41, brightness: 1, alpha: 1.0), forKey: "titleTextColor")
            // 액션 추가
            alert.addAction(confirmAction)
            // 알림창 띄우기
            present(alert, animated: true)
        }
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
        
        var snapshot = datasource.snapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems([], toSection: .main)
        datasource.apply(snapshot, animatingDifferences: false)
        
        collectionView.allowsMultipleSelection = true
        collectionView.delegate = self
        collectionView.collectionViewLayout = layout()
    }
    
    /// **태그 컬렉션뷰 레이아웃**
    func layout() -> UICollectionViewCompositionalLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(35))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(35))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        
        return UICollectionViewCompositionalLayout(section: section)
    }
    
    /// **컬렉션뷰 내 태그 데이터 보여주기**
    private func bind() {
        vm.tags
            .receive(on: RunLoop.main)
            .sink { [unowned self] tags in
                var snapshot = self.datasource.snapshot()
                snapshot.deleteItems(tags)
                snapshot.appendItems(tags, toSection: .main)
                self.datasource.apply(snapshot, animatingDifferences: false)
            }.store(in: &subscriptions)
    }
    
    /// **현재 웹 페이지의 URL을 Extension Context에서 가져오고 UI 변화주기**
    func getUrl() {
        let extensionItems = extensionContext?.inputItems as! [NSExtensionItem]
        for extensionItem in extensionItems {
            if let itemProviders = extensionItem.attachments {
                for itemProvider in itemProviders {
                    if itemProvider.hasItemConformingToTypeIdentifier(UTType.url.identifier as String) {
                        itemProvider.loadItem(forTypeIdentifier: UTType.url.identifier as String, options: nil) { url, error in
                            if let shareUrl = url as? URL {
                                let url = shareUrl.absoluteString // 현재 웹 페이지의 String 형식
                                DispatchQueue.main.async { [unowned self] in
                                    self.urlTextField.text = url // URL칸에 현재 웹 페이지 주소 넣어주기
                                    self.urlTextField.tintColor = .systemGray // URL 글씨 회색으로
                                    self.urlTextField.isEnabled = false // URL 수정 불가
                                    self.urlTextField.textColor = .systemGray
                                    self.loadBtn.isEnabled = false // 링크 데이터 불러오기 불가
                                    let encodingUrlString = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
                                    let encodingUrl = URL(string: encodingUrlString)!// 문자열을 url 형태로 변환
                                    loadItems(url: encodingUrl)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    
    
    /// **URL통해서 썸네일, 제목 가져오기**
    /// - Parameter url: 현재 사용자가 공유하기 한 웹페이지의 주소
    private func loadItems(url: URL) {
        state = true
        // url 입력칸이 비어있지 않다면
        if urlTextField.text != "" {
            // 로딩 애니메이션 만들기
            let animation = ms.lottieView(view: self.view, name: "loading") // 애니메이션 정의
            Task {
                animation.isHidden = false // 로딩 애니메이션 보이도록
                animation.play() // 로딩 애니메이션 플레이
                self.urlTextField.textColor = .systemGray
                // 메타데이터 불러오기 시도 -> 타이틀 넣기
                do {
                    let metadata = try await LPLoader().load(for: url) // LPLoader 이용해서 메타데이터 불러오기
                    self.titleTextField.text = metadata.title
                    
                    // 아이콘 불러오기 -> 썸네일 넣기
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
                                    ms.toastMessage(message: "썸네일을 불러올 수 없어요", view: self.view)
                                case LPLoaderCase.faviconDataInvalid: 
                                    ms.toastMessage(message: "불러올 썸네일이 없어요", view: self.view)
                                default:
                                    ms.toastMessage(message: "썸네일을 불러올 수 없어요", view: self.view)
                                }
                            }
                        }
                    }
                } catch { // 데이터를 가져오는데 에러가 발생한다면
                    switch error {
                    default: ms.toastMessage(message: "데이터를 불러올 수 없어요", view: self.view)
                    }
                }
                
                // 로딩 멈추고 화면 안 보이게
                animation.stop()
                animation.isHidden = true
            }
        }
    }
    
    // 기본 UI 구성 및 버튼 탭 했을 때
    /// **기본 UI 구성**
    private func setupUI() {
        // 썸네일 코너 깎기
        thumbnailImageView.image = UIImage(named: "url_default_img")
        thumbnailImageView.layer.masksToBounds = true
        thumbnailImageView.layer.cornerRadius = 12
        // 메모 적는 칸 세팅
        memoView.layer.borderWidth = 0.5
        memoView.layer.borderColor = UIColor.lightGray.cgColor
        memoView.layer.cornerRadius = 6
        // TextView delegate 설정 <- 글자수 제한
        memoTextView.delegate = self
        // 메모 적는 칸에 수 제안 제거
        memoTextView.autocorrectionType = .no
        memoTextView.spellCheckingType = .no
        // 링크 불러오기 버튼 세팅
        loadBtn.layer.masksToBounds = true
        loadBtn.layer.cornerRadius = 10
        // 제목 입력칸에 placehorder
        configureTextField(textField: titleTextField, placeHolder: "제목을 입력해주세요")
        configureTextField(textField: tagTextField, placeHolder: "태그를 등록해주세요 (10자)")
        configureTextField(textField: urlTextField, placeHolder: "URL을 입력해주세요")
    }
    
    // **네비게이션 UI 구성**
    func setupNavigation() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "저장", style: .plain, target: self, action: #selector(saveData))
        navigationItem.rightBarButtonItem?.tintColor = .black
        navigationItem.title = "URL 추가"
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "취소", style: .plain, target: self, action: #selector(extensionContextDismiss))
        navigationItem.leftBarButtonItem?.tintColor = .lightGray
    }
    
    /// **각 텍스트 필드 구성**
    private func configureTextField(textField: UITextField, placeHolder: String) {
        textField.autocorrectionType = .no
        textField.spellCheckingType = .no
        textField.placeholder = placeHolder
        switch (textField) {
            case tagTextField:
                textField.delegate = self
            default: return
            }
    }
    
    /// **URL 데이터 저장**
    @objc func saveData() {
        if titleTextField.text != "" { // 제목이 비어있지 않다면
            guard let url = urlTextField.text else { return }
            guard let title = titleTextField.text else { return }
            guard let thumbnail = thumbnailImageView.image else { return }
            guard let imageData: Data = thumbnail.jpegData(compressionQuality: 0.9) else { return } // 썸네일 이미지 Data 형태로 변환
            guard let memo = memoTextView.text else { return }
            vm.saveData(url: url, title: title, thumbnailImage: imageData, memo: memo)
            // 창 내려가게
            ms.toastMessage(message: "저장완료!", view: self.view)
            // 토스트메시지 출력 후 0.7초 뒤에 내려감
            DispatchQueue.main.asyncAfter(deadline: .now()+0.7) {
                self.extensionContextDismiss()
            }
        } else if urlTextField.text == "" {
            ms.toastMessage(message: "URL을 입력해주세요", view: self.view)
        } else { // 제목 없을 때 제목을 입력해달라는 토스트 메시지 출력
            ms.toastMessage(message: "제목을 입력해주세요", view: self.view)
        }
    }
    
    
    /// **태그 삭제**
    /// - Parameter sender: 현재 사용자가 선택한 태그의 indexPath
    @objc func deleteTag(sender: UIButton) {
        vm.deleteTag(at: sender.tag)
        vm.sendTags()
        configureCollectionView()
        bind()
    }
    
    /// **현재 창 닫기**
    @objc func extensionContextDismiss() {
        self.extensionContext?.completeRequest(returningItems: nil)
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

// 메모 입력 칸에 placehorder 추가 및 글자수 제한
extension ShareViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let currentText = memoTextView.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return false }
        let changedText = currentText.replacingCharacters(in: stringRange, with: text)
        memoTextCnt.text = "(\(changedText.count)/500)"
        return changedText.count <= 499
    }
}

extension ShareViewController: UITextFieldDelegate {
    // 태그 글자수 제한 (10자)
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = tagTextField.text ?? ""
        guard let stringRange = Range(range, in: currentText) else {
            return false }
        let changedText = currentText.replacingCharacters(in: stringRange, with: string)
        return changedText.count <= 10
    }
    // 태그 등록 시
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let addedTagNames = vm.getAddedTagNames()
        guard let tagName = tagTextField.text else { return false }
        if addedTagNames.contains(tagName) { // 동일한 태그명이 이미 존재할 때
            ms.toastMessage(message: "이미 동일한 이름의 태그가 있어요", view: self.view)
        } else if addedTagNames.count >= 15 { // 이미 태그가 15개 이상 등록되어 있을 때
            ms.toastMessage(message: "태그는 15개까지만 저장할 수 있어요", view: self.view)
        } else if tagName == "" { // 태그명이 없을 때
            ms.toastMessage(message: "태그명을 입력해주세요", view: self.view)
        } else {
            vm.saveTag(tagName: tagName)
            vm.sendTags()
            tagTextField.text = ""
        }
        return true
    }
}

// 태그 선택/해제 시
extension ShareViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        vm.selectOrDeselectTag(indexPath: indexPath)
        configureCollectionView()
        bind()
    }
}
