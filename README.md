# DocumentService

## Goals
- Fully strictly typed, working now: DocumentService is fully strictly typed, including internally and the public API, and checks types at runtime.
- Adaptable with hooks: these can be used for automated logging, automated retries, migrating data on then re-trying fail to open, and more. 
- Few dependencies and simple API: DocumentService will not lock you into using a specific implementation of Promise or Future. Instead, it just yields when it needs to, and lets you implement your own async behaviour.
- Transaction based API as the core, auto-saving for rapidly changing data can be added on later
- Safe transactions involving multiple keys (e.g. trades)
- Automatic retry
- Session-locking - although this can be turned off (e.g. for modifying data about groups)
- Let's you use your own async handlers - I recommend Redblox Futures.

## What it does not do ():
- Caching. Re-implement the features of every existing DataStore library which provide a table that is auto-saved and saved on close is not a priority, and this wouldn't work for documents that aren't session locked. For now, if you need to cache just do it yourself: call Update periodically and on close.
- Throttling. If you reach limits, you are probably using transactions too frequently. In the future an extended class could be created from Document to enable cacheing and auto-saves (for less important transactions), queueing and throttling. You should ratelimit remotes that call document updates.
- Mock DataStores. I plan to provide an interface and add the ability to inject a different datastore class, but this mock class itself is outside the scope of this project.
- Queue transactions. UpdateAsync apparently garuantees the order of transactions.
- Make Promises.

## Limitations:
- Luau type checking is not perfect

If you think I could achieve these goals better please open an Issue or contact me!