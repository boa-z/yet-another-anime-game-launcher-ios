import Foundation

nonisolated enum DesktopCommandBuilder {
    static func build(
        _ command: [DesktopCommandSegment],
        environment: [(key: String, value: String)] = []
    ) -> String {
        environmentPrefix(environment) + command
            .map(render)
            .joined(separator: " ")
    }

    static func build(
        _ command: [String],
        environment: [(key: String, value: String)] = []
    ) -> String {
        build(command.map { .string($0) }, environment: environment)
    }

    static func buildEnvironment(_ environment: [(key: String, value: String)]) -> String {
        environmentPrefix(environment).trimmingCharacters(in: .whitespaces)
    }

    static func sanitize(_ value: String) -> String {
        var sanitized = ""
        for character in value {
            switch character {
            case "\\":
                sanitized += "\\\\"
            case " ":
                sanitized += "\\ "
            case "\"":
                sanitized += "\\\""
            case "'":
                sanitized += "\\'"
            case "&":
                sanitized += "\\&"
            case "#":
                sanitized += "\\#"
            case "~":
                sanitized += "\\~"
            case "`":
                sanitized += "\\`"
            case "|":
                sanitized += "\\|"
            case "[":
                sanitized += "\\["
            case "]":
                sanitized += "\\]"
            case "<":
                sanitized += "\\<"
            case ">":
                sanitized += "\\>"
            case "{":
                sanitized += "\\{"
            case "}":
                sanitized += "\\}"
            case "*":
                sanitized += "\\*"
            case "$":
                sanitized += "\\$"
            case "(":
                sanitized += "\\("
            case ")":
                sanitized += "\\)"
            case ";":
                sanitized += "\\;"
            case "\n":
                sanitized += "\\\\n"
            case "\t":
                sanitized += "\\\\t"
            default:
                sanitized.append(character)
            }
        }
        return sanitized
    }

    private static func render(_ segment: DesktopCommandSegment) -> String {
        switch segment {
        case .string(let value):
            sanitize(value)
        case .raw(let value):
            value
        case .nested(let nestedCommand):
            "$(\(build(nestedCommand)))"
        }
    }

    private static func environmentPrefix(_ environment: [(key: String, value: String)]) -> String {
        environment
            .filter { !$0.value.isEmpty }
            .map { "\($0.key)=\(sanitize($0.value)) " }
            .joined()
    }
}
