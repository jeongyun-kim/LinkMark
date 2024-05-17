//
//  Methods.swift
//  LinkMark
//
//  Created by 김정윤 on 4/10/24.
//

import Foundation
import Lottie
import UIKit
import Toast
import RealmSwift

class Methods {
    var realm: Realm {
        let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.LinkMark.Share")
        let realmURL = container?.appendingPathComponent("share.realm")
        let config = Realm.Configuration(fileURL: realmURL)
        return try! Realm(configuration: config)
    }
    
    func getTagCntFromUrls(tag: Tag) -> Int {
        let cnt = Array(realm.objects(UrlList.self)).filter{ Array($0.tags).contains(tag) }.count
        return cnt
    }
    
    /// - 시간대 별 시차 적용
    func calcDate(from date: Date) -> Date {
        let timezone = TimeZone.autoupdatingCurrent
        let fromGMT = timezone.secondsFromGMT(for: date)
        let localizedDate = date.addingTimeInterval(TimeInterval(fromGMT))
        return localizedDate
    }
    
    /// - 로딩 중 화면 구성
    func lottieView(view: UIView, name: String) -> LottieAnimationView {
        let animation = LottieAnimation.named(name)
        let animationView = LottieAnimationView(animation: animation)
        animationView.frame = CGRect(x: 0, y: 0, width: 200, height: 200)
        animationView.center = view.center
        animationView.loopMode = .loop
        view.addSubview(animationView)
        return animationView
    }
  
    /// - 토스트 메시지 구성
    func toastMessage(message: String, view: UIView) {
        var toastStyle = ToastStyle()
        toastStyle.backgroundColor = UIColor(red: 190/255, green: 167/255, blue: 249/255, alpha: 1.0)
        toastStyle.messageColor = .white
        toastStyle.verticalPadding = 12
        toastStyle.horizontalPadding = 12
        toastStyle.messageFont = .systemFont(ofSize: 16, weight: .regular)
        if message == "저장완료!" {
            view.makeToast(message, duration: 0.8, position: .center, style: toastStyle)
        } else {
            view.makeToast(message, duration: 0.8, position: .bottom, style: toastStyle)
        }
    }
   
    /// - 알림창 구성
    func alert(for title: String, vc: UIViewController) {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        let pointColor = UIColor(hue: 0.7306, saturation: 0.54, brightness: 1, alpha: 1.0)
        alert.setValue(NSAttributedString(string: title, attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16, weight: .bold), NSAttributedString.Key.foregroundColor : pointColor]), forKey: "attributedTitle")
        alert.view.subviews.first?.subviews.first?.subviews.first?.backgroundColor = UIColor.white
        // 팝업 띄우기
        vc.present(alert, animated: true)
        // 0.6초 뒤에 사라지도록 시간 설정
        Timer.scheduledTimer(withTimeInterval: 0.65, repeats: false, block: { _ in alert.dismiss(animated: true) } )
    }
    
    /// - 메시지까지 있는 알림창 구성만 
    func alertSetTitle(title: String, message: String?) -> UIAlertController {
        let titleColor = UIColor(hue: 0.7306, saturation: 0.54, brightness: 1, alpha: 1.0)
        let messageColor = UIColor.lightGray
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        // 제목 및 메시지 컬러 변경
        alert.setValue(NSAttributedString(string: title, attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16, weight: .bold), NSAttributedString.Key.foregroundColor : titleColor]), forKey: "attributedTitle")
        alert.setValue(NSAttributedString(string: message ?? "", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 14, weight: .regular), NSAttributedString.Key.foregroundColor : messageColor]), forKey: "attributedMessage")
        alert.view.subviews.first?.subviews.first?.subviews.first?.backgroundColor = .white // 배경색 변경
        return alert
    }
    
    /// Date -> String으로 변환
    func dateToString(saveDate: Date) -> Substring {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let saveDateString = dateFormatter.string(from: saveDate)
        let saveDate = "\(saveDateString)".split(separator: " ")[0]
        return saveDate
    }
}

