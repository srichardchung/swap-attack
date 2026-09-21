# Swap Attack

A browser-based, single-player puzzle game inspired by Tetris Attack / Panel de Pon. Swap adjacent colored blocks to create matches, trigger chain reactions, and rack up combo scores.

Built with **Phaser 3**, **TypeScript**, and **Vite**.

## Requirements

- Node.js 18+
- npm 9+

## Setup

```bash
npm install
```

## Development

```bash
npm run dev
```

Opens at [http://localhost:3000](http://localhost:3000) with hot-module replacement.

## Production Build

```bash
npm run build
```

Output goes to `dist/`. Serve with:

```bash
npm run preview
```

## Project Structure

```
src/game/
├── main.ts               # Phaser boot config
├── constants.ts          # Grid dimensions, timing, scoring
├── types.ts              # Shared TypeScript types
├── scenes/
│   ├── BootScene.ts      # Asset preloading
│   ├── GameScene.ts      # Main game loop
│   └── GameOverScene.ts  # Results screen
├── components/
│   ├── Grid.ts           # Grid data model + match/gravity logic
│   ├── Cursor.ts         # Player cursor + input
│   ├── BlockSprite.ts    # Block rendering
│   └── HUD.ts            # Score / chain / combo display
└── state/
    └── GameState.ts      # Reactive score state
```

## Spec

Feature spec lives in `.kiro/specs/swap-attack/`.
