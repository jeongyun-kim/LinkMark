
// 데이터 불러올 때, 아이콘 불러올 때 에러 정의
enum LPLoaderCase: Error {
    // 메타데이터를 불러오지 못했을 때
    case metadataLoadingFailed
    // 아이콘을 불러오지 못했을 때
    case faviconCouldNotBeLoaded
    // 아이콘이 없을 때
    case faviconDataInvalid
}


