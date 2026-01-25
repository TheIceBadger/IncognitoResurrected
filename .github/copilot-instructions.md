# Incognito Resurrected - AI Coding Instructions

## Project Overview

World of Warcraft addon that prefixes chat messages with a custom name. Supports multiple
WoW versions (Retail, Classic Era, Cata Classic) via interface version detection in
[IncognitoResurrected.toc](../IncognitoResurrected.toc).

## Architecture & Dependencies

### API Separation Architecture

**CRITICAL**: The addon uses a strict separation of API-specific code to support multiple
WoW versions:

- **[ClassicAPI.lua](../ClassicAPI.lua)**: Classic WoW API implementations
  - `SendChatMessage` hook for global `SendChatMessage()` function
  - `OpenConfig()` for Classic-specific config dialog
  - `ClassicHooks()` to set up Classic-specific hooks
- **[RetailAPI.lua](../RetailAPI.lua)**: Retail WoW API implementations
  - `SendChatMessage` hook for `C_ChatInfo.SendChatMessage()`
  - `SendMessage` hook for `C_Club.SendMessage()` (community channels)
  - `OpenConfig()` for Retail-specific config dialog
  - `RetailHooks()` to set up Retail-specific hooks

- **[IncognitoResurrected.lua](../IncognitoResurrected.lua)**: Shared core functionality
  - Addon initialization, options, localization, profiles
  - `IsRetailAPI()` detection to determine which API file to use
  - Client-side chat filters (colorization) - these use the same API on all versions
  - Shared utility functions like `GetNamePrefix()`, `Safe_Print()`

**When adding new code:**

- Message sending hooks → Add to ClassicAPI.lua OR RetailAPI.lua depending on API used
- Display/rendering features → Add to IncognitoResurrected.lua (shared)
- WoW API function calls → Use `IsRetailAPI()` check or place in appropriate API file

### Ace3 Framework Foundation

Built entirely on Ace3 libraries (embedded in `Libs/`):

- **AceAddon-3.0**: Core addon initialization (`OnInitialize`, `OnEnable`, `OnDisable`)
- **AceHook-3.0**: Function hooking for `SendChatMessage` interception
- **AceConfig-3.0/AceGUI-3.0**: Options UI with slash commands `/inc` or `/incognito`
- **AceDB-3.0**: Profile-based saved variables (`IncognitoResurrectedDB`)
- **AceLocale-3.0**: Localization (files: `IncognitoResurrected_*.lua`)

Load order in [embeds.xml](../embeds.xml) is critical - LibStub must load first.

### Runtime API Detection

[IncognitoResurrected.lua](../IncognitoResurrected.lua) `OnInitialize()` detects WoW API
version at runtime using `IsRetailAPI()`:

```lua
function IncognitoResurrected:IsRetailAPI()
    return type(C_ChatInfo) == "table" and type(C_ChatInfo.SendChatMessage) == "function"
end
```

Then calls appropriate hooks:

- **Retail (10.0+)**: Calls `self:RetailHooks()` from RetailAPI.lua
- **Classic/Era/Cata**: Calls `self:ClassicHooks()` from ClassicAPI.lua
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

- [IncognitoResurrected.lua](../IncognitoResurrected.lua): Shared core logic
  (initialization, options, filters)
- [ClassicAPI.lua](../ClassicAPI.lua): Classic WoW API implementations (global
  SendChatMessage hook)
- [RetailAPI.lua](../RetailAPI.lua): Retail WoW API implementations (C_ChatInfo/C_Club
  hooks)
- [IncognitoResurrected.toc](../IncognitoResurrected.toc): Multi-version interface
  declarations
- [IncognitoResurrected_enUS.lua](../IncognitoResurrected_enUS.lua): Localization template
  (all languages follow this structure)

## Common Tasks

### Adding New Channel Type

1. Add profile default in `Defaults.profile` in
   [IncognitoResurrected.lua](../IncognitoResurrected.lua)
2. Add option to `generalOptions.args` in
   [IncognitoResurrected.lua](../IncognitoResurrected.lua)
3. Implement condition in `SendChatMessage` hook in **BOTH**:
   - [ClassicAPI.lua](../ClassicAPI.lua) for Classic support
   - [RetailAPI.lua](../RetailAPI.lua) for Retail support
4. Add localization strings to all `IncognitoResurrected_*.lua` files

### Taint Prevention (Midnight/Secret API)

Since Midnight (12.0.0), WoW's Secret API is stricter about taint during secure
operations:

- **Always validate parameters** before calling API functions (check for nil, type, empty
  strings)
- **Use pcall** to wrap potentially tainted API calls (Ambiguate, UnitClass,
  GetPlayerInfoByGUID)
- **Early return** in chat filters if message/author validation fails
- **Never pass nil/invalid values** to API functions during combat/PvP
- See `ChatPrefixColorFilter()` for reference implementation

### Testing

No automated tests. Manual testing requires:

- Multiple WoW clients (Retail/Classic) or use `## Interface` version spoofing
- Test channels: guild, party, raid, custom channels, community (Retail only)
- Verify hooks with `/dump C_ChatInfo.SendChatMessage` or `/dump SendChatMessage`

### Packaging

Uses `#@no-lib-strip@` directives in
[IncognitoResurrected.toc](../IncognitoResurrected.toc) (lines 12-14) for CurseForge/Wago
packager. Libraries are embedded but stripped in release builds if available globally.
