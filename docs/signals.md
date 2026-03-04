---
sidebar_position: 8
---

# Signals

DocumentService provides 5 signals:
UpdatedSignal, OpenedSignal, ReadSignal, ClosedSignal, CacheChangedSignal.

These signals allow you to wait for a document to be open before modifying it or
to tap into cache changes (e.g. for replication), for example. They also
implement the Once and cancellation functionality through `:Once` and `:Disconnect`.

They are implemented with sleitnick signals, so listeners are wrapped in a task.spawn
and hence will run immediately (and before the method returns), until a yield
is encountered, and will run in reverse order to the order they are added.