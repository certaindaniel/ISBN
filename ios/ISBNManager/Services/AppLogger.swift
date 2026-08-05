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
}
