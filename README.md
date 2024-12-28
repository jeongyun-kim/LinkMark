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
<tr>
  <td>메인</td>
  <td>검색</td>
  <td>태그 관리</td>
  <td>공유하기</td>
</tr>
<tr line-height:0>
  <td><img src="" width="120" height="250"></td>
  <td><img src="" width="120" height="250"></td>
  <td><img src="" width="120" height="250"></td>
  <td><img src="" width="120" height="250"></td>
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
- 링크 제목, 썸네일을 위한 LinkPresentation 활용
- 사용자의 이벤트 처리를 위해 Combine 활용 
- 링크 불러오는동안 Lottie를 활용한 로딩 이미지 표출
- 사용성 향상을 위한 필수값(링크, 제목)에 대한 검증 및 명확한 표기
- 토스트 메시지를 이용한 피드백
- 링크 저장, 삭제 실시간 반영
- 메모 글자수 제한 
- 태그, 링크 목록의 레이아웃을 위한 Compositional CollectionView + Diffable DataSource 활용 

---

### 🚨 트러블슈팅

**✓ 향상된 사용자 경험을 위한 데이터 실시간 반영 중 FSCalendar의 Cell이 실시간 업데이트 되지않는 문제**

**- 문제점**
<br>
SwiftUI의 경우 뷰에서 무언가 변화가 생겼을 때, 뷰를 새로 렌더링 하는 방식을 가지고 있습니다. 하지만 사용자의 기록 현황을 확인할 수 있는 CalendarView의 경우 UIViewController를 감싸고 있는 형태로, 기록이 생성되거나 삭제되더라도 `updateUIVIewController()`에 별도의 코드를 작성해 주지 않아 변경사항이 반영되지 않는 문제가 발생하였습니다.

**- 해결**
<br>
이러한 문제를 해결하기 위해 `updateUIVIewController()`의 호출 시점마다 Calendar를 갱신해 주도록 처리하였습니다. 하지만 이는 예상보다도 많은 호출이 일어나 불필요한 애니메이션이 보여짐과 동시에 동기화가 불필요한 시점에도 갱신이 일어나며 쓸데없는 자원이 낭비되는 또 다른 문제가 발생하였습니다. 
<br>
그리하여 데이터가 변경되거나 삭제되었을 때에만 Reload 하도록 UIViewControllerRepresentable 내에 @Binding 값을 정의해 주어 캘린더를 업데이트해줘야 하는 시점을 Bool 값으로 구분해 주고자 하였습니다. 그리고 현재 값이 true 라면 Reload 해주고, 바로 다음에 불필요한 갱신이 일어나지않도록 값을 변경해 주는 과정을 거쳤습니다. 이를 통해 필요한 시점에만 변경사항을 반영해 줄 수 있었습니다. 

```swift
struct FSCalendarViewControllerWrapper: UIViewControllerRepresentable {
    @ObservedObject var vm: CalendarViewModel
    @Binding var detent: PresentationDetent
    @Binding var reloadCalendar: Bool

    func makeUIViewController(context: Context) -> some UIViewController {
        FSCalendarViewController(vm: vm)
    }
    
    // - BottomSheet 높이 변할 때마다 달력의 형태도 변경
    // - 상세뷰에서 편집 후 이미지 변경 시, 바로 썸네일 반영되도록 calendar.reloadData()
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        guard let vc = uiViewController as? FSCalendarViewController else { return }
        // Calendar 갱신 여부 보내기 
        vc.reloadCalendar(reloadCalendar) 
	      ... 
    }
    
    class FSCalendarViewController: UIViewController, FSCalendarDelegate, FSCalendarDataSource {
        init(vm: CalendarViewModel) {
        ...
		    // Calendar Reload 갱신해야한다면 Reload -> Trigger false 처리  
		    func reloadCalendar(_ reload: Bool) {
		            DispatchQueue.main.async {
		                if reload {
		                    self.calendar.reloadData()
		                    self.vm.action(.reloadCalendarTrigger(reload: false))
		                }
		            }
		      }
}
```
<br>

**✓ FullScreenCover로 감싸진 View로의 데이터 전달** 

**- 문제점**
<br>
특정 기록을 선택하였을 때, FullScreenCover로 설정된 뷰가 present되며 해당 기록의 상세정보를 확인할 수 있어야하는 상황에서 어떤 기록을 선택하든 보여지고 있는 기록들 중 첫번째 기록에 대한 상세정보만이 표출되는 문제가 발생하였습니다.
<br>

