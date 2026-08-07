import Foundation
import os

/// 結構化除錯日誌（對應 Flutter 版 AppLogger）。
/// 統一走 os_log，帶 subsystem/category，方便用 Console 或 log stream 過濾。
enum AppLogger {
    private static let log = OSLog(subsystem: "com.daniel.isbn", category: "App")

    static func debug(_ msg: String, _ file: String = #file, _ line: Int = #line) {
        os_log("%{public}s [%s:%d]", log: log, type: .debug, msg, file, line)
    }

    static func warn(_ msg: String, _ file: String = #file, _ line: Int = #line) {
        os_log("%{public}s [%s:%d]", log: log, type: .error, msg, file, line)
    }

    static func error(_ msg: String, _ error: Error? = nil, _ file: String = #file, _ line: Int = #line) {
        let detail = error.map { " \(String(describing: $0))" } ?? ""
        os_log("%{public}s%{public}s [%s:%d]", log: log, type: .error, msg, detail, file, line)
    }

    /// 把除錯訊息寫入 app 沙箱 Documents/search_debug.log，
    /// 供 `xcrun devicectl device copy from --domain-type appDataContainer` 拉回分析。
    /// 每行帶時間戳，可用來判斷查詢是否卡住/哪個來源失敗。
    static func fileLog(_ msg: String) {
        let dir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? ""
        let path = (dir as NSString).appendingPathComponent("search_debug.log")
        let line = "[DEBUG] \(Date()) \(msg)\n"
        guard let data = line.data(using: .utf8) else { return }
        do {
            if let fh = try? FileHandle(forWritingTo: URL(fileURLWithPath: path)) {
                fh.seekToEndOfFile()
                fh.write(data)
                fh.closeFile()
            } else {
                try data.write(to: URL(fileURLWithPath: path))
            }
        } catch {}
    }
}
