# Tick Facility in Bobatea

Bobatea now includes a tick facility similar to bubbletea's approach, allowing you to create timed commands that execute after a specified duration.

## Functions

### `tick(duration, callback)`

Creates a command that waits for the specified duration and then returns a message.

```v
import bobatea
import time

// Create a tick command that waits 1 second
tick_cmd := bobatea.tick(time.second, fn (t time.Time) bobatea.Msg {
    return bobatea.TickMsg{
        time: t
    }
})

// Execute the command (this will block for 1 second)
msg := tick_cmd()
```

### `every(duration, callback)`

Creates a command that waits until the next interval boundary aligned to the system clock.

```v
import bobatea
import time

// Create an every command that aligns to 500ms boundaries
every_cmd := bobatea.every(500 * time.millisecond, fn (t time.Time) bobatea.Msg {
    return bobatea.TickMsg{
        time: t
    }
})

// Execute the command
msg := every_cmd()
```

## TickMsg

A built-in message type that contains the time when the tick occurred:

```v
pub struct TickMsg {
pub:
    time time.Time
}
```

## Usage in Models

To create repeating ticks in your application, return another tick command from your update function:

```v
fn do_tick() bobatea.Cmd {
    return bobatea.tick(time.second, fn (t time.Time) bobatea.Msg {
        return bobatea.TickMsg{
            time: t
        }
    })
}

fn (m Model) init() ?bobatea.Cmd {
    return do_tick()
}

fn (mut m Model) update(msg bobatea.Msg) (bobatea.Model, ?bobatea.Cmd) {
    match msg {
        bobatea.TickMsg {
            // Handle the tick
            m.counter++
            
            // Return another tick to continue the loop
            return m, do_tick()
        }
        else {}
    }
    return m, none
}
```

## Key Differences from Bubbletea

- **Blocking**: V's tick implementation uses `time.sleep()` and blocks the current goroutine
- **Simplicity**: No complex timer management - just sleep and return
- **Compatibility**: Works with bobatea's existing command and message system

## Examples

See `examples/simple_tick_demo.v` for a working demonstration of the tick functionality.