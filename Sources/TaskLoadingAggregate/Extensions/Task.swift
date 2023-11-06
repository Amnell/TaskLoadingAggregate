//
//  Task.swift
//
//
//  Created by Mathias Amnell on 2022-07-27.
//

import SwiftUI
import Combine

extension Task {

    @discardableResult
    /// Track the running state of the task supplying a `TaskLoadingAggregate`
    /// The `TaskLoadingAggregate` aggregates all tasks loading states into one.
    /// You can then check the loading state in `TaskLoadingAggregate.isLoading`
    /// - Parameter aggregate: A loading aggregate that keeps track of the loading state.
    /// - Returns: Returns the original task, for you to use as you like.
    public func track(_ aggregate: TaskLoadingAggregate) -> Self {
        Task<Void, Never> {
            await aggregate.increment()

            _ = try? await self.value

            await aggregate.decrement()
        }

        return self
    }
}
