//
//  Extensions.swift
//  LinkMark
//
//  Created by 김정윤 on 4/15/24.
//

import Foundation
import UIKit

/// **UILabel에 행간 주기**
extension UILabel {
    public func setLineSpacing(lineSpacing: CGFloat) {
        if let text = self.text {
            let attributedStr = NSMutableAttributedString(string: text)
            let style = NSMutableParagraphStyle()
            style.lineSpacing = lineSpacing
            attributedStr.addAttribute(
                NSAttributedString.Key.paragraphStyle,
                value: style,
                range: NSRange(location: 0, length: attributedStr.length))
            self.attributedText = attributedStr
        }
    }
}

/// **컬렉션뷰 비어있을 때 보여주는 emptyView**
extension UICollectionView {
    // 데이터가 없을 때 보여주는 backgroundView에 message 세팅
    func setEmptyMessage(_ title: String, _ message: String, vc: String) {
        
        let emptyView: UIView = {
            let emptyView = UIView()
            emptyView.frame = CGRect(x: self.center.x, y: self.center.y, width: self.bounds.width, height: 0)
            //emptyView.backgroundColor = .lightGray
            return emptyView
        }()
        
        let titleLabel: UILabel = {
            let label = UILabel()
            label.text = title
            label.numberOfLines = 0
            label.textAlignment = .center
            //label.font = UIFont(name: "SF Pro", size: 14)
            label.font = .systemFont(ofSize: 17, weight: .semibold)
            label.textColor = .gray
            label.sizeToFit()
            return label
        }()
        let messageLabel: UILabel = {
            let label = UILabel()
            if vc == "Home" {
                let attributedString = NSMutableAttributedString(string: "")
                let imageAttachment = NSTextAttachment()
                imageAttachment.image = UIImage(systemName: "plus.square")?.withTintColor(.gray, renderingMode: .alwaysTemplate)
                imageAttachment.bounds = CGRect(x: 0, y: -5, width: 22, height: 20)
                attributedString.append(NSAttributedString(attachment: imageAttachment))
                attributedString.append(NSAttributedString(string: message))
                label.attributedText = attributedString
            } else {
                label.text = message
            }
            label.numberOfLines = 0
            label.textAlignment = .center
            label.font = .systemFont(ofSize: 16)
            label.textColor = .gray
            label.sizeToFit()
            return label
        }()
        emptyView.addSubview(titleLabel)
        emptyView.addSubview(messageLabel)
        titleLabel.snp.makeConstraints {
            if vc == "Home" {
                $0.centerY.equalTo(emptyView.snp.centerY).offset(-50)
            } else {
                $0.centerY.equalTo(emptyView.snp.centerY)
            }
            $0.centerX.equalTo(emptyView.snp.centerX)
        }
        messageLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(10)
            $0.left.equalTo(emptyView.snp.left)
            $0.right.equalTo(emptyView.snp.right)
        }
        self.backgroundView = emptyView
    } // 데이터가 있을 때 backgroundView 없애기
    func restore() {
        self.backgroundView = nil
    }
}

