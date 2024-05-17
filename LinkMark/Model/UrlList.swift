//
//  UrlList.swift
//  LinkMark
//
//  Created by 김정윤 on 1/10/24.
//

import Foundation
import RealmSwift

class UrlList: Object {
    @Persisted(primaryKey: true) var id: UUID = UUID()
    @Persisted var image: Data?
    @Persisted var title: String
    @Persisted var url: String
    @Persisted var memo: String?
    @Persisted var bookmark: Bool
    @Persisted var saveDate: Date
    @Persisted var tags: List<Tag>
    
    convenience init(image: Data? = nil, title: String, url: String, memo: String? = nil, saveDate: Date, tags: List<Tag>
    )
    {
        self.init()
        self.image = image
        self.title = title
        self.url = url
        self.memo = memo ?? ""
        self.saveDate = saveDate
        self.tags = tags
    }
}
