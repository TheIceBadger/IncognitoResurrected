-- Version: 1.4.5
-- ClassicAPI.lua
-- Classic WoW API implementation for Incognito Resurrected
function IncognitoResurrected:OpenConfig()
    -- Classic-specific config opening using AceConfigDialog
    local dialog = LibStub("AceConfigDialog-3.0")
    dialog:Open("IncognitoResurrected Options")

    -- Customize frame appearance
    local frame = dialog.OpenFrames["IncognitoResurrected Options"]
    if frame and frame.frame then
        frame.frame:SetHeight(580)
        -- Add text to status box
        if frame.statustext then
            frame.statustext:SetText(
                "Incognito Resurrected | https://www.curseforge.com/wow/addons/incognito-resurrected")
        end
        -- Hide the EditBox if it was created previously
        if frame.linkBox then frame.linkBox:Hide() end
    end
end

function IncognitoResurrected:ClassicHooks()
    -- Hook the classic SendChatMessage function
    self:RawHook("SendChatMessage", true)
end

function IncognitoResurrected:SendChatMessage(msg, chatType, language, target)
    -- Early out: ignore messages starting with configured symbols (after spaces)
    if self.db and self.db.profile and self.db.profile.enable and type(msg) ==
        "string" then
        local symbols = self.db.profile.ignoreLeadingSymbols or "/!#"
        local firstChar = msg:match("^%s*(.)")
        if firstChar and symbols:find(firstChar, 1, true) then
            self:Safe_Print("Skipping - leading symbol detected: " .. firstChar)
            self.hooks.SendChatMessage(msg, chatType, language, target)
            return
        end
    end

    if self.db.profile.enable then
        self:Safe_Print("Enable is true")
        if self.db.profile.name and self.db.profile.name ~= "" then
            self:Safe_Print("Name is set: " .. self.db.profile.name)
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
    self.hooks.SendChatMessage(msg, chatType, language, target)
end

