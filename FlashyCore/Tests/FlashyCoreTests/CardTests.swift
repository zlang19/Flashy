import Foundation
import XCTest
@testable import FlashyCore

final class CardParserTests: XCTestCase {
    func fixture(_ name: String) throws -> String {
        let url = Bundle.module.resourceURL!.appendingPathComponent("Fixtures/\(name)/flashcard.md")
        return try String(contentsOf: url, encoding: .utf8)
    }

    func testBasicCard() throws {
        let card = try CardParser.parse(fixture("basic"))
        XCTAssertEqual(card.title, "Krebs cycle")
        XCTAssertEqual(card.tags, ["biology", "metabolism"])
        XCTAssertEqual(card.front, "![Cycle diagram](cycle.png)\nWhat molecule enters the cycle?")
        XCTAssertTrue(card.back.hasPrefix("**Acetyl-CoA**"))
        XCTAssertTrue(card.back.hasSuffix("mitochondrial matrix"))
    }

    func testBlockListTagsQuotedTitleAndCaseInsensitiveHeadings() throws {
        let card = try CardParser.parse(fixture("frontmatter_list"))
        XCTAssertEqual(card.title, "Quoted: title")
        XCTAssertEqual(card.tags, ["one", "two"])
        XCTAssertEqual(card.front, "Question")
        XCTAssertEqual(card.back, "Answer")
    }

    func testMissingBack() {
        XCTAssertThrowsError(try CardParser.parse(fixture("missing_back"))) {
            XCTAssertEqual($0 as? CardParseError, .missingSection("Back"))
        }
    }

    func testHeadingInsideCodeFenceIsContent() throws {
        let card = try CardParser.parse(fixture("fenced_heading"))
        XCTAssertTrue(card.front.contains("```markdown\n## Back\n```"))
        XCTAssertEqual(card.back, "A literal `## Back` heading.")
    }

    func testNoFrontmatterAndWindowsLineEndings() throws {
        let card = try CardParser.parse("## Front\r\nQ\r\n## Back\r\nA\r\n")
        XCTAssertNil(card.title)
        XCTAssertEqual(card.tags, [])
        XCTAssertEqual(card.front, "Q")
        XCTAssertEqual(card.back, "A")
    }

    func testErrors() {
        XCTAssertThrowsError(try CardParser.parse("---\ntitle: x\n## Front\nQ\n## Back\nA")) {
            XCTAssertEqual($0 as? CardParseError, .unterminatedFrontmatter)
        }
        XCTAssertThrowsError(try CardParser.parse("---\nnot yaml\n---\n## Front\nQ\n## Back\nA")) {
            XCTAssertEqual($0 as? CardParseError, .invalidFrontmatterLine(line: 2, text: "not yaml"))
        }
        XCTAssertThrowsError(try CardParser.parse("## Front\n\n## Back\nA")) {
            XCTAssertEqual($0 as? CardParseError, .emptySection("Front"))
        }
        XCTAssertThrowsError(try CardParser.parse("## Front\nQ\n## Back\nA\n## Front\nQ2")) {
            XCTAssertEqual($0 as? CardParseError, .duplicateSection("Front"))
        }
    }
}

final class CardMarkdownTests: XCTestCase {
    func testBlocks() {
        let markdown = """
        # Title
        Some **bold**
        continued line.

        ![alt](img.png "caption") trailing text

        - one
          - nested
        2. second

        > quoted
        > more

        ```
        let x = 1
        ```
        ---
        """
        XCTAssertEqual(CardMarkdown.blocks(from: markdown), [
            .heading(level: 1, text: "Title"),
            .paragraph("Some **bold**\ncontinued line."),
            .image(alt: "alt", source: "img.png"),
            .paragraph("trailing text"),
            .listItem(marker: .bullet, indent: 0, text: "one"),
            .listItem(marker: .bullet, indent: 1, text: "nested"),
            .listItem(marker: .number(2), indent: 0, text: "second"),
            .quote("quoted\nmore"),
            .code("let x = 1"),
            .rule,
        ])
    }

    func testImageSources() {
        XCTAssertEqual(CardMarkdown.imageSources(in: "![a](x.png) and ![b](<sub dir/y.png>)"), ["x.png", "sub dir/y.png"])
    }

