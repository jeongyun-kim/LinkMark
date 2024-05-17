//
//  EditTagCell.swift
//  LinkMark
//
//  Created by 김정윤 on 4/6/24.
//

import UIKit
import RealmSwift

class EditTagCell: UICollectionViewCell {
    
    @IBOutlet weak var deleteBtn: UIButton!
    @IBOutlet weak var selectIndicator: UIButton!
    @IBOutlet weak var tagName: UILabel!
    
    /// ** Cell UI 구성**
    /// - item : 현재 컬렉션뷰에 그려지는 태그
    /// - tags : 현재 편집하려는 링크가 가지고 있는 태그들
    func configure(_ item: Tag, tags: List<Tag>) {
        tagName.text = item.tagName
        // 현재의 태그 아이디가 편집 중인 링크가 가지고 있는 태그 아이디에 포함되어 있다면 선택됨 처리 
        if tags.contains(item) {
            self.setSelected(true)
        } else {
            setSelected(false)
        }
    }
    
    /// **현재 태그의 선택 여부에 따라 UI 변화**
    private func setSelected(_ selected: Bool) {
           if selected {
               self.selectIndicator.tintColor = UIColor(hue: 0.7139, saturation: 0.4, brightness: 1, alpha: 1.0)
               self.selectIndicator.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .normal)
           } else {
               self.selectIndicator.tintColor = .systemGray4
               self.selectIndicator.setImage(UIImage(systemName: "circle"), for: .normal)
           }
       }
}
