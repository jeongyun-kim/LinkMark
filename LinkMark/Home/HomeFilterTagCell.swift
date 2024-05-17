//
//  HomeFilterTagCell.swift
//  LinkMark
//
//  Created by 김정윤 on 3/30/24.
//

import UIKit

class HomeFilterTagCell: UICollectionViewCell {
    @IBOutlet weak var filterTagLabelBtn: UIButton!
    
    /// **Cell UI 구성**
    func configure(item: Tag) {
        filterTagLabelBtn.layer.masksToBounds = true
        filterTagLabelBtn.layer.borderWidth = 1
        
        filterTagLabelBtn.layer.cornerRadius = 14
        filterTagLabelBtn.tintColor = .white
        filterTagLabelBtn.layer.borderColor = UIColor.systemGray5.cgColor
        let attirbute = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.black]
        let attributedTitle = NSAttributedString(string: item.tagName, attributes: attirbute)
        filterTagLabelBtn.setAttributedTitle(attributedTitle, for: .normal)
    }
}
