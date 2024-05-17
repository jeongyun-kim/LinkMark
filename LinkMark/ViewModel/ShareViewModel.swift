//
//  ShareViewModel.swift
//  ShareExtension
//
//  Created by 김정윤 on 4/2/24.
//

import Foundation
import Combine
import RealmSwift

class ShareViewModel: ObservableObject {
    // Output => Data
    init(tags: [Tag]) {
        self.tags = CurrentValueSubject(tags)
    }
    
    var realm: Realm {
        let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.LinkMark.Share")
        let realmURL = container?.appendingPathComponent("share.realm")
        let config = Realm.Configuration(fileURL: realmURL)
        return try! Realm(configuration: config)
    }
    
    // 모든 태그 목록
    var tags: CurrentValueSubject<[Tag], Never>
    // 현재 선택되어 있는 태그 List
    @Published var selectedTags: List<Tag> = List<Tag>()
    // 선택되어있는 태그 Dict(태그의 인덱스 : 태그 데이터)
    var selectedTagsDict:[UUID:Tag] = [:]
    
    
    /// **모든 태그 목록 전송**
    func sendTags() {
        tags.send(Array(realm.objects(Tag.self)).reversed())
    }
    
    /// **선택 중인 태그 딕셔너리 -> 리스트**
    /// - Parameter selectedTagsDict: 현재 선택 중인 태그 목록(딕셔너리)
    /// - Returns: 현재 선택 중인 태그 목록(리스트)
    func selectedTagsDictToList(from selectedTagsDict: [UUID: Tag]) -> List<Tag> {
        let selectedTagsList: List<Tag> = List<Tag>()
        // 태그를 저장한 날짜 기준으로 오래된 순 -> 최신순
        let sortedSelectedTagsArray = selectedTagsDict.sorted { $0.value.saveDate < $1.value.saveDate }.map{$0.value}
        for tag in sortedSelectedTagsArray{
            selectedTagsList.append(tag)
        }
        return selectedTagsList
    }
    
    // Input => User Interaction
    /// **태그 삭제**
    /// - Parameter indexPath: 현재 선택한 태그의 순번
    func deleteTag(at indexPath: Int) {
        let tag = Array(realm.objects(Tag.self)).reversed()[indexPath]
        if selectedTagsDict.values.contains(tag) {
            selectedTagsDict.removeValue(forKey: tag.id)
        }
        guard let toDeleteTag = realm.object(ofType: Tag.self, forPrimaryKey: tag.id) else { return }
        try! realm.write {
            realm.delete(toDeleteTag)
        }
        selectedTags = selectedTagsDictToList(from: selectedTagsDict)
    }
    
    /// **태그 저장(등록)**
    /// - Parameter tagName: 등록할 태그명
    func saveTag(tagName: String) {
        let tag = Tag(tagName: tagName, saveDate: Methods().calcDate(from: Date()))
        try! realm.write {
            realm.add(tag)
        }
    }
    
    /// **이미 등록되어있는 태그명 목록 반환**
    /// - Returns: 현재 등록되어 있는 태그명들
    func getAddedTagNames() -> [String] {
        return tags.value.map{$0.tagName}
    }
    
    /// **URL 데이터 저장**
    /// - Parameters:
    ///   - url: 링크 주소
    ///   - title: 해당 링크 제목
    ///   - thumbnailImage: 썸네일 이미지 데이터
    ///   - memo: 메모
    func saveData(url: String, title: String, thumbnailImage: Data, memo: String) {
        let nowDate = Methods().calcDate(from: Date())
        var tagNames = ""
        for tag in selectedTags {
            tagNames += "#\(tag.tagName)   "
        }
        let urlData = UrlList(image: thumbnailImage, title: title, url: url, memo: memo, saveDate: nowDate, tags: selectedTags)
        try! realm.write {
            realm.add(urlData)
        }
    }
    
    /// **선택한 태그 반환**
    /// - Parameter indexPath: 현재 사용자가 선택한 태그의 순번
    /// - Returns: 현재 사용자가 선택한 태그 정보
    func getTag(at indexPath: IndexPath) -> Tag {
        return Array(realm.objects(Tag.self)).reversed()[indexPath.row]
    }
    
    /// **태그 선택/해제할 때마다 호출**
    /// - Parameter indexPath: 현재 선택/해제한 태그의 순번
    /// 1. 현재 선택/해제한 태그 정보 불러오기
    /// 2. 만약 현재 선택 중인 태그 목록(딕셔너리)에 해당 태그가 있다면 선택 해제
    /// 3. 만약 현재 선택 중인 태그 목록(딕셔너리)의 길이가 4 이하이고 현재 선택한 태그가 포함되지 않는다면 딕셔너리에 추가
    /// 4. 현재 선택 중인 태그 목록 딕셔너리에서 리스트로 변환
    func selectOrDeselectTag(indexPath: IndexPath) {
        let tag = getTag(at: indexPath)
        if selectedTagsDict.values.contains(tag) {
            selectedTagsDict.removeValue(forKey: tag.id)
        } else if selectedTagsDict.count <= 4 {
            selectedTagsDict[tag.id] = tag
        }
        selectedTags = selectedTagsDictToList(from: selectedTagsDict)
    }
    
}
