import Foundation

struct LyricLine: Identifiable, Hashable {
    let id = UUID()
    let time: TimeInterval
    let text: String
}

struct ParsedLyrics: Hashable {
    let lines: [LyricLine]
    let metadata: [String: String]

    var isSynced: Bool {
        lines.contains { $0.time > 0 }
    }

    var plainText: String {
        lines.map(\.text).joined(separator: "\n")
    }

    func line(at time: TimeInterval) -> Int? {
        guard isSynced, !lines.isEmpty else { return nil }
        var index = 0
        for (i, line) in lines.enumerated() where line.time <= time + 0.05 {
            index = i
        }
        return index
    }
}

enum LyricsParser {
    private static let timePattern = #"\[(\d{1,2}):(\d{2})(?:\.(\d{1,3}))?\]"#

    static func parse(_ content: String) -> ParsedLyrics {
        var metadata: [String: String] = [:]
        var timed: [LyricLine] = []
        var untimed: [String] = []

        let normalized = content
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")

        for rawLine in normalized.components(separatedBy: "\n") {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty else { continue }

            if let tag = parseTag(line) {
                metadata[tag.key] = tag.value
                continue
            }

            let (times, text) = extractTimes(from: line)
            let cleaned = text.trimmingCharacters(in: .whitespaces)
            guard !cleaned.isEmpty else { continue }

            if times.isEmpty {
                untimed.append(cleaned)
            } else {
                for t in times {
                    timed.append(LyricLine(time: t, text: cleaned))
                }
            }
        }

        let lines: [LyricLine]
        if timed.isEmpty {
            lines = untimed.enumerated().map { LyricLine(time: 0, text: $0.element) }
        } else {
            lines = timed.sorted { $0.time < $1.time }
        }

        return ParsedLyrics(lines: lines, metadata: metadata)
    }

    private static func parseTag(_ line: String) -> (key: String, value: String)? {
        guard line.hasPrefix("["), line.hasSuffix("]") else { return nil }
        let inner = String(line.dropFirst().dropLast())
        guard let colon = inner.firstIndex(of: ":") else { return nil }
        let key = String(inner[..<colon]).lowercased()
        let value = String(inner[inner.index(after: colon)...])
        guard ["ti", "ar", "al", "by", "offset"].contains(key) else { return nil }
        return (key, value)
    }

    private static func extractTimes(from line: String) -> ([TimeInterval], String) {
        guard let regex = try? NSRegularExpression(pattern: timePattern) else {
            return ([], line)
        }
        let ns = line as NSString
        let matches = regex.matches(in: line, range: NSRange(location: 0, length: ns.length))
        var times: [TimeInterval] = []
        for match in matches {
            guard match.numberOfRanges >= 3 else { continue }
            let min = ns.substring(with: match.range(at: 1))
            let sec = ns.substring(with: match.range(at: 2))
            var fraction: Double = 0
            if match.numberOfRanges > 3, match.range(at: 3).location != NSNotFound {
                let fracStr = ns.substring(with: match.range(at: 3))
                let divisor = pow(10.0, Double(fracStr.count))
                fraction = (Double(fracStr) ?? 0) / divisor
            }
            let t = (Double(min) ?? 0) * 60 + (Double(sec) ?? 0) + fraction
            times.append(t)
        }
        var text = regex.stringByReplacingMatches(
            in: line,
            range: NSRange(location: 0, length: ns.length),
            withTemplate: ""
        )
        text = text.trimmingCharacters(in: .whitespaces)
        return (times, text)
    }
}
