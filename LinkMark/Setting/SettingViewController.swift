//
//  SettingViewController.swift
//  LinkMark
//
//  Created by 김정윤 on 1/9/24.
//

import UIKit
import MessageUI

class SettingViewController: UIViewController {
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var sendEmailBtn: UIButton!
    @IBOutlet weak var tagManageBtn: UIButton!
    @IBOutlet weak var manualBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    /// **기본 UI 구성**
    private func setupUI() {
        tagManageBtn.tintColor = .gray
        sendEmailBtn.tintColor = .gray
        manualBtn.tintColor = .gray
        navigationItem.backButtonTitle = ""
        navigationController?.navigationBar.tintColor = .black
        versionLabel.text = "버전 1.1.1"
    }
    
    /// **태그 관리 버튼 눌렀을 때**
    @IBAction func tagManageBtnTapped(_ sender: Any) {
        let sb = UIStoryboard(name: "TagManage", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "TagManageViewController") as! TagManageViewController
        navigationController?.pushViewController(vc, animated: true)
    }
    
    /// **사용방법 버튼 눌렀을 때**
    @IBAction func manualBtnTapped(_ sender: Any) {
        let sb = UIStoryboard(name: "Manual", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "ManualViewController") as! ManualViewController
        navigationController?.pushViewController(vc, animated: true)
    }
    
    /// **문의하기 버튼 눌렀을 때**
    @IBAction func sendEmailBtnTapped(_ sender: Any) {
        if MFMailComposeViewController.canSendMail() {
            let vc = MFMailComposeViewController()
            vc.mailComposeDelegate = self
            // 메일을 받을 이메일 주소 = 내 이메일
            vc.setToRecipients(["kkanyo04@naver.com"])
            // 이메일 제목
            vc.setSubject("[링마크 문의]")
            // 이메일 콘텐츠
            // isHTML : HTML 내용이 포함되어 있다면 true
            vc.setMessageBody("문의 내용을 적어주세요 :)", isHTML: false)
            self.present(vc, animated: true)
        } else {
            let alert = Methods().alertSetTitle(title: "메일 전송 실패", message: "이메일 설정을 확인 후 다시 시도해주세요")
            let confirmAction = UIAlertAction(title: "확인", style: .cancel)
            confirmAction.setValue(UIColor(hue: 0.7083, saturation: 0.34, brightness: 1, alpha: 1.0), forKey: "titleTextColor")
            alert.addAction(confirmAction)
            present(alert, animated: true)
        }
    }
}

// 메일 전송 이후 행동
extension SettingViewController: MFMailComposeViewControllerDelegate {
  func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
      // 메일창 내리기 
      controller.dismiss(animated: true)
  }
}
