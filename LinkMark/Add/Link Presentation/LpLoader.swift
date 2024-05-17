import LinkPresentation
import UniformTypeIdentifiers
import WebKit

/// **Link Presentation Methods 정의**
class LPLoader {
    // URL 통해 메타데이터 불러오기
    func load(for url: URL) async throws -> LPLinkMetadata {
        // metadataProvider : URL에서 메타데이터를 검색하는 객체
        let metadataProvider = LPMetadataProvider()
        // 현재 URL의 메타데이터를 가진 객체
        let metadata: LPLinkMetadata
        // 메타데이터 불러오기
        do {
            metadata = try await metadataProvider.startFetchingMetadata(for: url)
        } catch { // 데이터를 불러오는데 실패했다면
            throw LPLoaderCase.metadataLoadingFailed
        }
        return metadata
    }
    
    // URL 내 메타데이터 통해 아이콘(썸네일) 가져오기
    func favicon(metadata: LPLinkMetadata) async throws -> UIImage {
        // iconProvider : URL에서 썸네일을 검색하는 객체
        guard let iconProvider = metadata.iconProvider else {
            throw LPLoaderCase.faviconCouldNotBeLoaded // 아이콘을 불러올 수 없다면
        }
        // 아이콘(썸네일) 데이터 정의
        let iconData: Data
        do {
            iconData = try await iconProvider.loadDataRepresentation(for: .image) // 아이콘(썸네일) 불러오기
        } catch {
            throw LPLoaderCase.faviconCouldNotBeLoaded // 메타(아이콘)데이터를 불러올 수 없을때
        }
        // 불러온 아이콘(썸네일)을 UIImage로 변환
        guard let icon = UIImage(data: iconData) else {
            throw LPLoaderCase.faviconDataInvalid // 아이콘이 없는 경우
        }
        return icon // 아이콘(썸네일) 반환
    }
    
    func thumbnail(metadata: LPLinkMetadata) async throws -> UIImage {
        // imageProvider : URL에서 썸네일을 검색하는 객체
        guard let imageProvider = metadata.imageProvider else {
            throw LPLoaderCase.faviconCouldNotBeLoaded // 아이콘을 불러올 수 없다면
        }
        // 아이콘(썸네일) 데이터 정의
        let thumbnailData: Data
        do {
            thumbnailData = try await imageProvider.loadDataRepresentation(for: .video) // 아이콘(썸네일) 불러오기
        } catch {
            throw LPLoaderCase.faviconCouldNotBeLoaded // 메타(아이콘)데이터를 불러올 수 없을때
        }
        // 불러온 아이콘(썸네일)을 UIImage로 변환
        guard let thumbnail = UIImage(data: thumbnailData) else {
            throw LPLoaderCase.faviconDataInvalid // 아이콘이 없는 경우
        }
        return thumbnail // 아이콘(썸네일) 반환
    }
}
