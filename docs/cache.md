---
sidebar_position: 7
---

# Updating a player's data through cache

Most of the time, you'll want to update player data like this:

```lua
local data = table.clone(document:GetCache())
data.Points += points
document:SetCache(newData)
```

For Robux transactions remember to call `Save` to ensure they save!