
# TaskLoadingAggregate

### *Track your Swift Concurrency Tasks activity in an aggregate with ease.*

## 📄 Description
Swift's Concurrency makes working with asynchronous tasks through async/await a breeze. Hooking up a loading state for one task is just as easy. But what if you have multiple tasks running? Tracking one single loading state in those cases is a bit harder.

### Introducing `TaskLoadingAggregate` 🎉

TaskLoadingAggregate makes this a breeze by creating a loading state aggregate for your tasks. Each tracked task will report their status to the aggregate and as long as a task is loading the aggregate will report `isLoading` as `true`.

## 🎮 Usage

Hooking up a task to a TaskLoadingAggregate is as simple as:

``` swift
let loadingAggregate = TaskLoadingAggregate()

// First task
Task {
    try await doSomething()
}.track(loadingAggregate)

// Second task
Task {
    try await doSomethingElse()
}.track(loadingAggregate)

// You can now bind your UI or whatever to loadingAggregate's @Published isLoading property 🚀
ActivityIndicator(isAnimating: loadingAggregate.isLoading, style: .large)

// And as @Published is a `Published<Bool>` you can use Combine to do whatever:
loadingAggregate.$isLoading
    .sink { isLoading in
        if isLoading {
            doSomething()
        } else {
            doSomethingElse()
        }
    }
    .store(in: &cancellables)
```

#### Q: *Is this only for `Task`?*

No, you can use a TaskLoadingAggregate however you like, but then it is up to you to increment and decrement the aggregates loading counter:

``` swift
let loadingAggregate = TaskLoadingAggregate()

// In async function
func doSomething() async {
    loadingAggregate.increment()
    await doSomethingElse()
    loadingAggregate.decrement()
}

// In classic closure
loadingAggregate.increment()
self.doSomething(completion: {
    loadingAggregate.decrement()
})
```

## 😋 Who cooked it?

[![@amnell][twitter-image]](https://twitter.com/amnell) [![amnell][github-image]](https://github.com/amnell)

## ⚖️ License

**TaskLoadingAggregate** is generously distributed under the *[MIT](https://opensource.org/licenses/MIT)*.

<!-- GitHub's Markdown reference links -->
[twitter-image]: https://img.shields.io/badge/Twitter-1DA1F2?style=for-the-badge&logo=twitter&logoColor=white
[github-image]: https://img.shields.io/badge/GitHub-100000?style=for-the-badge&logo=github&logoColor=white

<!-- README generated with: https://github.com/pH-7/cool-readme-generator -->
