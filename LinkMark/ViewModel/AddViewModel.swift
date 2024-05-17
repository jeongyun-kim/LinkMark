//
//  AddViewModel.swift
//  LinkMark
//
//  Created by 김정윤 on 3/25/24.
//

import Foundation
import Combine
import RealmSwift

final class AddViewModel: ObservableObject {
    // Output => Data
    var realm: Realm {
            let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.LinkMark.Share")
            let realmURL = container?.appendingPathComponent("share.realm")
        let config = Realm.Configuration(fileURL: realmURL)
            return try! Realm(configuration: config)
        }
    
    // 모든 태그 목록
    var tags: CurrentValueSubject<[Tag], Never>
    // Realm에 저장할 최종 선택 태그 목록(리스트)
    @Published var selectedTags: List<Tag> = List<Tag>()
    // 현재 선택 중인 태그 목록(딕셔너리)
    var selectedTagsDict:[UUID:Tag] = [:]
    
    init(tags: [Tag]) {
        self.tags = CurrentValueSubject(tags)
    }
    
    func sendTags() {
        tags.send(Array(realm.objects(Tag.self)).reversed())
    }
    
    // Input => User Interaction
    /// **선택되어 있는 태그의 딕셔너리를 리스트 형태로 변환해서 반환**
    /// - Parameter selectedTagsDict: 현재 선택 중인 태그 목록 (딕셔너리 [UUID: Tag])
    /// - Returns: 현재 선택 중인 태그 목록(리스트)
    func selectedTagsDictToList(from selectedTagsDict: [UUID: Tag]) -> List<Tag> {
        let selectedTagsList: List<Tag> = List<Tag>()
        // 태그를 인덱스 내림차순으로 정리(태그 등록 오래된 순 -> 최신순)
        let sortedSelectedTagsArray = selectedTagsDict.sorted { $0.value.saveDate < $1.value.saveDate }.map{$0.value}
        for tag in sortedSelectedTagsArray {
            selectedTagsList.append(tag)
        }
        return selectedTagsList
    }

    /// ** 등록되어 있는 태그명 반환**
    /// - Returns: 현재 등록되어 있는 태그명들
    func getAddedTagsNames() -> [String] {
        return tags.value.map{$0.tagName}
    }
    
    /// **태그 삭제**
    /// - Parameter indexPath: 현재 삭제하려고 한 태그의 순번
    func deleteTag(indexPath: Int) {
        let selectedToDeleteTagId = Array(realm.objects(Tag.self)).reversed()[indexPath].id
        if selectedTagsDict.keys.contains(selectedToDeleteTagId) {
            selectedTagsDict.removeValue(forKey: selectedToDeleteTagId)
        }
        let selectedToDeleteTag = realm.object(ofType: Tag.self, forPrimaryKey: selectedToDeleteTagId)!
        try! realm.write {
            realm.delete(selectedToDeleteTag)
        }
        tags.send(Array(realm.objects(Tag.self)).reversed())
        selectedTags = selectedTagsDictToList(from: selectedTagsDict)
    }
    
    /// **태그 저장**
    /// - Parameter tagName: 등록할 태그명
    func saveTag(tagName: String) {
        // 등록할 태그를 태그 형태로 변환
        let tag = Tag(tagName: tagName, saveDate: Methods().calcDate(from: Date()))
        try! realm.write {
            realm.add(tag)
        }
    }
    
    /// **선택한 태그 데이터 반환**
    /// - Parameter indexPath: 현재 선택한 태그의 순번
    /// - Returns: 현재 선택한 태그의 정보
    func getTag(indexPath: Int) -> Tag {
        let tag = Array(realm.objects(Tag.self)).reversed()[indexPath]
        return tag
    }
    
    /// **태그 선택/해제 시 호출**
    /// - Parameter indexPath: 현재 선택/해제한 태그의 순번
    func selectOrDeselectTag(indexPath: IndexPath) {
        let tag = getTag(indexPath: indexPath.row)
        if selectedTagsDict.values.contains(tag) {
            selectedTagsDict.removeValue(forKey: tag.id)
        } else if selectedTagsDict.count <= 4 {
            selectedTagsDict[tag.id] = tag
        }
        selectedTags = selectedTagsDictToList(from: selectedTagsDict)
    }
    
    /// **URL 데이터 처리 및 저장**
    /// - Parameters:
    ///   - thumbnailImage: 썸네일 이미지 데이터
    ///   - title: 제목
    ///   - url: URL
    ///   - memo: 메모
    func saveItem(thumbnailImage: Data, title: String, url: String, memo: String) {
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
}
