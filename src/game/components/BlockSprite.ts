import type { BlockColor } from '../types';

/**
 * BlockSprite — visual wrapper for a single grid cell.
 * Stub: full implementation in Phase 3 (Task 3.2).
 */
export class BlockSprite extends Phaser.GameObjects.Sprite {
  constructor(scene: Phaser.Scene, x: number, y: number, color: BlockColor) {
    super(scene, x, y, color);
  }

  playFlash(): void {
    // TODO Task 3.2
  }

  setEmpty(): void {
    // TODO Task 3.2
    this.setVisible(false);
  }
}
