# Swap Attack

A desktop single-player puzzle game inspired by Tetris Attack / Panel de Pon.
Swap adjacent coloured blocks to create matches, trigger chain reactions, and rack up combo scores.

Built with **Godot 4.7.2** and **GDScript**.

## Requirements

- [Godot 4.7.2](https://godotengine.org/download) (standard build, no Mono/C# required)

## Running the game

1. Open Godot 4.7.2.
2. Click **Import** and select the `project.godot` file at the root of this repository.
3. Press **F5** (or the Play button) to run from `scenes/Main.tscn`.

## Project structure

```
swap-attack/
├── project.godot            ← Godot project file and Input Map
├── scenes/
│   ├── Main.tscn            ← entry scene
│   ├── GameScene.tscn       ← main play field
│   ├── Block.tscn           ← reusable block node
│   └── GameOverScene.tscn   ← results screen
├── scripts/
│   ├── Constants.gd         ← Autoload: grid dimensions, timing, scoring
│   ├── GameState.gd         ← Autoload: reactive score / chain / combo state
│   ├── Grid.gd              ← board data + match / gravity algorithms
│   ├── Cursor.gd            ← player cursor + key-repeat input
│   ├── Block.gd             ← per-block visual state
│   ├── HUD.gd               ← score / chain / combo display
│   └── AudioManager.gd      ← audio stub (future use)
└── assets/
    ├── sprites/             ← block textures (6 colours + flash frame)
    └── fonts/               ← HUD font
```

## Controls

| Action | Keys |
|---|---|
| Move cursor | Arrow keys or WASD |
| Swap blocks | Space or X |

## Spec

Feature spec and design documents live in `.kiro/specs/swap-attack/`.
