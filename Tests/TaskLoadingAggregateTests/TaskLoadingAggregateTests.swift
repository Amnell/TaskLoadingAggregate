import XCTest
import Combine
@testable import TaskLoadingAggregate

@MainActor
final class ConcurrencyActivityTests: XCTestCase {
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        cancellables = []
    }

    func testLoadingAggregateLifecycle() {
        let loadingAggregate = TaskLoadingAggregate()

        addTeardownBlock { [weak loadingAggregate] in
            XCTAssertNil(loadingAggregate, "Object should be deallocated. Detected memory leak.")
        }
    }

    func testExample() async throws {
        let loadingAggregate = TaskLoadingAggregate()

        var trueCount: Int = 0
        var falseCount: Int = 0

        let expectedTrueCount: Int = 1
        let expectedFalseCount: Int = 2

        let trueCountExpectation = expectation(description: "isLoading should be true once")
        let falseCountExpectation = expectation(description: "isLoading should be false twice")

        loadingAggregate.$isLoading
            .sink { isLoading in
                XCTAssertTrue(Thread.isMainThread)
                if isLoading {
                    trueCount += 1

                    if trueCount == expectedTrueCount {
                        trueCountExpectation.fulfill()
                    }

                    XCTAssertTrue(trueCount <= expectedTrueCount)
                }

                if !isLoading {
                    falseCount += 1

                    if falseCount == expectedFalseCount, !isLoading {
                        falseCountExpectation.fulfill()
                    }

                    XCTAssertTrue(falseCount <= expectedFalseCount)
                }
            }
            .store(in: &cancellables)

        // Kick off two tasks
        let longRunningThrowingTask = throwingTask(delay: 1)
        let longRunningTask = task(delay: 1)

        // Start tracking both
        longRunningTask.track(loadingAggregate)
        longRunningThrowingTask.track(loadingAggregate)

        longRunningThrowingTask.cancel()

        addTeardownBlock { [weak loadingAggregate] in
            XCTAssertNil(loadingAggregate, "Object should be deallocated. Detected memory leak.")
        }

        await fulfillment(of: [trueCountExpectation, falseCountExpectation], timeout: 4)
    }

    func testCancellingDecrementsLoading() async throws {
        let loadingAggregate = TaskLoadingAggregate()
        let task = task(delay: 5).track(loadingAggregate)

        let isLoadingTrueExpectation = expectation(description: "Loading aggregate should be loading")
        let isLoadingFalseExpectation = expectation(description: "Loading aggregate should NOT be loading")

        Task {
            try await Task.sleep(nanoseconds: UInt64(0.01 * 1e+9))

            if loadingAggregate.isLoading {
                isLoadingTrueExpectation.fulfill()
            }

            task.cancel()

            try await Task.sleep(nanoseconds: UInt64(0.1 * 1e+9))

            if !loadingAggregate.isLoading {
                isLoadingFalseExpectation.fulfill()
            }
        }

        await fulfillment(of: [isLoadingTrueExpectation, isLoadingFalseExpectation], timeout: 2)
    }

    // MARK: - Helpers

    func throwingTask(delay: TimeInterval) -> Task<Void, Error> {
        Task {
            print("🟢 longRunningThrowingTask")
            do {
                try await Task.sleep(nanoseconds: UInt64(delay * 1e+9))
                try Task.checkCancellation()
            } catch {
                print("🔴 longRunningThrowingTask", error)
                throw error
            }
            print("🔴 longRunningThrowingTask")
        }
    }

    func task(delay: TimeInterval) -> Task<Void, Never> {
        Task {
            print("🟢 longRunningTask")
            do {
                try await Task.sleep(nanoseconds: UInt64(1 * 1e+9))
                try Task.checkCancellation()
            } catch {
                print("🔴 longRunningTask", error)
            }
            print("🔴 longRunningTask")
        }
    }

    func asyncMethod(delay: TimeInterval) async {
        print("🟢 longRunningTask")
        do {
            try await Task.sleep(nanoseconds: UInt64(1 * 1e+9))
            try Task.checkCancellation()
        } catch {
            print("🔴 longRunningTask", error)
        }
        print("🔴 longRunningTask")
    }
}
