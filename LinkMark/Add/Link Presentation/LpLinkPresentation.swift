import LinkPresentation
import UniformTypeIdentifiers
 
// loadDataRepresentation을 async/await 할 수 있도록 수정
extension NSItemProvider {
    func loadDataRepresentation(for type: UTType) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            _ = self.loadDataRepresentation(for: type) { data, error in
                if let data {
                    // 불러온 데이터 return
                    continuation.resume(returning: data)
                } else if let error {
                    // 에러 던지기
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
