import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import XCTest
@testable import FlashyCore

final class StatsTests: XCTestCase {
    let today = StudyDay(100)

    func outcomes(_ pairs: [(Int, DayOutcome)]) -> [StudyDay: DayOutcome] {
        Dictionary(uniqueKeysWithValues: pairs.map { (today.adding($0.0), $0.1) })
    }

    func testStreakSkipsEmptyDaysAndBreaksOnMissed() {
        let streak = Stats.streak(outcomes: outcomes([
            (-7, .cleared), (-6, .cleared), (-5, .cleared),
            (-4, .missed),
            (-3, .cleared), (-2, .empty), (-1, .cleared),
        ]), today: today)
        XCTAssertEqual(streak.current, 2)
        XCTAssertEqual(streak.longest, 3)
    }

    func testTodayInProgressDoesNotBreakStreak() {
        XCTAssertEqual(Stats.streak(outcomes: outcomes([(-1, .cleared)]), today: today).current, 1)
        XCTAssertEqual(Stats.streak(outcomes: outcomes([(-1, .cleared), (0, .cleared)]), today: today).current, 2)
        XCTAssertEqual(Stats.streak(outcomes: outcomes([(-2, .cleared)]), today: today).current, 0, "unrecorded past day breaks")
        XCTAssertEqual(Stats.streak(outcomes: [:], today: today).current, 0)
    }

    func testPendingOutcomes() {
        let pending = Stats.pendingOutcomes(
            after: today.adding(-4),
            before: today,
            recorded: [today.adding(-2)],
            wasAnythingDue: { $0 == today.adding(-3) }
        )
        XCTAssertEqual(pending, outcomes([(-3, .missed), (-1, .empty)]))
    }

    func testRatingsByDayAndRetention() {
        let events = [
            ReviewEvent(cardID: "a", day: today, rating: .good),
            ReviewEvent(cardID: "b", day: today, rating: .bad),
            ReviewEvent(cardID: "c", day: today.adding(-2), rating: .okay),
            ReviewEvent(cardID: "d", day: today.adding(-9), rating: .bad),
        ]
        let days = Stats.ratingsByDay(events, in: today.adding(-2)...today)
        XCTAssertEqual(days.map(\.total), [1, 0, 2])
        XCTAssertEqual(days[2][.bad], 1)
        XCTAssertEqual(Stats.retention(events), 0.5)
        XCTAssertNil(Stats.retention([]))

        let series = Stats.retentionSeries(events, in: today.adding(-13)...today, bucketDays: 7)
        XCTAssertEqual(series.map(\.retention), [0.0, 2.0 / 3.0])
    }

    func testMaturityAndCategoryAccuracy() {
        let counts = Stats.maturityCounts([.new, Schedule(intervalDays: 3, dueDay: today), Schedule(intervalDays: 21, dueDay: today)])
        XCTAssertEqual(counts, [.new: 1, .learning: 1, .mature: 1])

        let accuracy = Stats.categoryAccuracy([
            ReviewEvent(cardID: "bio/a", day: today, rating: .good),
            ReviewEvent(cardID: "chem/b", day: today, rating: .bad),
            ReviewEvent(cardID: "chem/b", day: today, rating: .good),
            ReviewEvent(cardID: "deleted", day: today, rating: .bad),
        ], categoryOf: { $0 == "deleted" ? nil : [String($0.split(separator: "/")[0])] })
        XCTAssertEqual(accuracy.map(\.categoryPath), [["chem"], ["bio"]])
        XCTAssertEqual(accuracy[0].accuracy, 0.5)
    }
}

final class GitHubClientTests: XCTestCase {
    final class FakeTransport: HTTPTransport, @unchecked Sendable {
        var responses: [String: (Int, String, [String: String])] = [:]
        var requests: [URLRequest] = []

        func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
            requests.append(request)
            let url = request.url!.absoluteString
            let (status, body, headers) = responses[url] ?? (404, "", [:])
            return (Data(body.utf8), HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: headers)!)
        }
    }

    let commitURL = "https://api.github.com/repos/zlang19/Flashy/commits/main"

    func testHeadChangedAndUnchanged() async throws {
        let transport = FakeTransport()
        let client = GitHubClient(transport: transport)

        transport.responses[commitURL] = (200, "abc123\n", ["ETag": "\"e1\""])
        let changed = try await client.head(etag: nil)
        XCTAssertEqual(changed, .changed(sha: "abc123", etag: "\"e1\""))
        XCTAssertNil(transport.requests[0].value(forHTTPHeaderField: "If-None-Match"))

        transport.responses[commitURL] = (304, "", [:])
        let unchanged = try await client.head(etag: "\"e1\"")
        XCTAssertEqual(unchanged, .unchanged)
        XCTAssertEqual(transport.requests[1].value(forHTTPHeaderField: "If-None-Match"), "\"e1\"")
    }

    func testRateLimit() async {
        let transport = FakeTransport()
        transport.responses[commitURL] = (403, "", ["X-RateLimit-Remaining": "0", "X-RateLimit-Reset": "1000"])
        do {
            _ = try await GitHubClient(transport: transport).head(etag: nil)
            XCTFail("expected rate limit error")
        } catch {
            XCTAssertEqual(error as? GitHubError, .rateLimited(resetsAt: Date(timeIntervalSince1970: 1000)))
        }
    }

    func testTreeKeepsOnlyBlobs() async throws {
        let transport = FakeTransport()
        transport.responses["https://api.github.com/repos/zlang19/Flashy/git/trees/abc?recursive=1"] = (200, """
        {"sha":"abc","truncated":false,"tree":[
          {"path":"flashcards","type":"tree","sha":"t1","mode":"040000"},
          {"path":"flashcards/a/flashcard.md","type":"blob","sha":"b1","mode":"100644","size":10}
        ]}
        """, [:])
        let result = try await GitHubClient(transport: transport).files(at: "abc")
        XCTAssertEqual(result.files, [RemoteFile(path: "flashcards/a/flashcard.md", sha: "b1")])
        XCTAssertFalse(result.truncated)
    }

    func testRawPathIsPercentEncoded() async throws {
        let transport = FakeTransport()
        transport.responses["https://raw.githubusercontent.com/zlang19/Flashy/abc/flashcards/my%20card/a%23b.png"] = (200, "PNG", [:])
        let data = try await GitHubClient(transport: transport).contents(of: "flashcards/my card/a#b.png", at: "abc")
        XCTAssertEqual(String(data: data, encoding: .utf8), "PNG")
    }
}
