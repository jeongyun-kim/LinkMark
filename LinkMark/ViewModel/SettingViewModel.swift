//
//  SettingViewModel.swift
//  LinkMark
//
//  Created by 김정윤 on 4/18/24.
//

import Foundation
import Combine
import RealmSwift

final class SettingViewModel {
    // Output => Data
    var realm: Realm {
        let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.LinkMark.Share")
        let realmURL = container?.appendingPathComponent("share.realm")
        let config = Realm.Configuration(fileURL: realmURL)
        return try! Realm(configuration: config)
    }
    
    // 모든 태그 목록
    let tags: CurrentValueSubject<[Tag], Never>
    
    init(tags: [Tag]) {
        self.tags = CurrentValueSubject(tags)
    }
    
    func sendTags() {
        tags.send(Array(realm.objects(Tag.self)).reversed())
    }
    
    // Input => User Interactions
    
    /// **선택한 태그 정보 반환**
    /// - Parameter indexPath: 현재 사용자가 선택한 태그의 순번
    /// - Returns: 현재 사용자가 선택한 태그의 정보
    func getTag(_ indexPath: Int) -> Tag {
        let tag = tags.value[indexPath]
        return tag
    }
    
    /// **등록되어 있는 태그명 목록 반환**
    /// - Returns: 이미 등록되어 있는 태그명들
    func getAddedTagsNames() -> [String] {
        return tags.value.map { $0.tagName }
    }
    
    /// **태그 저장**
    /// - Parameter tagName: 등록할 태그명
    func saveTag(tagName: String) {
        let tag = Tag(tagName: tagName, saveDate: Methods().calcDate(from: Date()))
        try! realm.write {
            realm.add(tag)
        }
        sendTags()
    }
    
    /// **태그 삭제**
    /// - Parameter tagsToDeleteDict: 삭제할 태그 목록(딕셔너리 [indexPath: Tag])
    /// 1. 삭제할 태그 목록에서 태그들의 ID만 추출
    /// 2. 각 ID로 데이터 불러와 Realm에서 삭제 처리
    /// 3. Publisher 업데이트
    func deleteTags(_ tagsToDeleteDict: [UUID: Tag]) {
        let tagsToDelete = tagsToDeleteDict.map{ $0.key }
        for id in tagsToDelete {
            let toDeleteTag = realm.object(ofType: Tag.self, forPrimaryKey: id)!
            try! realm.write {
                realm.delete(toDeleteTag)
            }
        }
        // 태그 삭제 후 태그 Publisher 업데이트 
        sendTags()
    }
    
    /// **태그명 수정**
    /// - Parameters:
    ///   - tag: 현재 수정하려는 태그 정보
    ///   - newTagName: 수정하려는 태그명 
    func editTag(tag: Tag, newTagName: String) {
        try!realm.write {
            tag.tagName = newTagName
        }
        sendTags()
    }
}
