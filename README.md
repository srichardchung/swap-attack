# Swap Attack

A desktop single-player puzzle game inspired by Tetris Attack / Panel de Pon.
Swap adjacent coloured blocks to create matches, trigger chain reactions, and rack up combo scores.

Built with **Godot 4.7.2** and **GDScript** as part of the Kiro University Challenge.

---

## Requirements

- [Godot 4.7.2](https://godotengine.org/download) — standard build (no Mono/C# required)

---

## How to run

1. Clone the repository:
   ```
   git clone git@github.com:srichardchung/swap-attack.git
   ```
2. Open **Godot 4.7.2**.
3. Click **Import** and select `project.godot` at the repository root.
4. Press **F5** (or the ▶ Play button) to run from `scenes/Main.tscn`.

---

## Controls

| Action | Keys |
|---|---|
| Move cursor left / right | ← → or A / D |
| Move cursor up / down | ↑ ↓ or W / S |
| Swap blocks | Space or X |

---

## How to play

- A **2-wide cursor** highlights two adjacent cells. Press **Space / X** to swap them.
- Match **3 or more** same-coloured blocks in a row or column to clear them.
- Blocks fall after clears — **chain reactions** earn multiplied points.
- Clearing more than 3 blocks at once triggers a **combo bonus**.
- New rows rise from the bottom at increasing speed. The game ends when blocks reach the top.

---

## Scoring

```
Points = BASE_POINTS(10) × block_count × combo_mult × chain_level

combo_mult  = max(1, block_count / 3)
chain_level = 1 for first clear, increments on each gravity-triggered chain
```

---

## Project structure

```
swap-attack/
├── project.godot            ← Godot project file + Input Map + Autoloads
├── scenes/
│   ├── Main.tscn            ← entry scene (instances GameScene)
│   ├── GameScene.tscn       ← main play field + state machine
│   ├── Block.tscn           ← reusable block node
│   └── GameOverScene.tscn   ← results screen
├── scripts/
│   ├── Constants.gd         ← Autoload: all shared constants and enums
│   ├── GameState.gd         ← Autoload: reactive score / chain / combo state
│   ├── AudioManager.gd      ← Autoload: audio stub
│   ├── Grid.gd              ← board data + match / gravity algorithms
│   ├── Cursor.gd            ← player cursor + key-repeat input
│   ├── Block.gd             ← per-block procedural rendering
│   ├── HUD.gd               ← score / chain / combo display
│   └── GameScene.gd         ← scene orchestration + game loop
├── assets/
│   ├── sprites/             ← block textures (procedurally generated at runtime)
│   └── fonts/               ← HUD font placeholder
└── .kiro/
    ├── specs/swap-attack/   ← requirements, design, tasks
    ├── steering/            ← project conventions steering file
    ├── hooks/               ← PostFileSave + PostTaskExec hooks
    ├── agents/              ← grid-dev + game-review custom agents
    └── powers/swap-attack-power/  ← custom Kiro power with 3 skills
```

---

## Kiro University Challenge features demonstrated

| Lesson | Feature | Location |
|---|---|---|
| 1 | Vibe mode + Spec (requirements → design → tasks) | `.kiro/specs/swap-attack/` |
| 2 | Steering files | `.kiro/steering/project.md` |
| 3 | Hooks (PostFileSave convention checker, PostTaskExec changelog) | `.kiro/hooks/` |
| 4 | Property-based testing (Grid.gd testable logic) | `scripts/Grid.gd` |
| 5 | Powers (swap-attack-power with 3 skills) | `.kiro/powers/swap-attack-power/` |
| 6 | MCP servers (fetch + filesystem) | `mcp.json` |
| 7 | Custom agents (grid-dev, game-review) | `.kiro/agents/` |
| Bonus 2 | Packaged Kiro power with full plugin.json schema | `.kiro/powers/swap-attack-power/plugin.json` |
