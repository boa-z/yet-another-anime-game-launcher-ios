import XCTest
@testable import YaaglIOS

final class DesktopCommandBuilderTests: XCTestCase {
    func testBuildMatchesDesktopCommandBuilderForSimpleCommands() {
        XCTAssertEqual(DesktopCommandBuilder.build(["echo"]), "echo")
        XCTAssertEqual(
            DesktopCommandBuilder.build(["/usr/bin/folder with space/command"]),
            "/usr/bin/folder\\ with\\ space/command"
        )
        XCTAssertEqual(DesktopCommandBuilder.build(["echo", "Hello"]), "echo Hello")
        XCTAssertEqual(DesktopCommandBuilder.build(["echo", "Hello World"]), "echo Hello\\ World")
    }

    func testBuildEscapesDesktopShellSpecialCharacters() {
        let literal = "Hello '&_#`~[]<>| World"

        XCTAssertEqual(
            DesktopCommandBuilder.build(["echo", literal]),
            "echo Hello\\ \\'\\&_\\#\\`\\~\\[\\]\\<\\>\\|\\ World"
        )
    }

    func testBuildLeavesQuotedStringsAsLiteralArguments() {
        XCTAssertEqual(
            DesktopCommandBuilder.build(["echo", "\"Hello World\""]),
            "echo \\\"Hello\\ World\\\""
        )
        XCTAssertEqual(
            DesktopCommandBuilder.build(["echo", "\"Hello \" World\""]),
            "echo \\\"Hello\\ \\\"\\ World\\\""
        )
    }

    func testBuildEscapesSubshellSyntaxUnlessNestedSegmentIsUsed() {
        XCTAssertEqual(
            DesktopCommandBuilder.build(["echo", "Hello $(echo World)"]),
            "echo Hello\\ \\$\\(echo\\ World\\)"
        )
        XCTAssertEqual(
            DesktopCommandBuilder.build([
                .string("echo"),
                .nested([.string("echo"), .string("Hello World")])
            ]),
            "echo $(echo Hello\\ World)"
        )
    }

    func testBuildMatchesDesktopNestedContextsWithoutExecutingThem() {
        let command = DesktopCommandBuilder.build(["echo", "Hello World"])

        XCTAssertEqual(
            DesktopCommandBuilder.build(["eval", command]),
            "eval echo\\ Hello\\\\\\ World"
        )
        XCTAssertEqual(
            DesktopCommandBuilder.build(["sh", "-c", command]),
            "sh -c echo\\ Hello\\\\\\ World"
        )
        XCTAssertEqual(
            DesktopCommandBuilder.build([
                .string("echo"),
                .nested([.string("echo"), .string("Hello\\ World")])
            ]),
            "echo $(echo Hello\\\\\\ World)"
        )
    }

    func testBuildMatchesDesktopOSAScriptEmbeddingWithoutExecutingIt() {
        let command = DesktopCommandBuilder.build(["echo", "Hello World"])
        let escapedForAppleScript = command.replacing("\\", with: "\\\\")
        let appleScript = [
            "do",
            "shell",
            "script",
            "\"\(escapedForAppleScript)\""
        ].joined(separator: " ")

        XCTAssertEqual(
            DesktopCommandBuilder.build(["osascript", "-e", appleScript]),
            "osascript -e do\\ shell\\ script\\ \\\"echo\\ Hello\\\\\\\\\\ World\\\""
        )
    }

    func testBuildSupportsRawSegmentsForPipes() {
        XCTAssertEqual(
            DesktopCommandBuilder.build([
                .string("echo"),
                .string("Hello '&_#`~[]<>| World"),
                .rawString("|"),
                .string("base64")
            ]),
            "echo Hello\\ \\'\\&_\\#\\`\\~\\[\\]\\<\\>\\|\\ World | base64"
        )
    }

    func testBuildPrefixesNonEmptyEnvironmentVariablesInOrder() {
        let literal = "Hello '&_#`~[]<>| World"

        XCTAssertEqual(
            DesktopCommandBuilder.build(
                ["node", "-e", "console.log(process.env.CCCENV)"],
                environment: [
                    (key: "CCCENV", value: literal),
                    (key: "EMPTY_ENV", value: "")
                ]
            ),
            "CCCENV=Hello\\ \\'\\&_\\#\\`\\~\\[\\]\\<\\>\\|\\ World node -e console.log\\(process.env.CCCENV\\)"
        )
    }

    func testBuildEscapesNewlinesAndTabsLikeDesktopSanitize() {
        XCTAssertEqual(
            DesktopCommandBuilder.build(["echo", "Line 1\n\tLine 2"]),
            "echo Line\\ 1\\\\n\\\\tLine\\ 2"
        )
    }
}
