//
//  ManualCell.swift
//  LinkMark
//
//  Created by 김정윤 on 4/23/24.
//

import UIKit
import Toast

class ManualCell: UICollectionViewCell {
    @IBOutlet weak var manualDescBtn: UIButton!
    @IBOutlet weak var manualImageView: UIImageView!
    
    func configure(_ manual: ManualMessages) {
        manualImageView.image = UIImage(named: manual.imageName)
        
        manualDescBtn.tintColor = .lightGray
        manualDescBtn.layer.masksToBounds = true
        manualDescBtn.layer.cornerRadius = 6
        let attirbute = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15), NSAttributedString.Key.foregroundColor: UIColor.white]
        let attributedTitle = NSAttributedString(string: manual.description, attributes: attirbute)
        manualDescBtn.setAttributedTitle(attributedTitle, for: .normal)
        
    }
}
