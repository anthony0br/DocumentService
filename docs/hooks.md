---
sidebar_position: 8
---

# Hooks

To listen to and respond to events, like saving or reading data, DocumentService
has a hooks API: `HookBefore`, `HookAfter`, `OnceBefore`, and `OnceAfter`.

Hooks run sequentially in the order they are added, and generally, should not
yield.

`HookBefore` and `HookAfter` return a cancel function. This will clean up the
hook and stop it from running again in response to any future events. Note that
once an event happens, the sequence of hooks to run is fixed and cannot be changed
for while the hooks are running for that particular event.