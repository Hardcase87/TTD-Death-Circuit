# TTD Death Circuit — Xogot Overkill Pass

Compatibility revision 1.3: Mutant Maniac vehicle, rolling tyres and procedural nitro plasma.

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

## The Overkill pass

- One authored 90,000-unit Titan City circuit: approximately three minutes at full attack.
- Six district stages with distinct sky treatment, weather, scenery rhythm and road palette.
- Proper road curvature, hills, lane markings, shoulders, drift grip and off-road slowdown.
- Live top-right route map showing the complete track, district markers and player position.
- Permanent signs installed at fixed world coordinates.
- Image-based drive-through checkpoint gates at every district boundary.
- Layered generated Titan City horizon and original TTD gate artwork.
- Enemies intentionally removed for this handling-and-presentation pass.
- New Death Circuit Mutant Maniac player car with realistic mutant armour, exposed machinery and preserved TTD/MAYHEM identity.
- Speed-linked tyre tread animation, contact-patch streaks, suspension movement, steering roll and procedural nitro plasma.
- Dynamic synthesized engine tone, responsive HUD, restart flow and mobile landscape layout.

## Project structure

- `main.tscn` — launch scene
- `scripts/main.gd` — racer, projection, track, UI, input and audio
- `assets/environment/` — generated horizon and checkpoint gate
- `assets/vehicles/` — Death Circuit Mutant Maniac player vehicle and legacy Mayhem sprites
- `assets/signs/` — fixed roadside billboards and hazards

Part of the Tactical Terror Division / Titan City universe.
