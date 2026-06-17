# Code Generation Plan — QuickShell Integration

## Summary
- **Scope**: Integrate existing QuickShell configuration into NixOS Home Manager
- **Files to create**: 1 (home/quickshell.nix)
- **Files to modify**: 1 (home/default.nix — add import)
- **Files to move**: ~18 QML/JSON/Python files from to_implement/ to home/quickshell/config/
- **Files to exclude**: ~15 dev artifacts (*.md, tests/, ConnectionExample.qml, debug_disk.js)

## Steps

### Step 1: Create directory structure
- [x] Create `home/quickshell/config/`
- [x] Create `home/quickshell/config/battery/`
- [x] Create `home/quickshell/config/colors/`
- [x] Create `home/quickshell/config/filters/`
- [x] Create `home/quickshell/config/interaction/`
- [x] Create `home/quickshell/config/utils/`
- [x] Create `home/quickshell/config/taskwarrior/`

### Step 2: Move functional QML/config files
- [x] `shell.qml`
- [x] `Graph.qml`
- [x] `PieChart.qml`
- [x] `app-colors.json`
- [x] `get_events.py`
- [x] `battery/BatteryGraph.qml`
- [x] `colors/BorderColorManager.qml`
- [x] `filters/NotificationFilter.qml`
- [x] `filters/filter-config.json`
- [x] `interaction/ClickRedirectHandler.qml`
- [x] `utils/ConfigManager.qml`
- [x] `utils/DeviceDetector.qml`
- [x] `utils/save_config.py`
- [x] `taskwarrior/TaskPanel.qml`
- [x] `taskwarrior/TaskManager.qml`
- [x] `taskwarrior/TaskItem.qml`
- [x] `taskwarrior/TaskCard.qml`
- [x] `taskwarrior/DataWatcher.qml`

### Step 3: Create home/quickshell.nix
- [x] Nix module with programs.quickshell configuration
- [x] Python with Google API packages
- [x] Symlink to config via mkOutOfStoreSymlink

### Step 4: Update home/default.nix
- [x] Add `./quickshell.nix` to imports list

### Step 5: Remove quickshell from home.packages
- [x] Remove `quickshell` from home.packages in default.nix (now managed by programs.quickshell)

### Step 6: Validate
- [x] Run `nix flake check` to verify no evaluation errors

### Step 7: Cleanup
- [ ] Remove `to_implement/quickshell/` directory (after user confirms)
