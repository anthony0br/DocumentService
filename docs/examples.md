---
sidebar_position: 3
---
 
 # Examples

 ## Opening a document for a player with error handling & lock stealing
 ```lua
    local document = store:GetDocument(tostring(player.UserId))
    local result = document:Open()

    if not result.success and result.reason == "SessionLockedError" then
        document:Steal()
        result = document:Open()
    end

    if not result.success then
        if result.reason == "BackwardsCompatibilityError" then
            player:Kick(
                "You joined an old server which does not support your saved data."
                    .. "Please try joining another server. If this persists, contact a developer."
            )
        end

        if result.reason == "RobloxAPIError" then
            player:Kick("Failed to load data due to a Roblox service issue. Try again later.")
        end

        player:Kick(
            `Failed to load data: {result.reason}. Please screenshot this message and report it to a developer.`
        )

        return false
    end
```

You should close documents when a player leaves. Note that I have not created a player documents table.
You should use `:GetDocument` to retrieve the document - there is usually no need to create a table to
reference your player documents. See the API reference for `GetDocument` for information on when documents are
garbage collected.

 ## Developer Products