    func testResolve() {
        let dir = "flashcards/bio/krebs"
        XCTAssertEqual(CardMarkdown.resolve("cycle.png", cardDirectory: dir), "flashcards/bio/krebs/cycle.png")
        XCTAssertEqual(CardMarkdown.resolve("./img/a%20b.png", cardDirectory: dir), "flashcards/bio/krebs/img/a b.png")
        XCTAssertEqual(CardMarkdown.resolve("../shared.png", cardDirectory: dir), "flashcards/bio/shared.png")
        XCTAssertEqual(CardMarkdown.resolve("https://x.com/a.png", cardDirectory: dir), "https://x.com/a.png")
        XCTAssertNil(CardMarkdown.resolve("../../../../x.png", cardDirectory: dir))
    }
}

final class RepoLayoutTests: XCTestCase {
    func file(_ path: String, _ sha: String = "s") -> RemoteFile {
        RemoteFile(path: path, sha: sha)
    }

    func testFindsCardsAtAnyDepth() {
        let cards = RepoLayout.cards(in: [
            file("README.md"),
            file("flashcards/README.md"),
            file("flashcards/loose/flashcard.md"),
            file("flashcards/bio/cells/mitosis/flashcard.md"),
            file("flashcards/bio/cells/mitosis/phases.png"),
            file("flashcards/bio/cells/mitosis/img/detail.png"),
            file("flashcards/bio/cells/mitosis/inner/flashcard.md"),
            file("flashcards/bio/notes.txt"),
            file("templates/card/flashcard.md"),
        ])
        XCTAssertEqual(cards.map(\.id), ["bio/cells/mitosis", "loose"])

        let mitosis = cards[0]
        XCTAssertEqual(mitosis.categoryPath, ["bio", "cells"])
        XCTAssertEqual(mitosis.folderName, "mitosis")
        XCTAssertEqual(mitosis.markdownPath, "flashcards/bio/cells/mitosis/flashcard.md")
        XCTAssertEqual(mitosis.files.count, 4, "nested card folder belongs to the outer card")
        XCTAssertEqual(cards[1].categoryPath, [])
    }

    func testContentHashTracksAnyFileChange() {
        let before = RepoLayout.cards(in: [file("flashcards/a/flashcard.md", "1"), file("flashcards/a/x.png", "1")])
        let image = RepoLayout.cards(in: [file("flashcards/a/flashcard.md", "1"), file("flashcards/a/x.png", "2")])
        let same = RepoLayout.cards(in: [file("flashcards/a/x.png", "1"), file("flashcards/a/flashcard.md", "1")])
        XCTAssertNotEqual(before[0].contentHash, image[0].contentHash)
        XCTAssertEqual(before[0].contentHash, same[0].contentHash)
    }

    func testNaming() {
        XCTAssertEqual(Naming.prettify("organic_chemistry"), "Organic Chemistry")
        XCTAssertEqual(Naming.prettify("dna-replication"), "Dna Replication")
        XCTAssertEqual(Naming.breadcrumb(["bio", "cells"]), "Bio › Cells")
        XCTAssertEqual(Naming.breadcrumb([]), "Uncategorized")
    }

    func testCategoryTree() {
        let tree = CategoryNode.build([
            (id: "loose", categoryPath: []),
            (id: "bio/a", categoryPath: ["bio"]),
            (id: "bio/cells/b", categoryPath: ["bio", "cells"]),
            (id: "chem/c", categoryPath: ["chem"]),
        ])
        XCTAssertEqual(tree.cardIDs, ["loose"])
        XCTAssertEqual(tree.children.map(\.name), ["Bio", "Chem"])
        XCTAssertEqual(tree.node(at: ["bio"])?.allCardIDs, ["bio/a", "bio/cells/b"])
        XCTAssertEqual(tree.node(at: ["bio", "cells"])?.cardIDs, ["bio/cells/b"])
        XCTAssertNil(tree.node(at: ["nope"]))
    }

    func testSyncPlan() {
        let plan = SyncPlan(
            remote: [file("a", "1"), file("b", "2"), file("c", "3")],
            local: ["a": "1", "b": "old", "gone": "9"]
        )
        XCTAssertEqual(plan.toDownload.map(\.path), ["b", "c"])
        XCTAssertEqual(plan.toDelete, ["gone"])
        XCTAssertTrue(SyncPlan(remote: [file("a", "1")], local: ["a": "1"]).isEmpty)
    }
}
