# Incognito Resurrected - AI Coding Instructions

## Project Overview

World of Warcraft addon that prefixes chat messages with a custom name. Supports multiple
WoW versions (Retail, Classic Era, Cata Classic) via interface version detection in
[IncognitoResurrected.toc](../IncognitoResurrected.toc).

## CRITICAL UNRESOLVED ISSUE - PVP ADDON_ACTION_FORBIDDEN Error

**Status**: UNRESOLVED - Persistent error in battlegrounds/arenas despite multiple fix
attempts

**Error Details**:

```
[ADDON_ACTION_FORBIDDEN] AddOn 'IncognitoResurrected' tried to call the protected function 'UNKNOWN()'
[C]: in function 'SendChatMessage'
[IncognitoResurrected/RetailAPI.lua]:123: in function <IncognitoResurrected/RetailAPI.lua:33>
```

**Problem**: Even after unhooking with `self:Unhook(C_ChatInfo, "SendChatMessage")`, our
function is STILL being called in PVP instances. The unhook doesn't remove us from the
call chain as expected.

**Attempted Fixes** (all failed):

1. Store original functions before unhook and call them - still triggers
   ADDON_ACTION_FORBIDDEN
2. Call `self.hooks[C_ChatInfo].SendChatMessage` - hooks table may be nil after unhook
3. Call `C_ChatInfo.SendChatMessage` directly - this IS the protected function causing the
   error
4. Return immediately without calling anything - chat messages are lost
5. Check `_isPvPDisabled` flag and return - function still in call chain after unhook

**Root Cause Hypothesis**:

- AceHook's `Unhook()` doesn't immediately restore original Blizzard function
- Our hooked function remains in call chain even after unhooking
- Any code execution in our function during secure moment triggers ADDON_ACTION_FORBIDDEN
- The error occurs at line 123 which is likely calling ANY API during taint

**Potential Solutions to Explore**:

1. Don't use AceHook at all in Retail - use manual hooking with direct table manipulation
2. Use `hooksecurefunc` instead of RawHook (but this prevents modification)
3. Completely disable addon in PVP via OnDisable/OnEnable lifecycle
4. Pre-check instance type BEFORE hooking at all during addon initialization
5. Use PLAYER_ENTERING_BATTLEGROUND event instead of PLAYER_ENTERING_WORLD
6. Investigate if AceHook has a "force unhook" or "clear all hooks" method

**Testing Notes**:

- Error occurs consistently in battlegrounds and arenas
- Error happens when ANY chat message is sent while in PVP instance
- The "Disabled in PVP instance to prevent errors" message prints correctly
- Unhook appears to execute without errors, but doesn't actually remove the hook

## Architecture & Dependencies

### API Separation Architecture

**CRITICAL**: The addon uses a strict separation of API-specific code to support multiple
WoW versions:

- **[ClassicAPI.lua](../ClassicAPI.lua)**: Classic WoW API implementations
  - `SendChatMessage` hook for global `SendChatMessage()` function
  - `OpenConfig()` for Classic-specific config dialog
  - `ClassicHooks()` to set up Classic-specific hooks
  - **DO NOT MODIFY - ClassicAPI.lua should NEVER be changed unless the user explicitly
    requests and approves it**
  - **ClassicAPI works correctly and does not need fixes for Retail-specific issues**
- **[RetailAPI.lua](../RetailAPI.lua)**: Retail WoW API implementations
  - `SendChatMessage` hook for `C_ChatInfo.SendChatMessage()`
  - `SendMessage` hook for `C_Club.SendMessage()` (community channels)
  - `OpenConfig()` for Retail-specific config dialog
  - `RetailHooks()` to set up Retail-specific hooks
  - **Most modern WoW issues (battlegrounds, arenas, Midnight API changes) are
    Retail-only**

- **[IncognitoResurrected.lua](../IncognitoResurrected.lua)**: Shared core functionality
  - Addon initialization, options, localization, profiles
  - `IsRetailAPI()` detection to determine which API file to use
  - Client-side chat filters (colorization) - these use the same API on all versions
  - Shared utility functions like `GetNamePrefix()`, `Safe_Print()`

**When adding new code:**

- Determine if the issue/feature is Retail-specific, Classic-specific, or affects both
- **Retail-only features** (PvP instances, Secret API, C_ChatInfo, communities): Only
  modify RetailAPI.lua
- **Classic-only features**: Only modify ClassicAPI.lua **AND GET USER APPROVAL FIRST**
- **Shared features** (UI, options, colorization): Modify IncognitoResurrected.lua
- If you must modify both API files, ensure changes are appropriate for each version
- **Never blindly copy changes from RetailAPI.lua to ClassicAPI.lua**
- **When in doubt, DO NOT touch ClassicAPI.lua**

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
