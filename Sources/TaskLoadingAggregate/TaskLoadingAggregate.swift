//
//  TaskLoadingAggregate.swift
//  
//
//  Created by Mathias Amnell on 2022-07-27.
//

import Foundation
import Combine

public class TaskLoadingAggregate: ObservableObject {

    // MARK: - Public

    @Published public private(set) var isLoading: Bool = false

    // MARK: - Private

    @Published private var relay: Int = 0
    private let lock = NSRecursiveLock()
    private var cancellable: AnyCancellable?

    // MARK: - Initialization

    public init() {
        cancellable = $relay
            .map { $0 > 0 }
            .removeDuplicates()
            .assignWeakly(to: \.isLoading, on: self)
    }

    // MARK: - Private functions

    public func increment() {
        lock.lock()
        relay += 1
        lock.unlock()
    }

    public func decrement() {
        lock.lock()
        // Never let it go below zero
        if relay > 0 {
            relay -= 1
        }
        lock.unlock()
    }
}
