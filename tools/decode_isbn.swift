import Foundation
import Vision
import CoreGraphics
import ImageIO

// 最小工具：把一張圖片當作「使用者拍到的相機畫面」，用 Vision 解出其中的條碼 ISBN。
// 用法: swift decode_isbn.swift <image-path>

guard CommandLine.arguments.count >= 2 else {
    print("usage: swift decode_isbn.swift <image-path>")
    exit(1)
}
let path = CommandLine.arguments[1]
guard let src = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil) else {
    print("cannot open image: \(path)")
    exit(2)
}
guard let image = CGImageSourceCreateImageAtIndex(src, 0, nil) else {
    print("cannot decode image: \(path)")
    exit(3)
}

let request = VNDetectBarcodesRequest()
let handler = VNImageRequestHandler(cgImage: image, options: [:])
try handler.perform([request])

var found = false
for obs in request.results ?? [] {
    guard let data = obs.payloadData, !data.isEmpty else { continue }
    found = true

    // 把 payload 位元組轉成數字字串。
    // EAN-13 payload 可能是 ASCII 數字(0x30..0x39) 或「數字值」(0..9)。
    var digits = ""
    for b in data {
        if b >= 0x30 && b <= 0x39 { digits.append(Character(UnicodeScalar(b))) }      // ASCII digit
        else if b <= 0x09 { digits.append(Character(UnicodeScalar(0x30 + b))) }      // digit value
        else { digits.append("?") }
    }

    let isbn = digits.filter { $0.isNumber }
    let valid = ISBN13ChecksumValid(isbn) && (isbn.hasPrefix("978") || isbn.hasPrefix("979"))
    print("symbology=\(obs.symbology)")
    print("payload=\(isbn)")
    print(valid ? "ISBN_VALID" : "ISBN_INVALID")
}

if !found {
    print("no barcode detected")
    exit(4)
}

func ISBN13ChecksumValid(_ s: String) -> Bool {
    guard s.count == 13 else { return false }
    let chars = Array(s)
    var sum = 0
    for i in 0..<12 {
        guard let d = chars[i].wholeNumberValue else { return false }
        sum += i % 2 == 0 ? d : d * 3
    }
    guard let check = chars[12].wholeNumberValue else { return false }
    let expected = (10 - (sum % 10)) % 10
    return check == expected
}
