---------------------------------------------------------------------
-- ChatCompat.lua  (v3)
-- Abstraction layer for Retail / Classic Chat APIs
--
-- Retail: EditBox pre-hook approach — hooks chat editbox OnKeyDown to
-- modify outgoing text before Enter triggers the secure send path.
-- Never replaces C_ChatInfo.SendChatMessage, preventing taint.
--
-- Classic: Manual table-swap hooks (no taint issues in Classic).
---------------------------------------------------------------------
local MAJOR, MINOR = "ChatCompat", 3
local ChatCompat = LibStub:NewLibrary(MAJOR, MINOR)
if not ChatCompat then return end

---------------------------------------------------------------------
-- State Initialization
---------------------------------------------------------------------
ChatCompat._hooks = ChatCompat._hooks or {}

---------------------------------------------------------------------
-- API Detection
---------------------------------------------------------------------
local function detectApi()
    local hasCChatInfo = type(C_ChatInfo) == "table" and
                             type(C_ChatInfo.SendChatMessage) == "function"
    local hasCClub = type(C_Club) == "table" and type(C_Club.SendMessage) ==
                         "function"
    local supportsInstanceChat =
        ChatTypeInfo and ChatTypeInfo["INSTANCE_CHAT"] ~= nil

    return {
        useCChatInfo = hasCChatInfo,
        useCClub = hasCClub,
        supportsInstanceChat = supportsInstanceChat
    }
end

ChatCompat.api = detectApi()

---------------------------------------------------------------------
-- Hook SendChatMessage  (manual table swap — no AceHook, no taint)
-- Preserves the original across unhook/re-hook cycles.
---------------------------------------------------------------------
function ChatCompat:HookSendChatMessage(addon)
    if self._hooks.sendChatHooked then return end

    -- Capture the true original only once
    if not self._hooks.sendChatOriginal then
        if self.api.useCChatInfo then
            self._hooks.sendChatOriginal = C_ChatInfo.SendChatMessage
        else
            self._hooks.sendChatOriginal = SendChatMessage
        end
    end

    if self.api.useCChatInfo then
        C_ChatInfo.SendChatMessage = function(msg, chatType, language, target)
            return addon:SendChatMessage(msg, chatType, language, target)
        end
    else
        SendChatMessage = function(msg, chatType, language, target)
            return addon:SendChatMessage(msg, chatType, language, target)
        end
    end
    self._hooks.sendChatHooked = true
end

---------------------------------------------------------------------
-- Unhook SendChatMessage  (deterministic restore of original)
---------------------------------------------------------------------
function ChatCompat:UnhookSendChatMessage()
    if not self._hooks.sendChatHooked then return end

    if self.api.useCChatInfo then
        C_ChatInfo.SendChatMessage = self._hooks.sendChatOriginal
    else
        SendChatMessage = self._hooks.sendChatOriginal
    end
    self._hooks.sendChatHooked = false
    -- NOTE: sendChatOriginal is kept for re-hooking later
end

---------------------------------------------------------------------
-- Hook C_Club.SendMessage  (Retail communities)
---------------------------------------------------------------------
function ChatCompat:HookClubSendMessage(addon)
    if not self.api.useCClub then return end
    if self._hooks.clubSendHooked then return end

    if not self._hooks.clubSendOriginal then
        self._hooks.clubSendOriginal = C_Club.SendMessage
    end

    C_Club.SendMessage = function(clubID, streamID, msg)
        return addon:SendMessage(clubID, streamID, msg)
    end
    self._hooks.clubSendHooked = true
end

---------------------------------------------------------------------
-- Unhook C_Club.SendMessage
---------------------------------------------------------------------
function ChatCompat:UnhookClubSendMessage()
    if not self._hooks.clubSendHooked then return end

    C_Club.SendMessage = self._hooks.clubSendOriginal
    self._hooks.clubSendHooked = false
end

