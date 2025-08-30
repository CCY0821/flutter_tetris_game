# Rune System Debug Guide

This guide documents the complete solution to the rune system issues encountered on Aug 30, 2025.

## Problem Summary
- **Symptom**: Rune energy bars would fill up, but rune slots remained unlit and unresponsive to clicks
- **User Report**: "能量條滿了也沒亮燈 點了沒反應"

## Root Cause Analysis

### Primary Issue: Missing Persistence Layer
The rune loadout configuration selected by users was never saved to persistent storage, causing the RuneSystem to always initialize with empty slots.

### Secondary Issues:
1. **Initialization Order**: RuneSystem initialized before loading saved configuration
2. **Synchronization Gap**: No mechanism to reload RuneSystem when loadout changed
3. **UI Update Lag**: Energy changes didn't trigger immediate UI updates

## Complete Solution

### 1. Persistence Layer (`lib/core/game_persistence.dart`)
```dart
// Added complete rune loadout persistence
static Future<bool> saveRuneLoadout(RuneLoadout loadout)
static Future<RuneLoadout?> loadRuneLoadout()
static Future<bool> clearRuneLoadout()
static Future<bool> hasSavedRuneLoadout()
```

### 2. Game State Initialization (`lib/game/game_state.dart`)
```dart
// Fixed initialization sequence
Future<void> initializeAudio() async {
  await audioService.initialize();
  await _loadHighScore();
  await _loadRuneLoadout();     // NEW: Load before rune system init
  _initializeRuneSystem();
}

// Added loadout management
Future<void> _loadRuneLoadout()
Future<void> saveRuneLoadout()
```

### 3. Rune System Enhancement (`lib/game/rune_system.dart`)
```dart
// Added comprehensive debug logging
void _initializeSlots() {
  debugPrint('RuneSystem: Initializing slots...');
  for (int i = 0; i < slots.length; i++) {
    final runeType = loadout.getSlot(i);
    debugPrint('RuneSystem: Slot $i - runeType: $runeType');
    // ...
  }
}

// Added reload capability
void reloadLoadout() {
  _initializeSlots();
}
```

### 4. Touch Controls Update (`lib/game/touch_controls.dart`)
```dart
// Added initialization safety check
if (!widget.gameState.hasRuneSystemInitialized) {
  return _buildEmptyRuneSlot(slotSize);
}

// Enhanced energy checking
final hasEnoughEnergy = widget.gameState.runeEnergyManager.canConsume(definition.energyCost);
final canCast = runeSlot.canCast && !isDisabled && hasEnoughEnergy;
```

### 5. Settings Panel Integration (`lib/widgets/settings_panel.dart`)
```dart
// Updated callback to save and reload
onLoadoutChanged: () async {
  await widget.gameState.saveRuneLoadout();
  widget.onStateChange();
},
```

## Verification Logs

### Before Fix:
```
RuneSystem: Slot 0 - runeType: null
RuneSystem: Slot 0 - after reset: state=RuneSlotState.empty
```

### After Fix:
```
GamePersistence: Rune loadout loaded - RuneLoadout([Flame Burst, Earthquake, Angel's Grace])
RuneSystem: Slot 0 - runeType: RuneType.flameBurst
RuneSystem: Slot 0 - after reset: state=RuneSlotState.ready
```

## Debug Checklist for Future Issues

1. **Check Persistence**:
   - Look for "GamePersistence: Rune loadout loaded/saved" messages
   - Verify loadout is not empty: `RuneLoadout([...])`

2. **Check Initialization**:
   - Monitor "RuneSystem: Initializing slots..." logs
   - Ensure runeType is not null: `runeType: RuneType.flameBurst`

3. **Check State Synchronization**:
   - Verify slot states: `state=RuneSlotState.ready` (not empty)
   - Confirm energy manager: `canConsume(X)` returns true

4. **Check UI Updates**:
   - Look for "Energy changed! Triggering UI update..." messages
   - Verify setState calls in TouchControls

## Key Files Modified
- `lib/core/game_persistence.dart` (+72 lines)
- `lib/game/game_state.dart` (+35 lines)
- `lib/game/rune_system.dart` (enhanced debug)
- `lib/game/touch_controls.dart` (safety checks)
- `lib/widgets/settings_panel.dart` (callback update)

## Testing Commands
```bash
# Build and install
flutter build apk
adb install -r "build\app\outputs\flutter-apk\app-release.apk"

# Monitor logs
adb logcat | grep -i "GameState:\|RuneSystem:\|GamePersistence:"

# Test persistence
adb shell am force-stop com.example.flutter_tetris_game
adb shell am start -n com.example.flutter_tetris_game/com.example.flutter_tetris_game.MainActivity
```

## Success Criteria
- ✅ Rune slots light up when sufficient energy
- ✅ Clicking consumes energy and casts spells  
- ✅ Configuration persists across app restarts
- ✅ Real-time UI updates on energy changes
- ✅ No "runeType: null" in logs after configuration