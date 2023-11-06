//
//  Publisher.swift
//  
//
//  Created by Mathias Amnell on 2022-07-27.
//

import Foundation
import Combine

// swiftlint:disable identifier_name
extension Publisher where Failure == Never {
    /// The out-of-the-box assign strongly captures root. This alternative creates a weak reference
    /// minimizing the risk of retain cycles.
    internal func assignWeakly<Root: AnyObject>(to keyPath: ReferenceWritableKeyPath<Root, Output>,
                                                 on root: Root) -> AnyCancellable {
        sink { [weak root] in
            root?[keyPath: keyPath] = $0
        }
    }
}
