//
//  DetailViewTagCell.swift
//  LinkMark
//
//  Created by 김정윤 on 3/28/24.
//
import SnapKit
import UIKit

class DetailTagCell: UICollectionViewCell {
    @IBOutlet weak var tagLabelBtn: UIButton!
    
    /// **Cell UI 구성**
    func configure(item: String) {
        tagLabelBtn.layer.masksToBounds = true
        tagLabelBtn.layer.cornerRadius = 5
        tagLabelBtn.tintColor = .systemGray5
        let attribute = [NSAttributedString.Key.foregroundColor: UIColor.gray, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13)]
        let attributedTitle = NSAttributedString(string: item, attributes: attribute)
        tagLabelBtn.setAttributedTitle(attributedTitle, for: .normal)
        tagLabelBtn.isEnabled = false
    }
}
