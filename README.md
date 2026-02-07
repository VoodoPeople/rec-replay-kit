# RecReplayKit

BLE scenario recording and replay for deterministic integration testing.

## Components

```
┌─────────────────────────────────────────────────────────────┐
│                        RecReplayKit                         │
├─────────────────┬─────────────────┬─────────────────────────┤
│     Recorder    │     Player      │       Validator         │
│   (planned)     │                 │                         │
│                 │  EventPlayer    │  EventValidator         │
│  Captures BLE   │  Real-time      │  ATT symmetry           │
│  events from    │  playback of    │  GATT addressing        │
│  device         │  scenarios      │  Schema rules           │
└─────────────────┴─────────────────┴─────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                           CLI                               │
│                        recreplay                            │
├─────────────────┬─────────────────┬─────────────────────────┤
│    validate     │      info       │         play            │
│    convert      │                 │                         │
└─────────────────┴─────────────────┴─────────────────────────┘
```

## CLI Usage

```bash
# Build
cd Packages/RecReplayKit && swift build

# Commands
recreplay info scenario.json              # Show metadata
recreplay validate scenario.json          # Check for errors
recreplay play scenario.json              # Real-time playback (type :q to quit)
recreplay play --no-realtime scenario.json # Instant dump
recreplay convert old.json -o new.json    # Migrate format

# During playback
:q                # Quit playback
Ctrl+C            # Interrupt

# Options
--format json    # JSON output
--no-color       # Disable colors
--quiet          # Minimal output
```

## Library Usage

```swift
import RecReplayKit

// Load
let scenario = try JSONDecoder().decode(Scenario.self, from: data)

// Validate
let result = EventValidator.validateWithResult(events: scenario.events)

// Play
let player = try EventPlayer(events: scenario.events)
player.eventSubject.sink { event in print(event) }
player.start()
```

## Scenario Format

```json
{
  "version": "1.0",
  "deviceRefs": [{ "deviceId": "device-v1", "instanceId": "device-0" }],
  "events": [
    { "t": 0, "type": "connect", "instanceId": "device-0" },
    { "t": 100, "type": "mtu_request", "instanceId": "device-0", "requestId": "r1", "mtu": 185 },
    { "t": 150, "type": "mtu_response", "instanceId": "device-0", "requestId": "r1", "mtu": 185, "status": "success" }
  ]
}
```
