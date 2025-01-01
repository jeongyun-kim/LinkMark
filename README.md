# 링마크 - 링크 모음 앱 
<a href="https://apps.apple.com/kr/app/%EB%A7%81%EB%A7%88%ED%81%AC/id6499511244">
	<img src="https://github.com/user-attachments/assets/dd8e6470-7966-49e3-ad87-0de5726221f8" width="120"/>
</a>

### ✏️ 개발 의도

인스타그램, 사파리, X 등 다양한 플랫폼에서 우리는 북마크를 이용하고 있습니다.
<br>
하지만 이러한 북마크들은 각 사이트 또는 앱에서 확인할 수 있기 때문에 한곳에서 빠르게 조회하고 관리할 수 없다는 불편함이 존재합니다.
<br>
이러한 불편함을 해결해보고자 한곳에서 저장해두고 싶은 링크들을 관리하는 앱을 개발하게 되었습니다.

---

### ⭐️ 스크린샷

<table>
<tr line-height:0>
  <td><img src="https://github.com/user-attachments/assets/0d74dc1a-c296-4484-b007-ce38c7df48b8" width="150" height="280"></td>
  <td><img src="https://github.com/user-attachments/assets/6eea3d4d-7031-43a1-bad6-96f19eecb263" width="150" height="280"></td>
  <td><img src="https://github.com/user-attachments/assets/c77fcc59-949c-4bcf-abbc-1bb5f558e755" width="150" height="280"></td>
  <td><img src="https://github.com/user-attachments/assets/626d4ca6-d114-42a5-ae38-c94b9223ff86" width="150" height="280"></td>
</tr>
</table>

---

### ✅ 개발환경

- iOS16+
- 1인 개발 | 2024.01.10 ~ 04.30

---

### 👩🏼‍💻 주요 기술

- UI : UIKit, Storyboard, SnapKit, Kingfisher, Lottie, Toast
- Database : Realm
- Reactive : Combine
- Design Pattern: MVVM
- etc: Link Presentation, Share Extension, Swift Concurrency, GCD

---

### 📚 주요 기능

- 공유하기를 통한 링크 저장
- 링크에 대한 메모 기록
- 저장한 링크 검색
- 태그를 통한 링크 분류
- 태그 관리
- 건의하기 

---

### 🧐 개발 포인트

- 타깃(App, Share Extension) 간 Realm 데이터 공유를 위한 App Group 활용
- CompletionHandler 기반 코드 Continuation 활용해 Concurrency 환경으로 변경
- 공유하기를 위한 Share Extension 활용
- 링크 제목, 썸네일을 위한 LinkPresentation 활용
- 사용자의 이벤트 처리를 위해 Combine 활용 
- 링크 불러오는동안 Lottie를 활용한 로딩 이미지 표출
- 사용성 향상을 위한 필수값(링크, 제목)에 대한 검증 및 명확한 표기
- 토스트 메시지를 이용한 이벤트 결과 피드백
- 링크 저장, 삭제 등 실시간 반영
- 태그, 링크 목록의 레이아웃을 위한 Compositional CollectionView + Diffable DataSource 활용 

---

### 🚨 트러블슈팅

**✓ 링크 썸네일을 받아오기 위한 메서드를 continuation을 활용해 GCD -> Concurrency 환경으로 변경**

**- 문제점**
<br>
imageProvider 또는 iconProvider에서 특정 데이터 타입의 데이터를 가져오는 메서드인 loadDataRepresentation은 completionHandler로 결과값을 반환하는 함수였습니다. 하지만 받아오는 데이터를 받아와 UIImage로 변경해주는 추가적인 단계가 있어 이를 순차적으로 처리하기 위해서는 Swift Concurrency 환경의 async-await을 활용해야했습니다.

**- 해결**
<br>
그리하여 completionHandler를 continuation을 이용해 Concucrrency 환경으로 변경하고자 결과값과 에러를 모두 반환할 수 있는 withCheckedThrowingContinuation를 활용해주었습니다.

```swift
extension NSItemProvider {
    func loadDataRepresentation(for type: UTType) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            _ = self.loadDataRepresentation(for: type) { data, error in
                if let data {
                    // 불러온 데이터 return 
                    continuation.resume(returning: data)
                } else if let error {
                    // 에러 던지기
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
```

