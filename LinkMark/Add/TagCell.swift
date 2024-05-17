//
//  TagCell.swift
//  LinkMark
//
//  Created by 김정윤 on 3/25/24.
//

import UIKit
import RealmSwift

class TagCell: UICollectionViewCell {
    
    @IBOutlet weak var deleteBtn: UIButton!
    @IBOutlet weak var selectIndicator: UIButton!
    @IBOutlet weak var tagName: UILabel!
    
    /// **Cell UI 구성**
    func configure(_ item: Tag, tags: List<Tag>) {
        tagName.text = item.tagName
        if tags.contains(item) {
            setSelected(true)
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
