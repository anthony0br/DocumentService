# DocumentService - strictly typed datastores!

DocumentService is a luau library for saving data with Roblox datastores. DocumentStores hold data about an entity.
This project is currently in early stages and should not be used.

DocumentService does not use promises. This enables better type support and allows you to choose which coroutine abstraction you use, if any.

## Features
- Full strict typing
- Data validation and migration
- Simple session locking API
- Run hooks before and after operations, e.g. logging
- Automatic retry with exponential backoff
- Automatically transfers existing 

## Long-term goals
- ACID transactions involving multiple Documents
- Local data with auto-save for session locked data (e.g. ReadLocal and WriteLocal methods)
- Queue and throttle transactions, yielding the thread while queued
