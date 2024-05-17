//
//  Tag.swift
//  LinkMark
//
//  Created by 김정윤 on 2/27/24.
//

import Foundation
import RealmSwift

class Tag: Object {
    @Persisted (primaryKey: true) var id: UUID = UUID()
    @Persisted var tagName: String
    @Persisted var saveDate: Date

    convenience init(tagName: String, saveDate: Date) {
        self.init()
        self.saveDate = saveDate
        self.tagName = tagName
    }
}