**✓ Extension Context 내 URL 가져와 앱에 반영하기**

**- 문제점**
<br>
공유하기를 통해 해당 웹페이지의 URL을 앱으로 가져온 직후, URL의 메타데이터를 가져오도록 구현해주고 싶었습니다.

**- 해결**
<br>
공유하기 시 떠오르는 화면이 Extension Context라는 것을 알게되었고 내부의 아이템들을 돌면서 URL을 찾고 가져와 앱에 반영해주면 되는 무제였습니다. 이 때, itemProvider의 경우 비동기적으로 작동하기 때문에 URL을 가져와 UI변화를 줄 때에 DispatchQueue.main.async를 이용해 UI 업데이트가 이루어지도록 처리하였습니다.

```swift
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
```

**✓ 링크 썸네일이 image 또는 icon이기에 생기는 예외처리**

**- 문제점**
<br>
처음에는 링크의 썸네일은 당연히 imageProvider로 불러올 수 있을거라고 생각했습니다. 하지만 어떠한 링크들의 경우, imageProvider가 아닌 iconProvider로 불러와야하는 경우들이 있었습니다.

**- 해결**
<br>
이를 고려하여 썸네일을 받아오는 단계를 단순히 imageProvider를 이용하는 것이 아닌 1차는 image, 2차는 icon 형식으로 변경해주었습니다.
<br>
그리하여 1차적으로 메타데이터에 썸네일이 image 형태로 존재한다면 해당 단계에서 썸네일을 반영해주었고, 이 때에 썸네일이 없는 모든 경우를 에러로 분류하여 icon 형태로 받아오는 단계를 거치도록 하였습니다.
최종적으로 iconProvider로도 썸네일을 받아오지못한다면 기본 이미지가 사용되도록 하였습니다. 

```swift
do {
  let thumbnail = try await LPLoader().thumbnail(metadata: metadata)
  self.thumbnailImageView.image = thumbnail
} catch {
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
```
<br>

**✓ URL 인코딩** 

**- 문제점**
<br>
URL을 입력 후 유효성 검증을 거치는 과정에서 "abc"같은 문자는 괜찮지만 "ㅇㄹㅁㄴ"같은 한글을 입력했을 때, 런타임 에러가 발생하였습니다.
<br>

**- 해결**
<br>
한글을 URL로 변환할 때 생기는 문제라고 생각하여 관련 코드에 print를 통해 디버깅을 진행하였고, 한글 또는 공백만이 포함된 경우 URL의 변환값이 nil로 반환됨을 알 수 있었습니다.
<br>
그리하여 PercentEncoding을 통해 Label의 텍스트를 인코딩하여 URL로 변환할 수 있도록 처리해주었습니다.
한글과 영어의 인코딩에 대해 고려하지않아 생긴 문제로 간단하지만 이러한 사소한 것까지 신경써야한다는 점에서 인상깊었던 문제입니다.

```swift
guard let url = URL(string: urlTextField.text!.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!) else { return }
```
<br>

---


### 👏 회고

**- 강제 언래핑 제거**
<br>
처음 만들어보는 앱인만큼 종종 강제 언래핑을 행하는 코드를 찾아볼 수 있습니다. 이는 런타임 에러를 일으킬 수 있는 문제 중 하나이기 때문에 다음 번에는 이러한 부분들을 고려하여 개발해야할 것 같습니다.
<br>

**- async/await에 대한 이해**
<br>
async/await 환경에 대해 제대로 알지못하고 시작한 개발이었지만 Task, continuation 등을 접하였고 개발을 하는 도중에도 비동기에 대해 고민해볼 수 있었습니다. 이후에는 GCD와 Swift Concurrency 간의 차이점과 특징 등을 공부하여 보다 명확하게 이해하고 싶습니다. 
<br>

**- 전체적인 코드 퀄리티 및 출시기간에 대한 아쉬움**
<br>
혼자 공부하며 앱을 만들었기때문에 제가 생각했던 것보다 전반적으로 오래 걸렸고 코드가 과하게 길어지는 경향이 있었던 것 같습니다.
다음에는 이러한 점을 보완하여 코드의 가독성을 향상시키고 다양한 문제상황을 고려하여 일정을 계획하고 싶습니다. 

