//
//  SearchCell.swift
//  LinkMark
//
//  Created by 김정윤 on 2/17/24.
//

import UIKit
import RealmSwift

class SearchCell: UICollectionViewCell {
    @IBOutlet weak var tagsLabel: UILabel!
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var memoLabel: UILabel!
    @IBOutlet weak var urlLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var bookmarkBtn: UIButton!
    @IBOutlet weak var safariBtn: UIButton!

    /// ** Cell UI 구성**
    /// - 기본 UI 구성
    func setupUI() {
        thumbnailImageView.layer.masksToBounds = true
        thumbnailImageView.layer.cornerRadius = 12
    }
    
    /// - Cell 내 데이터 넣기
    func configure(_ item: UrlList) {
        thumbnailImageView.image = UIImage(data: item.image!)
        titleLabel.text = item.title
        memoLabel.text = item.memo
        urlLabel.text = String(item.url.split(separator: "/")[1])
        var tagLabelText = ""
        for tag in item.tags {
            tagLabelText += "#\(tag.tagName)   "
        }
        tagsLabel.text = tagLabelText
        // 즐겨찾기 되어있는 상태라면 채워져있는 이미지로, 아니라면 빈 이미지
        if item.bookmark == true {
            bookmarkBtn.setImage(UIImage(systemName: "bookmark.fill"), for: .normal)
        } else {
            bookmarkBtn.setImage(UIImage(systemName: "bookmark"), for: .normal)
        }
        setupUI()
    }
}
