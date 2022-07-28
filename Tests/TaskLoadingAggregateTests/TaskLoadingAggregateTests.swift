import XCTest
import Combine
@testable import TaskLoadingAggregate

final class ConcurrencyActivityTests: XCTestCase {
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        cancellables = []
    }

    func testLoadingManagerLifecycle() {
        let loadingManager = TaskLoadingAggregate()

        addTeardownBlock { [weak loadingManager] in
            XCTAssertNil(loadingManager, "Object should be deallocated. Detected memory leak.")
        }
    }

    func testExample() async throws {
        let loadingManager = TaskLoadingAggregate()

        var trueCount: Int = 0
        var falseCount: Int = 0

        let expectedTrueCount: Int = 1
        let expectedFalseCount: Int = 2

        let trueCountExpectation = expectation(description: "isLoading should be true once")
        let falseCountExpectation = expectation(description: "isLoading should be false twice")

        loadingManager.$isLoading
            .sink { isLoading in
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
        longRunningTask.track(loadingManager)
        longRunningThrowingTask.track(loadingManager)

        longRunningThrowingTask.cancel()

        addTeardownBlock { [weak loadingManager] in
            XCTAssertNil(loadingManager, "Object should be deallocated. Detected memory leak.")
        }

        await waitForExpectations(timeout: 4)
    }

    func testCancellingDecrementsLoading() async throws {
        let loadingManager = TaskLoadingAggregate()
        let task = task(delay: 5).track(loadingManager)

        let isLoadingTrueExpectation = expectation(description: "Loading manager should be loading")
        let isLoadingFalseExpectation = expectation(description: "Loading manager should NOT be loading")

        Task {
            try await Task.sleep(nanoseconds: UInt64(0.01 * 1e+9))

            if loadingManager.isLoading {
                isLoadingTrueExpectation.fulfill()
            }

            task.cancel()

            try await Task.sleep(nanoseconds: UInt64(0.1 * 1e+9))

            if !loadingManager.isLoading {
                isLoadingFalseExpectation.fulfill()
            }
        }

        await waitForExpectations(timeout: 2)
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
