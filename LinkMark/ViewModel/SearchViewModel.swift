//
//  SearchViewModel.swift
//  LinkMark
//
//  Created by 김정윤 on 2/17/24.
//

import Foundation
import Combine
import RealmSwift

final class SearchViewModel {
    // Output => Data
    // 키워드로 검색한 검색 결과 URL 목록
    @Published private(set) var searchResults = [UrlList]()
    // 사용자가 선택한 URL 아이템
    let selectedItem = PassthroughSubject<UrlList, Never>()
    
    var realm: Realm {
            let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.LinkMark.Share")
            let realmURL = container?.appendingPathComponent("share.realm")
            let config = Realm.Configuration(fileURL: realmURL)
            return try! Realm(configuration: config)
        }
    
    
    // Input => User Interaction
    /// **검색 결과**
    /// 1. 사용자가 검색하면 제목/url/메모에 해당 키워드가 검색된 결과들을 찾음
    /// 2. 검색결과가 없다면 false를 return
    /// 3. 검색결과가 있다면 searchResult Publisher로 결과들 보내고 true를 return
    /// 4. searchViewController에서 검색결과의 true/false 받아 뷰 그리기
    /// - Parameter keyword: 검색할 키워드
    /// - Returns: 검색 결과 상태 (없으면 false / 있으면 true 반환)
    func searchItems(keyword: String) -> Bool {
        let saveData = Array(realm.objects(UrlList.self))
        let urlFilteredData = Set(saveData.filter { URL(string: $0.url)!.host()!.contains(keyword) })
        let titleOrMemoFilteredData = Set(saveData.filter { $0.title.lowercased().contains(keyword) || $0.title.contains(keyword) ||  $0.memo!.lowercased().contains(keyword) || $0.memo!.contains(keyword) })
        let result = Array(urlFilteredData.union(titleOrMemoFilteredData))
        
        if result.isEmpty {
            print("검색되는게 없어요")
            return false
        }
        searchResults = Array(result)
        return true
    }
    
    /// **사용자가 선택한 아이템의 디테일뷰 열기**
    /// - Parameter indexPath: 현재 사용자가 선택한 URL 아이템의 순번
    func didSelect(at indexPath: IndexPath) {
        let urlItem = searchResults[indexPath.row] // 인덱스값으로 받아온 아이템 정의
        selectedItem.send(urlItem) // 선택한 아이템의 정보를 selectedItem으로 보내기
    }
    
    /// **사파리**
    /// 1. SearchViewController에서 해당 아이템의 safariBtn의 tag값 가져오기
    /// 2. 해당 tag값 이용해서 현재 데이터들(searchResults)에서 해당 index(tag)의 URL 가져오기
    /// 3. URL 반환
    /// - Parameter indexPath: 현재 사용자가 선택한 URL 아이템의 순번
    /// - Returns: 해당 URL 아이템이 가진 URL
    func selectUrl(at indexPath: Int) -> URL {
        let urlString = searchResults[indexPath].url
        let encodingUrl = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let url = URL(string: encodingUrl)!
        return url
    }
    
    /// **북마크**
    /// 1. SearchViewController에서 사용자가 북마크 등록/해제한 아이템의 tag값 가져오기
    /// 2. 해당 tag값을 이용해 아이템의 id값 가져오기
    /// 3. Realm에서 해당 id의 북마크 데이터 toggle로 북마크 등록 또는 해제
    /// 4. SearchViewController에서는 tag번째 section만 다시 불러오기
    /// - Parameter indexPath: 북마크 등록 / 해제할  URL 아이템의 순번
    func bookmarkToggle(at indexPath: Int) {
        let id = searchResults[indexPath].id
        guard let data = realm.object(ofType: UrlList.self, forPrimaryKey: id) else { return }
        try! realm.write { // 북마크 상태 업데이트 false -> true / true -> false
            data.bookmark.toggle()
        }
    }
}
