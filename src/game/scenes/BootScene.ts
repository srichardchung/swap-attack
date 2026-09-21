/**
 * BootScene — preloads all game assets then starts GameScene.
 * Stub: full implementation in Phase 3 (Task 3.1).
 */
export class BootScene extends Phaser.Scene {
  constructor() {
    super({ key: 'BootScene' });
  }

  preload(): void {
    // TODO Task 3.1 — load block sprite sheet and bitmap font
  }

  create(): void {
    this.scene.start('GameScene');
  }
}