**- 해결**
<br>
원인을 찾기 위해 우선 데이터 전달이 제대로 일어나는지 확인해보았습니다. 그리고 `onTapGesutre()`에서 전달 데이터를 출력해본 결과, 선택한 기록의 데이터가 출력되었고 FullScreenCover 내 DetailView는 해당 데이터가 아닌 첫번째 기록의 데이터를 전달받고 있음을 알 수 있었습니다. 즉, 탭을 했을 때 제대로 된 데이터가 선택되고 있지만 FullCoverScreen 내 뷰가 가지는 데이터는 변화하지않고 첫번째 데이터로 고정되어 생기는 문제라고 판단하게 되었습니다.
<br>
그리하여 selectedLog라는 State 변수를 두어 기록을 선택할 때마다 DetailView로 전달해줄 기록으로 변경하고 이를 DetailView로 전달하도록 수정하였습니다. 

```swift
struct BottomSheetView: View {
    @ObservedObject var vm: CalendarViewModel
    @State private var isPresentingFullCover = false
    @State private var selectedLog: Log = Log(title: "", content: "", place: nil, visitDate: Date())
    
    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                LazyVStack(spacing: 30) {
                    ForEach(vm.output.logList, id: \.id) { item in
                        rowView(proxy.size.width, item: item)
                            .onTapGesture {
                                selectedLog = item
                                isPresentingFullCover.toggle()
                            }
                    }
                }
                .padding(.horizontal)
            }
        }
        .fullScreenCover(isPresented: $isPresentingFullCover, content: {
            LazyNavigationView(DetailView(log: $selectedLog))
        })
        .padding(.top, 32)
        .background(Resources.Colors.lightOrange)
    }
}
```
<br>

**✓ Filemanager 내 이미지 저장을 위한 UIImage 활용**

**- 문제점**
<br>
UIKit에서는 UIImage → Data 를 통해 Filemanager에 이미지를 저장할 수 있었지만 SwiftUI에서는 Image를 FileManager로 저장하는 방법을 찾지 못하였습니다. 
그리하여 Image → UIImage 방식으로 이미지를 변환한 후, 저장 시 해당 UIImage를 활용하려고 하였으나 본래 이미지의 크기가 아닌 임의로 설정해준 크기로만 이미지를 변환할 수 있다는 또다른 문제가 있었습니다.

```swift
extension Image {
    func asUIImage() -> UIImage? {
        // SwiftUI View를 UIKit의 UIView로 변환할 뷰
        let controller = UIHostingController(rootView: self)

        // 뷰의 크기 설정 
        let size = controller.sizeThatFits(in: .init(width: 300, height: 300)) // 원하는 크기로 조정
        controller.view.frame = CGRect(origin: .zero, size: size)

        // 뷰의 레이어가 그려지게 
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        // 화면 업데이트 후 그려주기
        controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        let uiImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return uiImage
    }
}
```
<br>

**- 해결**
<br>
그리하여 PhotosPicker로 선택한 이미지가 변경될 때마다 PhotosPickerItem을 Data로 1차 변환하고 이를 UIImage로 2차 변환해주는 과정을 거쳐 각 이미지의 크기에 맞는 UIImage를 가져올 수 있었습니다.

그리고 뷰에서는 해당 UIImage를 사용하여 보여준 후, 사용자가 기록을 저장할 때에 그 UIImage를 활용해 이전과 같은 방식으로 Filemanager 내 이미지를 저장해줄 수 있었습니다.

```swift
// ImageOnChangeWrapper.swift
// - pickerItem: 받아온 이미지 
// - completionHandler: 변환 후 이미지 실어보내기
private func getUIImage(_ pickerItem: PhotosPickerItem?, completionHandler: @escaping (UIImage) -> Void) {
	guard let pickerItem else { return }
	Task {
	// 1차 변환: PhotosPickerItem => Data
		if let imageData = try? await pickerItem.loadTransferable(type: Data.self) {
		  // 2차 변환: Data => UIImage
	    if let image = UIImage(data: imageData) {
		    // Main으로 UIImage 보내기 
         DispatchQueue.main.async {
            completionHandler(image)
		     }
	     }
   }
	   else {
       print("Failed Get UIImage")
     }
	}
}
```

---

### 👏 회고

**- 사용자 편의성 개선**
<br>
사용자의 편의성을 더욱 생각하려고 노력하였던 앱이라고 생각합니다. 그리하여 출시 전후로 받은 동료분들의 피드백을 바탕으로 1차 업데이트를 진행하기도 하였습니다.  개발자이기는 하지만 언제나 사용자의 관점에서 바라보도록 더욱 노력해야할 것 같습니다. 이후에는 태그를 통한 기록 모아보기, 다크모드 대응 등 다양한 기능을 추가함으로써 앱의 활용성을 높이고 싶습니다.
<br>

