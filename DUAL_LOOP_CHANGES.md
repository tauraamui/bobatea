# Dual Loop Architecture Changes

## Overview

The TUI application has been modified to use a dual-loop architecture that separates input event handling from rendering, providing better input responsiveness.

## Changes Made

### 1. Unix/Linux Implementation (`lib/term/ui/termios_nix.c.v`)

- **`input_loop()`**: New function that runs at 1ms intervals (1000Hz) to capture input events
- **`render_loop()`**: New function that runs at the configured frame rate (default 30Hz) for rendering
- **`termios_loop()`**: Modified to coordinate both loops - starts input loop in a separate thread and runs render loop in main thread

### 2. Windows Implementation (`lib/term/ui/input_windows.c.v`)

- **`input_loop()`**: New function that runs at 1ms intervals to capture Windows console input events
- **`render_loop()`**: New function that runs at the configured frame rate for rendering
- **`run()`**: Modified to coordinate both loops similar to the Unix implementation

## Benefits

1. **Higher Input Responsiveness**: Input events are now processed at ~1000Hz instead of being limited to the frame rate
2. **Consistent Rendering**: Frame rendering continues at the configured rate (typically 30Hz) for smooth visual updates
3. **Better Resource Usage**: Input polling is lightweight and doesn't interfere with rendering performance
4. **Maintained Compatibility**: All existing APIs and configurations remain unchanged

## Technical Details

- Input loop runs in a separate thread using V's `spawn` keyword
- Render loop runs in the main thread to maintain compatibility with terminal operations
- Both loops respect the `paused` state of the context
- Frame timing and sleep calculations remain unchanged for the render loop
- Input polling uses a 1ms sleep interval to balance responsiveness with CPU usage

## Usage

No changes are required in existing code. The dual-loop architecture is transparent to applications using the TUI library. The same `Config` struct and callback functions (`event_fn`, `frame_fn`) work exactly as before.

## Testing

A test application (`test_dual_loop.v`) demonstrates the improved input responsiveness by showing real-time event and frame counters.