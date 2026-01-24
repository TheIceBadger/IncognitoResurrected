-- RetailAPI.lua
-- Retail WoW API implementation for Incognito Resurrected
function IncognitoResurrected:RetailHooks()
    -- Hook the retail C_ChatInfo.SendChatMessage function
    self:RawHook(C_ChatInfo, "SendChatMessage", true)

    -- Hook the C_Club.SendMessage function for community chat
    if type(C_Club) == "table" and type(C_Club.SendMessage) == "function" then
        self:RawHook(C_Club, "SendMessage", true)
    end
end

function IncognitoResurrected:SendChatMessage(msg, chatType, language, target)
    -- Early out: ignore messages starting with configured symbols (after spaces)
    if self.db and self.db.profile and self.db.profile.enable and type(msg) ==
        "string" then
        local symbols = self.db.profile.ignoreLeadingSymbols or "/!#"
        local firstChar = msg:match("^%s*(.)")
        if firstChar and symbols:find(firstChar, 1, true) then
            self.hooks[C_ChatInfo].SendChatMessage(msg, chatType, language,
                                                   target)
            return
        end
    end
    if self.db.profile.enable and self.db.profile.community and chatType ==
        "CHANNEL" then
        local id, chname = GetChannelName(target)
        self:Safe_Print("Channel name: " .. (chname or "nil"))
        if chname and chname:match("^Community:") then
            local clubId, streamId = chname:match("^Community:(.-):(.-)$")
            self:Safe_Print("Parsed clubId: " .. (clubId or "nil") ..
                                ", streamId: " .. (streamId or "nil"))
            if clubId and streamId then
                self:Safe_Print(
                    "Detected community channel, calling SendMessage")
                self:SendMessage(clubId, streamId, msg)
                return
            end
        end
    end
    if self.db.profile.enable then
        if self.db.profile.name and self.db.profile.name ~= "" then
            -- Determine if we should suppress adding the prefix based on exact/partial match
            local shouldAddPrefix = true
            if self.db.profile.hideOnMatchingCharName and character_name then
                local nLower = string.lower(self.db.profile.name)
                local cLower = string.lower(character_name or "")
                if nLower == cLower then
                    shouldAddPrefix = false
                else
                    local mode = self.db.profile.partialMatchMode or "disabled"
                    if mode ~= "disabled" and #nLower > 0 then
                        if mode == "start" then
                            if cLower:sub(1, #nLower) == nLower then
                                shouldAddPrefix = false
                            end
                        elseif mode == "anywhere" then
                            if cLower:find(nLower, 1, true) ~= nil then
                                shouldAddPrefix = false
                            end
                        elseif mode == "end" then
                            if cLower:sub(-#nLower) == nLower then
                                shouldAddPrefix = false
                            end
                        end
                    end
                end
            end
            if shouldAddPrefix then
                if (self.db.profile.guild and
                    (chatType == "GUILD" or chatType == "OFFICER")) or
                    (self.db.profile.raid and chatType == "RAID") or
                    (self.db.profile.party and chatType == "PARTY") or
                    (self.db.profile.instance_chat and chatType ==
                        "INSTANCE_CHAT") then
                    msg = self:GetNamePrefix() .. msg
                    -- Use World Chat Channels
                elseif self.db.profile.world_chat and chatType == "CHANNEL" then
                    msg = self:GetNamePrefix() .. msg
                    -- Use Specified Chat Channel, commas are allowed
                elseif self.db.profile.channel and chatType == "CHANNEL" then
                    for i in string.gmatch(self.db.profile.channel, '([^,]+)') do
                        local nameToMatch = strtrim(i)
                        local id, chname = GetChannelName(target)
                        if chname and strupper(nameToMatch) == strupper(chname) then
                            msg = self:GetNamePrefix() .. msg
                        end
                    end
                    -- LFR
                elseif self.db.profile.lfr and IsInLFR() then
                    msg = self:GetNamePrefix() .. msg
                end
            end
        end
    end
    -- Call original function
    self.hooks[C_ChatInfo].SendChatMessage(msg, chatType, language, target)
end

function IncognitoResurrected:SendMessage(clubID, streamID, msg)
    self:Safe_Print("Entering SendMessage with clubID: " .. clubID ..
                        ", streamID: " .. streamID)
    if self.db and self.db.profile and self.db.profile.enable and type(msg) ==
        "string" then
        local symbols = self.db.profile.ignoreLeadingSymbols or "/!#"
        local firstChar = msg:match("^%s*(.)")
        if firstChar and symbols:find(firstChar, 1, true) then
            self:Safe_Print("Ignoring due to leading symbol")
            self.hooks[C_Club].SendMessage(clubID, streamID, msg)
            return
        end
    end
    if self.db.profile.enable and self.db.profile.community then
        self:Safe_Print("Community option enabled")
        local clubInfo = C_Club.GetClubInfo(clubID)
        if clubInfo then
            self:Safe_Print("Club type: " .. clubInfo.clubType)
        else
            self:Safe_Print("No clubInfo")
        end
        if clubInfo and
            (clubInfo.clubType == Enum.ClubType.BattleNet or clubInfo.clubType ==
                Enum.ClubType.Character) then
            self:Safe_Print("Is community club")
            local shouldAddPrefix = true
            if self.db.profile.hideOnMatchingCharName and character_name then
                local nLower = string.lower(self.db.profile.name or "")
                local cLower = string.lower(character_name or "")
                self:Safe_Print("Configured name lower: " .. nLower)
                self:Safe_Print("Character name lower: " .. cLower)
                if nLower == cLower then
                    shouldAddPrefix = false
                    self:Safe_Print("Names match exactly")
                else
                    local mode = self.db.profile.partialMatchMode or "disabled"
                    self:Safe_Print("Partial match mode: " .. mode)
                    if mode ~= "disabled" and #nLower > 0 then
                        if mode == "start" then
                            if cLower:sub(1, #nLower) == nLower then
                                shouldAddPrefix = false
                                self:Safe_Print("Matches start")
                            end
                        elseif mode == "anywhere" then
                            if cLower:find(nLower, 1, true) ~= nil then
                                shouldAddPrefix = false
                                self:Safe_Print("Matches anywhere")
                            end
                        elseif mode == "end" then
                            if cLower:sub(-#nLower) == nLower then
                                shouldAddPrefix = false
                                self:Safe_Print("Matches end")
                            end
                        end
                    end
                end
            end
            self:Safe_Print("shouldAddPrefix: " .. tostring(shouldAddPrefix))
            if shouldAddPrefix then
                local prefix = self:GetNamePrefix()
                self:Safe_Print("Adding prefix: " .. prefix)
                msg = prefix .. msg
            end
        end
    end
    self.hooks[C_Club].SendMessage(clubID, streamID, msg)
end
