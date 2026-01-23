# Incognito Resurrected - AI Coding Instructions

## Project Overview

World of Warcraft addon that prefixes chat messages with a custom name. Supports multiple
WoW versions (Retail, Classic Era, Cata Classic) via interface version detection in
[IncognitoResurrected.toc](../IncognitoResurrected.toc).

## Architecture & Dependencies

### Ace3 Framework Foundation

Built entirely on Ace3 libraries (embedded in `Libs/`):

- **AceAddon-3.0**: Core addon initialization (`OnInitialize`, `OnEnable`, `OnDisable`)
- **AceHook-3.0**: Function hooking for `SendChatMessage` interception
- **AceConfig-3.0/AceGUI-3.0**: Options UI with slash commands `/inc` or `/incognito`
- **AceDB-3.0**: Profile-based saved variables (`IncognitoResurrectedDB`)
- **AceLocale-3.0**: Localization (files: `IncognitoResurrected_*.lua`)

Load order in [embeds.xml](../embeds.xml) is critical - LibStub must load first.

### Hook Strategy (API Version Detection)

[IncognitoResurrected.lua](../IncognitoResurrected.lua) lines 290-302 detect WoW API
version at runtime:

```lua
self._useCChatInfo = type(C_ChatInfo) == "table" and type(C_ChatInfo.SendChatMessage) == "function"
self._useCClubInfo = type(C_Club) == "table" and type(C_Club.SendMessage) == "function"
```

- **Retail (10.0+)**: Hooks `C_ChatInfo.SendChatMessage` and `C_Club.SendMessage`
- **Classic**: Hooks global `SendChatMessage` function
- All hooks use `RawHook` to preserve original behavior

## Core Workflows

### Message Interception Flow

1. **SendChatMessage hook** (lines 307-370) intercepts outgoing chat
2. **Leading symbol check** (lines 313-323): Skip messages starting with `/!#@?`
   (configurable via `ignoreLeadingSymbols`)
3. **Name matching logic** (lines 346-364): Suppress prefix if character name matches
   configured name based on `partialMatchMode` (disabled/start/anywhere/end)
4. **Channel filtering** (lines 337-369): Apply prefix only to enabled channels
   (guild/party/raid/instance/world/custom)
5. **Community chat special handling** (lines 328-343): Redirect to `C_Club.SendMessage`
   for community channels

### Chat Filter for Class Colors

Lines 502-584 implement client-side colorization:

- **ChatPrefixColorFilter** (lines 518-556): Regex matches bracketed prefix `(Name):` and
  injects class color codes
- Registered via `ChatFrame_AddMessageEventFilter` on `OnEnable`
- Supports custom class colors addon via `CUSTOM_CLASS_COLORS` detection

## Critical Patterns

### Feature Flags by WoW Version

```lua
function IncognitoResurrected:IsLFRAvailable()
    if type(GetDifficultyInfo) == "function" then
        local name = GetDifficultyInfo(17)
        return name ~= nil
    end
    return false
end
```

Use this pattern to hide UI elements not applicable to Classic (lines 162-165, 211-214).

### Bracket Style System

Lines 488-498 use lookup table for customizable brackets:

```lua
local pairs = { paren = {"(", ")"}, square = {"[", "]"}, curly = {"{", "}"}, angle = {"<", ">"} }
```

Always update both `GetNamePrefix()` and the regex in `ChatPrefixColorFilter` when
modifying bracket logic.

### Debug Mode

Use `self:Safe_Print(msg)` wrapper (lines 480-482) - only outputs when `debug` option
enabled. Critical for troubleshooting hook behavior without spamming users.

## Key Files

- [IncognitoResurrected.lua](../IncognitoResurrected.lua): Main addon logic (584 lines)
- [IncognitoResurrected.toc](../IncognitoResurrected.toc): Multi-version interface
  declarations
- [IncognitoResurrected_enUS.lua](../IncognitoResurrected_enUS.lua): Localization template
  (all languages follow this structure)

## Common Tasks

### Adding New Channel Type

1. Add profile default in `Defaults.profile` (lines 225-241)
2. Add option to `generalOptions.args` (lines 120-222)
3. Implement condition in `SendChatMessage` hook (lines 337-369)
4. Add localization strings to all `IncognitoResurrected_*.lua` files

### Testing

No automated tests. Manual testing requires:

- Multiple WoW clients (Retail/Classic) or use `## Interface` version spoofing
- Test channels: guild, party, raid, custom channels, community (Retail only)
- Verify hooks with `/dump C_ChatInfo.SendChatMessage` or `/dump SendChatMessage`

### Packaging

Uses `#@no-lib-strip@` directives in
[IncognitoResurrected.toc](../IncognitoResurrected.toc) (lines 12-14) for CurseForge/Wago
packager. Libraries are embedded but stripped in release builds if available globally.