---------------------------------------------------------------------
-- Retail: EditBox pre-hook approach
-- Hooks chat editbox OnKeyDown to modify text before Enter triggers the
-- secure send path.  This never replaces C_ChatInfo.SendChatMessage,
-- preventing taint entirely.
-- HookScript does not spread taint per WoW API documentation.
---------------------------------------------------------------------
function ChatCompat:HookChatEditBoxes(addon)
    if self._hooks.editBoxesHooked then return end

    local function hookSingleEditBox(editBox)
        if not editBox or editBox._chatCompatHooked then return end

        -- OnKeyDown fires BEFORE OnEnterPressed for the same key event.
        -- When the user presses Enter, our hook modifies the text in the
        -- editbox.  Blizzard's OnEnterPressed then reads the modified text
        -- and sends it through the untainted, secure API path.
        editBox:HookScript("OnKeyDown", function(eb, key)
            if key ~= "ENTER" and key ~= "NUMPADENTER" then return end
            if not addon._prefixEnabled then return end

            local text = eb:GetText()
            if not text or text == "" then return end

            local chatType = eb.chatType
            local target = eb.channelTarget

            -- ProcessOutgoingText is implemented on the addon object
            local modified = addon:ProcessOutgoingText(text, chatType, target)
            if modified and modified ~= text then
                eb:SetText(modified)
            end
        end)

        editBox._chatCompatHooked = true
    end

    -- Hook all existing chat editboxes
    local numFrames = NUM_CHAT_WINDOWS or 10
    for i = 1, numFrames do
        hookSingleEditBox(_G["ChatFrame" .. i .. "EditBox"])
    end

    -- Catch temporary windows opened later
    if type(FCF_OpenTemporaryWindow) == "function" then
        hooksecurefunc("FCF_OpenTemporaryWindow", function()
            for i = 1, (NUM_CHAT_WINDOWS or 10) do
                hookSingleEditBox(_G["ChatFrame" .. i .. "EditBox"])
            end
        end)
    end

    self._hooks.editBoxesHooked = true
    addon._prefixEnabled = true
end

---------------------------------------------------------------------
-- Call original SendChatMessage  (Classic table-swap path only)
---------------------------------------------------------------------
function ChatCompat:CallOriginalSendChatMessage(msg, chatType, language, target)
    local original = self._hooks.sendChatOriginal
    if type(original) == "function" then
        return original(msg, chatType, language, target)
    end
    -- Fallback: hooks were never set up
    if self.api.useCChatInfo then
        return C_ChatInfo.SendChatMessage(msg, chatType, language, target)
    else
        return SendChatMessage(msg, chatType, language, target)
    end
end

---------------------------------------------------------------------
-- Call original C_Club.SendMessage
---------------------------------------------------------------------
function ChatCompat:CallOriginalClubSendMessage(clubID, streamID, msg)
    local original = self._hooks.clubSendOriginal
    if type(original) == "function" then
        return original(clubID, streamID, msg)
    end
    if self.api.useCClub then
        return C_Club.SendMessage(clubID, streamID, msg)
    end
end

---------------------------------------------------------------------
-- Check if chat messaging is locked (Retail instance lockdown)
---------------------------------------------------------------------
function ChatCompat:IsChatLocked()
    if not self.api.useCChatInfo then return false end
    if type(C_ChatInfo) == "table" and type(C_ChatInfo.InChatMessagingLockdown) ==
        "function" then
        local ok, result = pcall(C_ChatInfo.InChatMessagingLockdown)
        if ok and result then return true end
    end
    return false
end

---------------------------------------------------------------------
-- Hook state queries
---------------------------------------------------------------------
function ChatCompat:IsSendChatHooked() return
    self._hooks.sendChatHooked or false end

function ChatCompat:IsClubSendHooked() return
    self._hooks.clubSendHooked or false end

---------------------------------------------------------------------
-- Bulk hook / unhook helpers
---------------------------------------------------------------------
function ChatCompat:HookAll(addon)
    self:HookSendChatMessage(addon)
    self:HookClubSendMessage(addon)
end

function ChatCompat:UnhookAll()
    self:UnhookSendChatMessage()
    self:UnhookClubSendMessage()
end

---------------------------------------------------------------------
-- API info (debug)
---------------------------------------------------------------------
function ChatCompat:GetApiInfo()
    return {
        useCChatInfo = self.api.useCChatInfo,
        useCClub = self.api.useCClub,
        supportsInstanceChat = self.api.supportsInstanceChat,
        sendChatHooked = self:IsSendChatHooked(),
        clubSendHooked = self:IsClubSendHooked()
    }
end

return ChatCompat
