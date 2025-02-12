import Foundation

extension FileManager {
    func removeFileIfNecessary(at url: URL) throws {
        guard fileExists(atPath: url.path) else {
            return
        }
        
        do {
            try removeItem(at: url)
        } catch let error {
            throw TTDTrimError("Couldn't remove existing destination file: \(error)")
        }
    }
}
