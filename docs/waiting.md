---
sidebar_position: 7
---

# Waiting for a Document to open

A common question I am asked is how to wait for a document to open (on a different
thread to the one which called `:Open`)
This is how I do that currently:

```lua
local thread = coroutine.running()

if not document:IsOpen() then
    document:OnceAfter("Open", function()
        task.defer(thread)
    end)
    coroutine.yield()
end
```