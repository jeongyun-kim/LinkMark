//
//  TagListBackgroundView.swift
//  LinkMark
//
//  Created by 김정윤 on 4/4/24.
//

import UIKit
import SnapKit


/// **태그 Section의 DecorationView**
class TagListBackgroundView: UICollectionReusableView {
    // DecorationView 생성
    let grayBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray5.withAlphaComponent(0.4)
        view.layer.borderWidth = 0.6
        view.layer.borderColor = UIColor.systemGray5.cgColor
        return view
    }()
    
    // DecorationView 추가 및 AutoLayout 지정
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(grayBackgroundView)
        grayBackgroundView.snp.makeConstraints {
            $0.top.leading.trailing.bottom.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension UICollectionReusableView {
    static var reuseIdentifier: String {
        return String(describing: Self.self)
    }
}
