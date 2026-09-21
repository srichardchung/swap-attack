# Swap Attack project guidance

## Purpose

Build a browser-based, single-player puzzle game where the player swaps adjacent blocks to create matches, chains, and combos. Use the feature spec in `.kiro/specs/swap-attack/` as the source for game behavior and implementation order.

## Technology and structure

- Use Phaser 3, TypeScript, and Vite as specified in `design.md`. This repository is a standalone game, so do not add Angular, PrimeNG, Bootstrap, or NgRx dependencies.
- Keep grid data and match rules in `src/game/components/Grid.ts`. Keep scene transitions and timing in `src/game/scenes/GameScene.ts`. Keep score state in `src/game/state/GameState.ts`.
- Keep shared dimensions, timing, and scoring values in `src/game/constants.ts`; use the types in `src/game/types.ts` across components.
- Bundle all runtime assets locally under `public/assets/`. Do not depend on a CDN at runtime.

## Implementation conventions

- Use strict TypeScript with explicit public types and no implicit `any`.
- Treat row 0 as the top and row 11 as the bottom; treat column 0 as the left edge. A cursor position identifies the left cell of its two-cell span.
- Prefer small, verifiable changes in the order listed in `tasks.md`. Mark a task complete only after its acceptance checks pass.
- Run `npx tsc --noEmit` and `npm run build` after implementing code. Exercise gameplay behavior for changes to swaps, matching, gravity, scoring, or game over.
- When the spec conflicts with itself, identify the conflict and resolve it against the functional requirements before implementation. Record the decision in the spec so later tasks use the same rule.

## Example

For a horizontal swap, call `Grid.swap(row, col)` with a zero-based `col` in `[0, COLS - 2]` and swap only `data[row][col]` with `data[row][col + 1]`. Reject out-of-bounds coordinates instead of wrapping to another row.
