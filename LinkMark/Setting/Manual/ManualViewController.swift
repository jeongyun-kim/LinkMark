//
//  ManualViewController.swift
//  LinkMark
//
//  Created by 김정윤 on 4/23/24.
//

import UIKit

class ManualViewController: UIViewController {

    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var collectionView: UICollectionView!
    
    let manuals: [ManualMessages] = ManualMessages.manuals
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "사용방법"
        collectionView.delegate = self
        collectionView.dataSource = self
        
        pageControl.numberOfPages = manuals.count
        pageControl.currentPage = 0
        
        navigationItem.largeTitleDisplayMode = .never
    }
}

extension ManualViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.bounds.size
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return .zero
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return .zero
    }
}

extension ManualViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return manuals.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ManualCell", for: indexPath) as? ManualCell else {
             return UICollectionViewCell()
        }
        let manual = manuals[indexPath.row]
        cell.configure(manual)
        return cell
    }
}

// 현재 스크롤뷰의 상황을 파악할 수 있음
extension ManualViewController: UIScrollViewDelegate {
    // 감속하면서 멈추었단거 확인 가능
    // => 인덱스 값을 줘서 페이지컨트롤 업데이트
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let index = Int(scrollView.contentOffset.x / self.collectionView.bounds.width)
        
        pageControl.currentPage = index
    }
}
