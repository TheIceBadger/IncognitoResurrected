--  Version: 1.4.3
IncognitoResurrected = LibStub("AceAddon-3.0"):NewAddon("IncognitoResurrected",
                                                        "AceConsole-3.0",
                                                        "AceEvent-3.0",
                                                        "AceHook-3.0");
--  Localization
local L = LibStub("AceLocale-3.0"):GetLocale("IncognitoResurrected", true)
--  Main Section
local Options = {
    name = "Incognito Resurrected",
    type = "group",
    args = {
        generalSettings = {
            name = "General Settings",
            type = "group",
            inline = true,
            order = 0,
            get = function(item)
                return IncognitoResurrected.db.profile[item[#item]]
            end,
            set = function(item, value)
                IncognitoResurrected.db.profile[item[#item]] = value
            end,
            args = {
                name = {
                    order = 1,
                    type = "input",
                    width = "normal",
                    name = L["name"],
                    desc = L["name_desc"]
                },
                Spacer1 = {
                    order = 1.5,
                    type = "description",
                    width = "double",
                    name = ""
                },
                enable = {
                    order = 2,
                    type = "toggle",
                    name = L["enable"],
                    desc = L["enable_desc"],
                    width = "normal"
                },
                Spacer2 = {
                    order = 2.5,
                    type = "description",
                    width = "half",
                    name = ""
                },
                hideOnMatchingCharName = {
                    order = 3,
                    type = "toggle",
                    name = L["hideOnMatchingCharName"],
                    desc = L["hideOnMatchingCharName_desc"],
                    width = "double"
                },
                -- Matching mode for character vs configured name
                partialMatchMode = {
                    order = 4,
                    type = "select",
                    name = L["partialMatchMode"],
                    desc = L["partialMatchMode_desc"],
                    values = {
                        disabled = L["partialMatchMode_disabled"],
                        start = L["partialMatchMode_start"],
                        anywhere = L["partialMatchMode_anywhere"],
                        ["end"] = L["partialMatchMode_end"]
                    },
                    sorting = {"disabled", "start", "anywhere", "end"},
                    width = "normal",
                    disabled = function()
                        return not IncognitoResurrected.db.profile
                                   .hideOnMatchingCharName
                    end
                },
                Spacer3 = {
                    order = 4.5,
                    type = "description",
                    width = "half",
                    name = ""
                },
                -- New option: Colorize prefix by class color
                colorizePrefix = {
                    order = 5,
                    type = "toggle",
                    name = "Color Name by class",
                    desc = "Color the Incognito Name with the sender's class color.",
                    width = "double"
                },
                -- New option: Ignore leading symbols
                ignoreLeadingSymbols = {
                    order = 6,
                    type = "input",
                    name = L["ignoreLeadingSymbols"],
                    desc = L["ignoreLeadingSymbols_desc"],
                    width = "normal"
                },
                spacer4 = {
                    order = 7,
                    type = "description",
                    name = "",
                    width = "half"
                },
                -- New option: Bracket style selector
                bracketStyle = {
                    order = 8,
                    type = "select",
                    name = L["bracketStyle"],
                    desc = L["bracketStyle_desc"],
                    values = {
                        paren = "(round)",
                        square = "[square]",
                        curly = "{curly}",
                        angle = "<angle>"
                    }
                }
            }
        },
        generalOptions = {
            name = "Options",
            type = "group",
            inline = true,
            order = 1,
            get = function(item)
                return IncognitoResurrected.db.profile[item[#item]]
            end,
            set = function(item, value)
                IncognitoResurrected.db.profile[item[#item]] = value
            end,
            args = {
                guild = {
                    order = 1,
                    type = "toggle",
                    width = "full",
                    name = L["guild"],
                    desc = L["guild_desc"]
                },
                guildinfo = {
                    order = 1.5,
                    type = "description",
                    name = "|cFFFFA500" .. L["guildinfo"]
                },
                party = {
                    order = 2,
                    type = "toggle",
                    width = 0.6,
                    name = L["party"],
                    desc = L["party_desc"]
                },
                raid = {
                    order = 3,
                    type = "toggle",
                    width = 0.6,
                    name = L["raid"],
                    desc = L["raid_desc"]
                },
                lfr = {
                    order = 4,
                    type = "toggle",
                    width = 0.6,
                    name = L["lfr"],
                    desc = L["lfr_desc"],
                    hidden = function()
                        return not IncognitoResurrected:IsLFRAvailable()
                    end
                },
                instance_chat = {
                    order = 5,
                    type = "toggle",
                    width = 0.6,
                    name = L["instance_chat"],
                    desc = L["instance_chat_desc"]
                },
                world_chat = {
                    order = 6,
                    type = "toggle",
                    width = "full",
                    name = L["world_chat"],
                    desc = L["world_chat_desc"]
                },
                world_chat_info = {
                    order = 6.5,
                    type = "description",
                    name = "|cFFFFA500" .. L["world_chat_info_desc"]
                },
                channel = {
                    order = 7,
                    type = "input",
                    name = L["channel"],
                    desc = L["channel_desc"]
                },
                channelinfo = {
                    order = 7.5,
                    type = "description",
                    name = "|cFFFFA500" .. L["channel_info_text"]
                },
                community = {
                    order = 8,
                    type = "toggle",
                    width = "full",
                    name = L["community"],
                    desc = L["community_desc"],
                    hidden = function()
                        return not IncognitoResurrected:IsLFRAvailable()
                    end
                },
                communityinfo = {
                    order = 8.5,
                    type = "description",
                    name = "|cFFFFA500" .. L["community_info_text"],
                    hidden = function()
                        return not IncognitoResurrected:IsLFRAvailable()
                    end
                },
                debug = {
                    order = 9,
                    type = "toggle",
                    width = "full",
                    name = L["debug"],
                    desc = L["debug_desc"]
                }
            }
        }
    }
}
local Defaults = {
    profile = {
        enable = true,
        guild = true,
        party = false,
        raid = false,
        lfr = false,
        instance_chat = false,
        world_chat = false,
        debug = false,
        channel = nil,
        community = false,
        hideOnMatchingCharName = true,
        -- Default ignored leading symbols
        ignoreLeadingSymbols = "/!#@?",
        -- Default bracket style
        bracketStyle = "paren",
        -- Class-color the bracketed prefix in chat frames
        colorizePrefix = true
    }
}
local SlashOptions = {
    type = "group",
    handler = IncognitoResurrected,
    get = function(item) return IncognitoResurrected.db.profile[item[#item]] end,
    set = function(item, value)
        IncognitoResurrected.db.profile[item[#item]] = value
    end,
    args = {
        enable = {name = L["enable"], desc = L["enable_desc"], type = "toggle"},
        name = {name = L["name"], desc = L["name_desc"], type = "input"},
        config = {
            name = L["config"],
            desc = L["config_desc"],
            guiHidden = true,
            type = "execute",
            func = function()
                InterfaceOptionsFrame_OpenToCategory(IncognitoResurrected)
            end
        }
    }
}
local SlashCmds = {"inc", "incognito", "IncognitoResurrected"};
local character_name
--  Init
function IncognitoResurrected:IsRetailAPI()
    -- Check if C_ChatInfo.SendChatMessage exists and is being used
    -- This handles Retail AND SoD/TBC Anniversary which backported the Retail API
    local result = type(C_ChatInfo) == "table" and
                       type(C_ChatInfo.SendChatMessage) == "function"
    DEFAULT_CHAT_FRAME:AddMessage("IsRetailAPI() - C_ChatInfo type: " ..
                                      type(C_ChatInfo))
    if C_ChatInfo then
        DEFAULT_CHAT_FRAME:AddMessage(
            "IsRetailAPI() - C_ChatInfo.SendChatMessage type: " ..
                type(C_ChatInfo.SendChatMessage))
    end
    DEFAULT_CHAT_FRAME:AddMessage("IsRetailAPI() returning: " ..
                                      tostring(result))
    return result
end

function IncognitoResurrected:OnInitialize()
    -- Load our database.
    self.db = LibStub("AceDB-3.0"):New("IncognitoResurrectedDB", Defaults, true)
    -- Set up our config options.
    local profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
    local config = LibStub("AceConfig-3.0")
    config:RegisterOptionsTable("IncognitoResurrected", SlashOptions, SlashCmds)
    local registry = LibStub("AceConfigRegistry-3.0")
    registry:RegisterOptionsTable("IncognitoResurrected Options", Options)
    registry:RegisterOptionsTable("IncognitoResurrected Profiles", profiles);
    local dialog = LibStub("AceConfigDialog-3.0");
    self.optionFrames = {
        main = dialog:AddToBlizOptions("IncognitoResurrected Options",
                                       "IncognitoResurrected"),
        profiles = dialog:AddToBlizOptions("IncognitoResurrected Profiles",
                                           "Profiles", "IncognitoResurrected")
    }
    -- Detect API version and setup appropriate hooks
    local isRetail = self:IsRetailAPI()
    if self.db.profile.debug then
        self:Print("API Detection: isRetail = " .. tostring(isRetail))
        self:Print("C_ChatInfo type: " .. type(C_ChatInfo))
        if C_ChatInfo then
            self:Print("C_ChatInfo.SendChatMessage type: " ..
                           type(C_ChatInfo.SendChatMessage))
        end
    end

    if isRetail then
        if self.db.profile.debug then
            self:Print("Calling RetailHooks()")
            self:Print("RetailHooks exists? " ..
                           tostring(self.RetailHooks ~= nil))
        end
        self:RetailHooks()
    else
        if self.db.profile.debug then
            self:Print("Calling ClassicHooks()")
            self:Print("ClassicHooks exists? " ..
                           tostring(self.ClassicHooks ~= nil))
        end
        self:ClassicHooks()
    end

    -- get current character name
    character_name, _ = UnitName("player")
    self:Safe_Print(L["Loaded"])
end

--  SendChatMessage and SendMessage are now implemented in ClassicAPI.lua or RetailAPI.lua
--  Functions
function IncognitoResurrected:Safe_Print(msg)
    if self.db.profile.debug then self:Print(msg) end
end
function InterfaceOptionsFrame_OpenToCategory(IncognitoResurrected)
    if type(IncognitoResurrected) == "string" then
        return Settings.OpenToCategory(IncognitoResurrected);
    elseif type(IncognitoResurrected) == "table" then
        local frame = IncognitoResurrected;
        local category = frame.name;
        if category and type(category) == "string" then
            return Settings.OpenToCategory(category);
        end
    end
end
function IsInLFR()
    local _, instanceType, difficultyID = GetInstanceInfo()
    return instanceType == "raid" and difficultyID == 17
end
function IncognitoResurrected:IsLFRAvailable()
    if type(GetDifficultyInfo) == "function" then
        local name = GetDifficultyInfo(17)
        return name ~= nil
    end
    return false
end
function IncognitoResurrected:GetNamePrefix()
    local style =
        (self.db and self.db.profile and self.db.profile.bracketStyle) or
            "paren"
    local pairs = {
        paren = {"(", ")"},
        square = {"[", "]"},
        curly = {"{", "}"},
        angle = {"<", ">"}
    }
    local pair = pairs[style] or pairs.paren
    return pair[1] .. (self.db.profile.name or "") .. pair[2] .. ": "
end
-- Class-color prefix rendering (client-side)
local OPEN_TO_CLOSE = {["("] = ")", ["["] = "]", ["{"] = "}", ["<"] = ">"}
local function ExtractPlayerGUID(...)
    local n = select("#", ...)
    for i = 1, n do
        local v = select(i, ...)
        if type(v) == "string" and v:match("^Player%-") then return v end
    end
end
function IncognitoResurrected:ChatPrefixColorFilter(frame, event, msg, author, ...)
    if not (self.db and self.db.profile and self.db.profile.enable and
        self.db.profile.colorizePrefix) then return false end
    -- Match a leading bracketed name, requiring a colon after the closing bracket.
    -- Supports optional spaces before and after the colon.
    -- Examples: "(Name):msg", "(Name): msg", "(Name) :msg", "(Name) : msg"
    local pre, open, name, close, spacesAfterClose, colonSpaces, rest =
        msg:match(
            "^(%s*)([%(%[%{%<])([^%(%[%{%<%]%}%>]+)([%)%]%}%>])(%s*):(%s*)(.*)$")
    if not open then return false end
    if OPEN_TO_CLOSE[open] ~= close then return false end
    -- Resolve class color of the sender
    local guid = ExtractPlayerGUID(...)
    local classFile
    if guid and GetPlayerInfoByGUID then
        local _, cf = GetPlayerInfoByGUID(guid)
        classFile = cf
    end
    if not classFile and author and UnitClass then
        local unit = Ambiguate and Ambiguate(author, "none") or author
        local _, cf = UnitClass(unit)
        classFile = cf
    end
    if not classFile then return false end
    local colors =
        (type(CUSTOM_CLASS_COLORS) == "table" and CUSTOM_CLASS_COLORS) or
            RAID_CLASS_COLORS
    local c = colors and colors[classFile]
    if not c then return false end
    local hex = string.format("|cff%02x%02x%02x",
                              math.floor((c.r or 1) * 255 + 0.5),
                              math.floor((c.g or 1) * 255 + 0.5),
                              math.floor((c.b or 1) * 255 + 0.5))
    local newMsg = string.format("%s%s%s%s|r%s%s:%s%s", pre or "", open, hex,
                                 name or "", close, spacesAfterClose or "",
                                 colonSpaces or "", rest or "")
    return false, newMsg, author, ...
end
function IncognitoResurrected:_EnsureChatFilterSetup()
    if self._ChatFilterFunc then return end
    self._filterEvents = {
        "CHAT_MSG_SAY", "CHAT_MSG_YELL", "CHAT_MSG_EMOTE",
        "CHAT_MSG_TEXT_EMOTE", "CHAT_MSG_GUILD", "CHAT_MSG_OFFICER",
        "CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER", "CHAT_MSG_RAID",
        "CHAT_MSG_RAID_LEADER", "CHAT_MSG_RAID_WARNING",
        "CHAT_MSG_INSTANCE_CHAT", "CHAT_MSG_INSTANCE_CHAT_LEADER",
        "CHAT_MSG_CHANNEL", "CHAT_MSG_WHISPER", "CHAT_MSG_WHISPER_INFORM"
    }
    self._ChatFilterFunc = function(frame, event, msg, author, ...)
        return IncognitoResurrected:ChatPrefixColorFilter(frame, event, msg,
                                                          author, ...)
    end
end
function IncognitoResurrected:RegisterChatFilters()
    self:_EnsureChatFilterSetup()
    if self._filtersRegistered then return end
    for _, ev in ipairs(self._filterEvents) do
        ChatFrame_AddMessageEventFilter(ev, self._ChatFilterFunc)
    end
    self._filtersRegistered = true
end
function IncognitoResurrected:UnregisterChatFilters()
    if not self._filtersRegistered then return end
    for _, ev in ipairs(self._filterEvents) do
        ChatFrame_RemoveMessageEventFilter(ev, self._ChatFilterFunc)
    end
    self._filtersRegistered = false
end
function IncognitoResurrected:OnEnable() self:RegisterChatFilters() end
function IncognitoResurrected:OnDisable() self:UnregisterChatFilters() end

