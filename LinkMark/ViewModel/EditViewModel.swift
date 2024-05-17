//
//  EditViewModel.swift
//  LinkMark
//
//  Created by 김정윤 on 4/6/24.
//

import Foundation
import Combine
import RealmSwift

final class EditViewModel: ObservableObject{
    // Output => Data
    var realm: Realm {
        let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.LinkMark.Share")
        let realmURL = container?.appendingPathComponent("share.realm")
        let config = Realm.Configuration(fileURL: realmURL)
        return try! Realm(configuration: config)
    }
    
    // 모든 태그 목록
    var tags: CurrentValueSubject<[Tag], Never>
    // 선택되어있는 태그 List
    @Published var selectedTags: List<Tag> = List<Tag>()
    // 선택되어있는 태그 Dict(태그의 인덱스 : 태그 데이터)
    var selectedTagsDict:[UUID:Tag] = [:]
    
    init(tags: [Tag]) {
        self.tags = CurrentValueSubject(tags)
    }
    
    /// **현재 저장되어있는 태그들 Publisher로 전송**
    func sendTags() {
        tags.send(Array(realm.objects(Tag.self)).reversed())
    }
    
    /// **이미 등록되어있는 태그명들 반환**
    /// - Returns: 이미 등록되어 있는 태그명들
    func getAddedTagsNames() -> [String] {
        return tags.value.map{$0.tagName}
    }
    
    /// **DetailView로부터 받아온 태그 목록을 딕셔너리 형태로 변환**
    /// <- select / deselect 했을 때, key(indexPath)로 업데이트하고 지우기 위해
    func selectedTagsToDict() {
        for selectedTag in selectedTags {
            selectedTagsDict[selectedTag.id] = selectedTag
        }
    }
    
    /// **선택되어 있는 태그의 딕셔너리를 리스트 형태로 변환해서 반환**
    /// - Returns: 선택 중인 태그 목록(리스트)
    func selectedTagsDictToList() -> List<Tag> {
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
    func deleteTag(indexPath: Int) {
        let selectedToDeleteTagId = Array(realm.objects(Tag.self)).reversed()[indexPath].id
        if selectedTagsDict.keys.contains(selectedToDeleteTagId) {
            selectedTagsDict.removeValue(forKey: selectedToDeleteTagId)
        }
        guard let selectedToDeleteTag = realm.object(ofType: Tag.self, forPrimaryKey: selectedToDeleteTagId) else { return }
        try! realm.write {
            realm.delete(selectedToDeleteTag)
        }
        tags.send(Array(realm.objects(Tag.self)).reversed())
        selectedTags = selectedTagsDictToList()
    }
    
    /// **태그 저장**
    /// - Parameter tagName: 등록할 태그명
    func saveTag(tagName: String) {
        let tag = Tag(tagName: tagName, saveDate: Methods().calcDate(from: Date()))
        try! realm.write {
            realm.add(tag)
        }
    }
    
    /// **태그를 선택하거나 해제했을 때 실행**
    /// 1. 해당 태그의 인덱스를 받아옴
    /// 2. 인덱스를 통해 사용자가 선택한 태그의 정보를 가져옴
    /// 3-1.  선택한 태그 딕셔너리에 [인덱스:태그 정보] 저장
    /// 3-2. 선택한 태그 딕셔너리에서 인덱스 이용해서 해당 태그 정보 삭제
    /// 4. 현재 선택되어있는 태그 딕셔너리를 리스트 형식으로 변환하여 대입해줌
    /// - Parameter indexPath: 현재 선택/해제한 태그의 순번
    func selectOrDeselectTag(at indexPath: IndexPath) {
        let tagData = Array(realm.objects(Tag.self)).reversed()[indexPath.row]
        if selectedTagsDict.values.contains(tagData) {
            selectedTagsDict.removeValue(forKey: tagData.id)
        } else if selectedTagsDict.count <= 4 {
            selectedTagsDict[tagData.id] = tagData
        }
        selectedTags = selectedTagsDictToList()
    }
    
    /// **URL 데이터 저장**
    /// - Parameters:
    ///   - id: 현재 URL 아이템의 ID
    ///   - title: 현재 URL 아이템의 제목
    ///   - memo: 현재 URL 아이템의 메모
    func saveData(id: UUID, title: String, memo: String) {
        // 데이터 바꾸기 위해 원래 저장된 데이터 가져오기
        guard let data = realm.object(ofType: UrlList.self, forPrimaryKey: id) else { return }
        // 데이터 변경 
        try! realm.write {
            data.title = title
            data.memo = memo
            data.tags = selectedTags
        }
    }
}
