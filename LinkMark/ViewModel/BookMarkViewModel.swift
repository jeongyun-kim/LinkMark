//
//  BookMarkViewModel.swift
//  LinkMark
//
//  Created by 김정윤 on 2/5/24.
//

import Foundation
import Combine
import RealmSwift

final class BookMarkViewModel: ObservableObject {
    // Output => Data
    // 모든 URL 목록
    let items: CurrentValueSubject<[UrlList], Never>
    // 사용자가 선택한 URL 아이템
    let selectedItem = PassthroughSubject<UrlList, Never>()
    
    var realm: Realm {
            let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.LinkMark.Share")
            let realmURL = container?.appendingPathComponent("share.realm")
            let config = Realm.Configuration(fileURL: realmURL)
            return try! Realm(configuration: config)
        }
    
    // 데이터베이스에서 가져온 데이터들
    init(items: [UrlList]) {
        self.items = CurrentValueSubject(items)
    }
    
    /// **현재 즐겨찾기 중인  URL 데이터들 보내기**
    func sendItems() {
        // 최신순으로 
        let saveData = Array(realm.objects(UrlList.self).sorted(byKeyPath: "saveDate", ascending: false)).filter{ $0.bookmark == true }
        items.send(saveData)
    }
    
    // Input => User Interaction
    /// **상세보기 :  인덱스를 통해 사용자가 선택한 아이템의 데이터 보내기**
    /// - Parameter indexPath: 현재 사용자가 선택한 URL 아이템의 순번
    func didSelect(at indexPath: IndexPath) {
        let urlItem = items.value[indexPath.item]
        selectedItem.send(urlItem)
    }
    
    /// **사용자가 선택한 아이템의 URL 반환**
    /// - Parameter indexPath: 현재 사용자가 선택한 URL 아이템의 순번
    /// - Returns: 해당 아이템의 URL 값
    func selectUrl(at indexPath: Int) -> URL {
        let urlString = items.value[indexPath].url
        let encodingUrl = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let url = URL(string: encodingUrl)!
        return url
    }
    
    /// **북마크 상태 변화**
    /// - Parameter indexPath: 북마크 등록/해제 할 URL 아이템의 순번 
    func bookmarkStateChange(at indexPath: Int) {
        let id = items.value[indexPath].id
        guard let data = realm.object(ofType: UrlList.self, forPrimaryKey: id) else { return }
        try! realm.write { // 북마크 상태 업데이트 false -> true / true -> false
            data.bookmark.toggle()
        }
    }
}
