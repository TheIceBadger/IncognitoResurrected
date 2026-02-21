# ChatCompat Integration Summary

## Changes Made

### 1. Added ChatCompat to embeds.xml

- Added `<Script file="Libs\ChatCompat\ChatCompat.lua"/>` after LibStub
- This ensures ChatCompat loads before the addon initializes

### 2. Fixed RetailAPI.lua

**Key Changes:**

- Added `local ChatCompat = LibStub("ChatCompat")` at the top
- Updated `RetailHooks()` to use `ChatCompat:HookSendChatMessage(self)`
- Updated the hook call to use `self.hooks[C_ChatInfo].SendChatMessage()` for Retail API
- Added fallback to `self.hooks.SendChatMessage()` for safety

### 3. Updated ClassicAPI.lua

**Key Changes:**

- Added `local ChatCompat = LibStub("ChatCompat")` at the top
- Updated `ClassicHooks()` to use `ChatCompat:HookSendChatMessage(self)`
- Hook call remains `self.hooks.SendChatMessage()` (correct for Classic)

### 4. Simplified IncognitoResurrected.lua

**Key Changes:**

- Removed custom `IsRetailAPI()` function (ChatCompat handles this)
- Changed detection to use `ChatCompat.api.useCChatInfo` instead
- Removed `self._isRetailAPI` storage (no longer needed)
- ChatCompat already loaded via `local ChatCompat = LibStub("ChatCompat")` at line 8

## How ChatCompat Works

### API Detection

ChatCompat automatically detects the WoW API version:

- **Retail/Wrath**: `ChatCompat.api.useCChatInfo = true` (uses C_ChatInfo.SendChatMessage)
- **Classic/TBC/Cata**: `ChatCompat.api.useCChatInfo = false` (uses global
  SendChatMessage)

### Unified Hooking

`ChatCompat:HookSendChatMessage(addon)` automatically:

- Hooks `C_ChatInfo.SendChatMessage` on Retail
- Hooks global `SendChatMessage` on Classic
- Uses AceHook's `RawHook` method under the hood

### Hook Calls

After hooking, the addon's `SendChatMessage` function is called, which should:

- **Retail**: Call `self.hooks[C_ChatInfo].SendChatMessage()` to invoke original
- **Classic**: Call `self.hooks.SendChatMessage()` to invoke original

## Benefits of ChatCompat

1. **Simplified Code**: No need to manually detect API versions or manage different hook
   targets
2. **Maintainability**: Single source of truth for API differences
3. **Future-Proof**: ChatCompat can be updated for new WoW versions without changing addon
   code
4. **Consistency**: Both Classic and Retail files follow the same pattern

## File Structure

```
IncognitoResurrected/
├── embeds.xml                    # Loads ChatCompat after LibStub
├── IncognitoResurrected.lua      # Uses ChatCompat.api.useCChatInfo for detection
├── ClassicAPI.lua                # Uses ChatCompat:HookSendChatMessage()
├── RetailAPI.lua                 # Uses ChatCompat:HookSendChatMessage()
└── Libs/
    └── ChatCompat/
        └── ChatCompat.lua        # Handles all API detection and hooking
```

## Testing Checklist

- [ ] Test on Retail (Midnight 12.0+): Should use C_ChatInfo.SendChatMessage
- [ ] Test on Classic Era: Should use global SendChatMessage
- [ ] Test on Cata Classic: Should use global SendChatMessage
- [ ] Verify chat messages have prefix added correctly
- [ ] Verify no ADDON_ACTION_FORBIDDEN errors
- [ ] Verify debug mode shows correct API detection

## Version Updates

All files updated to version 1.4.7 for consistency:

- RetailAPI.lua: 1.4.5 → 1.4.7 ✓
- ClassicAPI.lua: 1.4.5 → 1.4.7 ✓
- IncognitoResurrected.lua: 1.4.7 (no change)

## Next Steps

1. Test in-game on both Retail and Classic clients
2. Verify ChatCompat is loaded correctly via `/dump LibStub("ChatCompat")`
3. Check debug output to confirm correct API is being used
4. Monitor for any hook-related errors during gameplay

## Known Limitations

- The PvP ADDON_ACTION_FORBIDDEN issue mentioned in copilot-instructions.md is
  **Retail-only**
- This ChatCompat integration doesn't solve the PvP taint issue (that requires different
  approach)
- ChatCompat simplifies the hooking mechanism but doesn't change the hook behavior
