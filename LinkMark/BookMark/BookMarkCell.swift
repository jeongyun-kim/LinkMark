//
//  BookmarkCell.swift
//  LinkMark
//
//  Created by 김정윤 on 2/5/24.
//

import UIKit
import RealmSwift

class BookMarkCell: UICollectionViewCell {
    @IBOutlet weak var memoLabel: UILabel!
    @IBOutlet weak var urlLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var safariBtn: UIButton!
    @IBOutlet weak var bookmarkBtn: UIButton!
    @IBOutlet weak var tagsLabel: UILabel!
    
    /// **Cell 기본 UI 구성**
    func setupUI() {
        thumbnailImageView.layer.masksToBounds = true
        thumbnailImageView.layer.cornerRadius = 12
    }
    
    /// **Cell 내 데이터 넣기**
    func configure(item: UrlList) {
        thumbnailImageView.image = UIImage(data: item.image!)
        titleLabel.text = item.title
        urlLabel.text = String(item.url.split(separator: "/")[1])
        memoLabel.text = item.memo
        var tagLabelText = ""
        for tag in item.tags {
            tagLabelText += "#\(tag.tagName)   "
        }
        tagsLabel.text = tagLabelText
        bookmarkBtn.setImage(UIImage(systemName: "bookmark.fill"), for: .normal)
        setupUI()
        
    }
}
