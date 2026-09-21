import type { GameState } from '../state/GameState';

/**
 * HUD — score / chain / combo display container.
 * Stub: full implementation in Phase 3 (Task 3.3).
 */
export class HUD extends Phaser.GameObjects.Container {
  bind(_state: GameState): void {
    // TODO Task 3.3
  }

  showChainLabel(_level: number): void {
    // TODO Task 3.3
  }

  showComboLabel(_count: number): void {
    // TODO Task 3.3
  }
}
