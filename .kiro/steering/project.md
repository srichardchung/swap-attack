# Swap Attack — Project Steering

## Purpose

Build a desktop, single-player puzzle game where the player swaps adjacent blocks to create matches, chains, and combos. Use the feature spec in `.kiro/specs/swap-attack/` as the authoritative source for game behaviour and implementation order.

---

## Engine and Language

| Concern | Choice |
|---|---|
| Engine | **Godot 4.7.2** |
| Language | **GDScript** (`.gd` files only) |
| Scene format | Godot `.tscn` (text scenes) and `.tres` (resources) |
| Export target | Desktop (Windows / macOS / Linux) via Godot export presets |

**Do not** add any of the following to this project:
- Phaser, TypeScript, Vite, npm, Node.js, or any JavaScript/web stack
- Angular, PrimeNG, Bootstrap, or NgRx
- HTML entry points, `package.json`, `tsconfig.json`, or `vite.config.*`
- CDN-hosted assets at runtime

---

## Repository Layout

```
swap-attack/
├── .kiro/
│   ├── specs/swap-attack/
│   │   ├── requirements.md
│   │   ├── design.md
│   │   └── tasks.md
│   └── steering/
│       └── project.md
├── project.godot            ← Godot project file
├── scenes/
│   ├── Main.tscn            ← entry scene set in project.godot
│   ├── GameScene.tscn       ← active play field
│   └── GameOverScene.tscn   ← results screen
├── scripts/
│   ├── Grid.gd              ← board data + match / gravity logic
│   ├── Cursor.gd            ← cursor position + input
│   ├── Block.gd             ← per-block state node
│   ├── HUD.gd               ← score / chain / combo display
│   └── GameState.gd         ← autoload: reactive score state
├── assets/
│   ├── sprites/             ← block textures (6 colours + flash frame)
│   └── fonts/               ← bitmap font for HUD
└── README.md
```

---

## File Ownership Rules

| Concern | File |
|---|---|
| Grid data + match / clear / gravity algorithms | `scripts/Grid.gd` |
| Scene transitions, state machine, timing | `scenes/GameScene.tscn` + attached script |
| Score, chain, combo reactive state | `scripts/GameState.gd` (Autoload) |
| Shared constants | `scripts/Constants.gd` (Autoload) |
| Player input actions | Godot **Input Map** in `project.godot` |

---

## Implementation Conventions

- Write all scripts in **GDScript**; use `class_name` declarations for any script intended to be referenced by type elsewhere.
- Use `static func` for pure logic that does not need node context (e.g. match-detection helpers).
- Row 0 = top of the board; row 11 = bottom. Column 0 = left edge. A cursor position identifies the **left cell** of its two-cell span.
- Prefer **signals** over direct method calls for cross-node communication (e.g. `block_cleared`, `chain_updated`, `game_over`).
- Register all player controls in the **Input Map** (`ui_left`, `ui_right`, `ui_up`, `ui_down`, `swap`); do not hard-code `KEY_*` constants in scripts.
- Keep shared numeric constants (grid size, timing, scoring) in `Constants.gd`; import via the Autoload name.
- Prefer small, verifiable changes in the order listed in `tasks.md`. Mark a task complete only after its acceptance checks pass.
- After implementing logic changes run the scene in the Godot editor to verify gameplay behaviour; use the built-in debugger for breakpoints.
- When the spec conflicts with itself, identify the conflict, resolve it against the functional requirements, record the decision in the spec, then implement.

---

## Coordinate Convention (authoritative)

```
col  0   1   2   3   4   5
row 0 [ ][ ][ ][ ][ ][ ]   ← top (visible play area starts here)
row 1 [ ][ ][ ][ ][ ][ ]
...
row11 [ ][ ][ ][ ][ ][ ]   ← bottom (new rows rise from below)
```

Cursor `col` is the index of its **left** cell; valid range `[0, COLS-2]` = `[0, 4]`.
