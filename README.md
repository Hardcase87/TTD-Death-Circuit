# TTD Death Circuit — Outrun Assault v2.0

Compatibility revision 2.0: authored arcade road, five-pose Mutant Maniac, optic-flow speed system and disciplined world dressing.

An original TTD arcade road racer built as a Godot 4 project for import into Xogot.

## Import into Xogot

1. Download and extract the ZIP.
2. In Xogot, choose **Import Project**.
3. Select this folder's `project.godot` file.
4. Open `main.tscn` and press Run.

The project uses the Godot 4 Compatibility renderer and has no plugins or external dependencies.

## Controls

- **Keyboard:** WASD or arrow keys; Space/Shift for nitro.
- **Touch:** lower-left steering pad; lower-right throttle, brake and nitro controls.

## The v2.0 assault

- One authored 90,000-unit Titan City circuit: approximately three minutes at full attack.
- Six district stages with unique full-art horizons, scenery rhythm and road palette.
- One-second cinematic background crossfades synchronized to district gates and HUD announcements.
- Unobstructed district artwork with the obsolete black placeholder skyline removed.
- Hand-authored straights, committed sweepers, S-bends, crests and descents replace generic sine-wave road wandering.
- Speed-reactive horizon, wider high-speed perspective, corner look-ahead and nitro camera punch.
- Dense optic flow from radial streaks, animated roadside reflectors, longer lane rhythm and surface glints.
- Five original Mutant Maniac poses: hard left, soft left, centre, soft right and hard right.
- Visible rotating wheel highlights, tyre contact streaks, suspension travel, drift lean and procedural nitro plasma.
- Shoulder exclusion, hard size limits and a lower-screen safety zone prevent signs from covering the track or touch controls.
- Protected checkpoint approaches keep every district gate readable and driveable.
- World props are sorted once at course build time, removing the former per-frame allocation and sort.
- Higher top speed, harder launch, curve force, drift grip and off-road slowdown produce a more physical arcade line.
- Live top-right route map showing the complete track, district markers and player position.
- Permanent signs installed at fixed world coordinates.
- Image-based drive-through checkpoint gates at every district boundary.
- Layered generated Titan City horizon and original TTD gate artwork.
- Enemies intentionally removed for this handling-and-presentation pass.
- Dynamic synthesized engine tone, responsive HUD, restart flow and mobile landscape layout.

## Project structure

- `main.tscn` — launch scene
- `scripts/main.gd` — racer, projection, track, UI, input and audio
- `assets/environment/` — six generated district horizons, legacy horizon and checkpoint gate
- `assets/vehicles/` — Death Circuit Mutant Maniac player vehicle and legacy Mayhem sprites
- `assets/signs/` — fixed roadside billboards and hazards

Part of the Tactical Terror Division / Titan City universe.
