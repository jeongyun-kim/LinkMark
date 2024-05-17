//
//  TagManageCell.swift
//  LinkMark
//
//  Created by 김정윤 on 4/18/24.
//

import UIKit

class TagManageCell: UICollectionViewCell {
    @IBOutlet weak var tagNameBtn: UIButton!
    //@IBOutlet weak var tagName: UILabel!
    @IBOutlet weak var tagCnt: UILabel!
    @IBOutlet weak var selectIndicator: UIImageView!
    
    func configure(item: Tag) {
        let attirbute = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15), NSAttributedString.Key.foregroundColor: UIColor.black]
        let attributedTitle = NSAttributedString(string: item.tagName, attributes: attirbute)
        tagNameBtn.setAttributedTitle(attributedTitle, for: .normal)
        let cnt = Methods().getTagCntFromUrls(tag: item)
        tagCnt.text = "(\(cnt))"
    }
    
    override var isSelected: Bool {
        didSet {
            if isSelected {
                selectIndicator.tintColor = UIColor(hue: 0.7139, saturation: 0.4, brightness: 1, alpha: 1.0)
                selectIndicator.image = UIImage(systemName: "checkmark.circle.fill")
            } else {
                selectIndicator.tintColor = UIColor.systemGray4
                selectIndicator.image = UIImage(systemName: "circle")
            }
        }
    }
}
