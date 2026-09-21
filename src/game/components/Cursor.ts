import type { CursorState } from '../types';

/**
 * Cursor — wraps cursor position and keyboard input.
 * Stub: full implementation in Phase 2 (Task 2.1).
 */
export class Cursor {
  state: CursorState = { row: 5, col: 2 };

  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  constructor(_scene: Phaser.Scene) {}

  update(_delta: number): void {
    // TODO Task 2.1
  }

  getPosition(): CursorState {
    return this.state;
  }
}
