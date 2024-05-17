//
//  HomeViewModel.swift
//  LinkMark
//
//  Created by 김정윤 on 1/18/24.
//

import Foundation
import Combine
import RealmSwift

class HomeViewModel: ObservableObject {
    // Output => Data
    // 모든 URL 목록
    let items: CurrentValueSubject<[UrlList], Never>
    // 사용자가 선택한 URL 아이템
    let selectedItem = PassthroughSubject<UrlList, Never>()
    // 모든 태그 목록
    let tags: CurrentValueSubject<[Tag], Never>
    
    init(items: [UrlList], tags: [Tag]) {
        self.items = CurrentValueSubject(items)
        self.tags = CurrentValueSubject(tags)
    }
    
    var realm: Realm {
        let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.LinkMark.Share")
        let realmURL = container?.appendingPathComponent("share.realm")
        let config = Realm.Configuration(fileURL: realmURL)
        return try! Realm(configuration: config)
    }
    
    /// **홈뷰의 페이지 : 모든 태그와 URL 아이템들 보내기**
    /// - Parameter filterState: saveDate 기준 정렬 상태 (false : 오름차순, true: 내림차순)
    func sendAllItems(filterState: Bool) {
        items.send(Array(realm.objects(UrlList.self).sorted(byKeyPath: "saveDate", ascending: filterState)))
        tags.send(Array(realm.objects(Tag.self)))
    }
    
    /// ** 태그 선택 이후 페이지 : 해당 태그에 맞는 아이템들 반환**
    /// - Parameter tag: 현재 사용자가 선택한 태그 정보
    /// - Returns: 해당 태그를 포함하고 있는 URL 목록
    func getFilteredItems(tag: Tag) -> [UrlList] {
        // 최신순으로 보여주기 
        return Array(realm.objects(UrlList.self).sorted(byKeyPath: "saveDate", ascending: false).filter{$0.tags.contains(tag)})
    }
    
    
    // Input => User Interaction
    // 사용자 input 처리
    /// ** 상세보기
    /// - 사용자가 선택한 URL의 인덱스를 이용해서 해당 아이템 보내기
    /// - Parameter indexPath: 사용자가 선택한 URL의 순번
    func didSelect(at indexPath: IndexPath) {
        let urlItem = items.value[indexPath.item] // 인덱스값으로 받아온 아이템 정의
        selectedItem.send(urlItem) // 선택한 아이템의 정보 뿌려는 publisher에 보내기 => HomeViewController에서 정보 뿌리기
    }
    
    /// **삭제 모드**
    /// - 사용자가 현재 선택한 아이템의 인덱스로 해당 아이템의 아이디 보내주기
    /// - Parameter indexPath: 삭제할 태그의 순번
    /// - Returns: 삭제할 태그의 아이디
    func getIdToDelete(at indexPath: IndexPath) -> UUID {
        let toDeleteItemId = items.value[indexPath.item].id
        return toDeleteItemId
    }
    
    
    /// **UrlList 삭제**
    /// - Parameter dictSelectedIndexPath: 삭제하기 위한 아이템들 [indexPath: UUID]
    ///  - 플로팅 -> 알림창 -> 확인 -> 삭제
    /// 1. 현재 선택되어 있는 아이템들의 인덱스와 아이디를 가져옴
    /// 2. 인덱스를 통해 오름차순 정렬
    /// 3. 오름차순 정렬된 배열을 돌면서 v(= id)에 맞는 데이터 Realm에서 삭제
    func deleteItems(dictSelectedIndexPath: Dictionary<IndexPath, UUID>){
        // 삭제할 아이템 인덱스 오름차순 정렬
        let sortedSelected = dictSelectedIndexPath.sorted { $0.key < $1.key }
        for (_, v) in sortedSelected {
            guard let item = self.realm.object(ofType: UrlList.self, forPrimaryKey: v) else { return }
            try! self.realm.write {
                self.realm.delete(item)
            }
        }
    }
    
    
    /// **현재 선택한 링크의 URL 보내기**
    /// - Parameter indexPath: 현재 선택한 아이템의 순번
    /// - Returns: 현재 선택한 아이템의 URL
    /// 1. 아이템의 인덱스 가져옴
    /// 2. 리스트의 인덱스에 맞는 URL을 반환
    /// 3. HomeViewController에서 해당 URL을 보여줌
    func selectUrl(at indexPath: Int) -> URL {
        let urlString = items.value[indexPath].url
        let encodingUrl = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let url = URL(string: encodingUrl)!
        return url
    }
    
    
    /// **북마크**
    /// - Parameter indexPath: 북마크하고자 하는 아이템이 UrlList 중에서 몇 번째에 있는지
    /// 1. 북마크하고자(풀고자)하는 아이템의 인덱스를 가져옴
    /// 2. 인덱스를 이용해 Realm에서 해당 아이템의 id를 가져옴
    /// 3. Realm내 데이터들 중에서 가져온 id의 북마크 상태 변경
    func bookmarkStateChange(at indexPath: Int) {
        let id = items.value[indexPath].id
        guard let data = realm.object(ofType: UrlList.self, forPrimaryKey: id) else { return }
        try! realm.write { // 북마크 상태 업데이트 false -> true / true -> false
            data.bookmark.toggle()
        }
    }

    /// **태그 선택**
    /// - Parameter indexPath: 현재 선택한 태그의 indexPath
    /// - Returns: 현재 선택한 태그 정보
    func getTag(at indexPath: Int) -> Tag {
        let tag = tags.value[indexPath]
        return tag
    }
}
