# DocumentService

## Goals
- Fully strictly typed, working now: DocumentService is fully strictly typed, including internally and the public API, and checks types at runtime.
- Adaptable with hooks. For example, these can be used for automated logging.
- Few dependencies and simple API: DocumentService will not lock you into using a specific implementation of Promise or Future. Instead, it just yields when it needs to, and lets you implement your own async behaviour.
- Transaction based API as the core, auto-saving for rapidly changing data can be added on later
- Safe transactions involving multiple keys (e.g. trades)
- Automatic retry
- Optional session-locking - this can be turned off easily (e.g. for modifying data about groups)
- Lets you use your own async handlers - I recommend Redblox Futures.

## Non-goals:
- Caching. I don't intend (yet) to re-implement the features of every existing DataStore library which provide a table that is auto-saved and saved on close is not a priority, and this wouldn't work for documents that aren't session locked. For now, if you need to cache just do it yourself: call Update periodically and on close.
- Queue transactions. UpdateAsync apparently garuantees the order of transactions.
- Make Promises. We can't type check these, yet, so I want to provide the option to use other async handling methods.

If you think I could achieve these goals better please open an Issue or contact me!