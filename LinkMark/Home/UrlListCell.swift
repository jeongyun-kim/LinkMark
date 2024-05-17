//  UrlListCell.swift
//  LinkMark
// 링크 목록

import UIKit
import SafariServices
import RealmSwift

class UrlListCell: UICollectionViewCell {
    @IBOutlet weak var selectIndicator: UIButton!
    @IBOutlet weak var highlightIndicator: UIView!
 
    @IBOutlet weak var tagsLabel: UILabel!
    @IBOutlet weak var safariBtn: UIButton!
    @IBOutlet weak var memoLabel: UILabel!
    @IBOutlet weak var urlLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var bookmarkBtn: UIButton!
    
    enum Mode {
        case view
        case select
    }
    
    override class func awakeFromNib() {
        super.awakeFromNib()
    }
    
    /// **Cell 기본 UI 구성**
    func setupUI() {
        thumbnailImageView.layer.masksToBounds = true
        thumbnailImageView.layer.cornerRadius = 12
    }
    
    /// **Cell에 데이터 넣기**
    func configure(item: UrlList, mode: Mode) {
        setupUI()
        // 기본 세팅
        thumbnailImageView.image = UIImage(data: item.image!)
        titleLabel.text = item.title
        memoLabel.text = item.memo
        let url = String(item.url.split(separator: "/")[1])
        urlLabel.text = url
        var tagLabelText = ""
        for tag in item.tags {
            tagLabelText += "#\(tag.tagName)   "
        }
        tagsLabel.text = tagLabelText
        // 모드마다 다르게
        switch (mode) {
        case .view:
            bookmarkBtn.isHidden = false
            selectIndicator.isHidden = true
            safariBtn.isHidden = false
            // 즐겨찾기 되어있는 상태라면 채워져있는 이미지로, 아니라면 빈 이미지
            if item.bookmark == true {
                bookmarkBtn.setImage(UIImage(systemName: "bookmark.fill"), for: .normal)
            } else {
                bookmarkBtn.setImage(UIImage(systemName: "bookmark"), for: .normal)
            }
            isHighlighted = false
            isSelected = false
        case .select:
            bookmarkBtn.isHidden = true
            selectIndicator.isHidden = false
            safariBtn.isHidden = true
        }
    }
    
    // 선택했을 때, 안했을 때
    /// 선택하면 회색 배경이 나타남
    override var isHighlighted: Bool {
        didSet  {
            highlightIndicator.isHidden = !isHighlighted
        }
    }
    /// 선택하면 체크 표시 / 해제하면 원 표시
    override var isSelected: Bool {
            didSet {
                highlightIndicator.isHidden = !isSelected
                if isSelected {
                    selectIndicator.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .normal)
                } else {
                    selectIndicator.setImage(UIImage(systemName: "circle"), for: .normal)
                }
            }
        }
}

