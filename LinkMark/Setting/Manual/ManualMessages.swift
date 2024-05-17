//
//  ManualMessages.swift
//  LinkMark
//
//  Created by 김정윤 on 4/23/24.
//

import Foundation

struct ManualMessages {
    let imageName: String
    let description: String
}

extension ManualMessages {
    static let manuals: [ManualMessages] = [
    ManualMessages(imageName: "img_home_no_url", description: "상단의 버튼을 통해 URL을 추가합니다"),
    ManualMessages(imageName: "img_share_view", description: "공유하기를 통해 URL을 추가할 수도 있습니다 (특정 앱에서는 불가능할 수 있습니다🥺 그럴 때에는 URL을 붙여넣기해서 불러와주세요"),
    ManualMessages(imageName: "img_add_view", description: "직접 URL을 붙여넣거나 공유하기를 통해 URL을 가져와 URL의 정보를 가져옵니다(직접 URL을 붙여넣기한 경우, 버튼을 눌러주세요!"),
    ManualMessages(imageName: "img_home_urls", description: "그럼 홈화면에서 저장된 URL을 확인할 수 있습니다"),
    ManualMessages(imageName: "img_home_filter", description: "저장된 URL들은 필터링 버튼을 통해 최신순 또는 오래된 순으로 정렬할 수 있습니다"),
    ManualMessages(imageName: "img_home_delete", description: "URL을 삭제하기 위해서는 좌측 상단의 선택을 눌러 삭제할 URL들을 선택 후 우측 하단의 휴지통 버튼을 눌러주세요"),
    ManualMessages(imageName: "img_filter_view", description: "상단의 태그 버튼을 누르면 해당 태그가 포함된 URL들을 볼 수 있습니다"),
    ManualMessages(imageName: "img_bookmark_view", description: "즐겨찾기에서는 즐겨찾기 표시가 된 URL들만 확인할 수 있습니다"),
    ManualMessages(imageName: "img_tag_manage", description: "태그 관리에서는 태그를 등록하거나 수정하고 삭제할 수 있습니다"),
    ManualMessages(imageName: "img_tag_edit", description: "태그명 수정을 위해선 태그명을 눌러주세요"),
    ManualMessages(imageName: "img_send_email", description: "문의하기를 통해 개발자에게 문의를 넣을 수 있습니다 :) 그 전에 기본앱 이메일의 설정이 제대로 되어있는지 확인해주세요!")
    ]
}
