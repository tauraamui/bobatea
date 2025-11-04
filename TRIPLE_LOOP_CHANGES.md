# Triple Loop Architecture Changes

## Overview

The TUI application has been modified to use a triple-loop architecture that separates input event handling, application logic updates, and rendering into three independent loops, providing optimal performance for each concern.

## Changes Made

### 1. Unix/Linux Implementation (`lib/term/ui/termios_nix.c.v`)

- **`input_loop()`**: Runs at 1ms intervals (1000Hz) to capture input events
- **`update_loop()`**: New function that runs at configurable rate (default 1000Hz) for application logic
- **`render_loop()`**: Runs at the configured frame rate (default 30Hz) for rendering
- **`termios_loop()`**: Modified to coordinate all three loops - starts input and update loops in separate threads, runs render loop in main thread

### 2. Windows Implementation (`lib/term/ui/input_windows.c.v`)

- **`input_loop()`**: Runs at 1ms intervals to capture Windows console input events
- **`update_loop()`**: New function that runs at configurable rate for application logic
- **`render_loop()`**: Runs at the configured frame rate for rendering
- **`run()`**: Modified to coordinate all three loops similar to the Unix implementation

### 3. TUI Configuration (`lib/term/ui/input.v`)

- **`update_fn`**: New optional callback function for high-frequency application updates
- **`update_rate`**: New configuration parameter (default 1000Hz) to control update frequency
- **`update()`**: New method to invoke the update callback

### 4. Draw Module Integration (`lib/draw/`)

- **`Config`**: Added `update_fn` parameter to support update callbacks
- Both immediate and retained mode contexts pass through the update function to TUI layer

### 5. Bobatea Library (`tea.v`)

- **`update_invoked`**: New flag to track update loop execution
- **`update_rate`**: New field to configure update frequency
- **`update_loop()`**: New function that handles high-frequency model updates
- **`frame()`**: Modified to focus only on rendering, with fallback update handling
- **`run()`**: Updated to pass update function to draw layer

## Benefits

1. **Ultra-High Input Responsiveness**: Input events processed at ~1000Hz
2. **High-Frequency Application Updates**: Your application's `update()` method runs at 1000Hz by default
3. **Smooth Rendering**: Frame rendering continues at optimal rate (typically 30Hz)
4. **Perfect for Games**: Game logic, physics, animations can update at high frequency independent of rendering
5. **Resource Efficient**: Each loop runs at its optimal frequency
6. **Maintained Compatibility**: All existing APIs work unchanged

## Technical Details

### Loop Frequencies
- **Input Loop**: 1000Hz (1ms intervals) - captures all input events immediately
- **Update Loop**: 1000Hz (configurable) - runs your application logic at high frequency
- **Render Loop**: 30Hz (configurable) - renders frames at optimal visual rate

### Threading Model
- Input loop runs in separate thread using V's `spawn`
- Update loop runs in separate thread using V's `spawn` (if update_fn provided)
- Render loop runs in main thread for terminal compatibility
- All loops respect the `paused` state

### Configuration
```v
tui.init(
    // ... other config
    update_fn: your_update_function  // Optional high-frequency update
    update_rate: 1000               // Update frequency in Hz
    frame_rate: 30                  // Render frequency in Hz
)
```

## Usage Examples

### Low-Level TUI Usage
```v
fn update(x voidptr) {
    // Called at 1000Hz - perfect for game logic
    mut app := unsafe { &App(x) }
    app.update_physics()
    app.update_animations()
}

fn frame(x voidptr) {
    // Called at 30Hz - only for rendering
    mut app := unsafe { &App(x) }
    app.render_scene()
}
```

### Bobatea Library Usage
```v
fn (mut m GameModel) update(msg bobatea.Msg) (bobatea.Model, ?bobatea.Cmd) {
    // This is now called at 1000Hz automatically!
    // Perfect for game state updates, physics, animations
    m.update_game_logic()
    return m, none
}

fn (mut m GameModel) view(mut ctx bobatea.Context) {
    // Called at 30Hz - only for rendering
    m.render_game_world(mut ctx)
}
```

## Testing

- `test_triple_loop.v`: Low-level TUI demonstration showing all three loop counters
- `test_bobatea_triple_loop.v`: Bobatea-level demonstration showing high-frequency model updates
- All existing tests pass, confirming backward compatibility

## Performance Impact

- Input latency reduced by ~30x (from 33ms to 1ms worst case)
- Application logic can now run at game-loop frequencies
- Rendering performance unchanged and optimal
- CPU usage optimized - each loop runs only as fast as needed