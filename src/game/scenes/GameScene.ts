import { Grid } from '../components/Grid';
import { Cursor } from '../components/Cursor';
import { HUD } from '../components/HUD';
import { GameState } from '../state/GameState';
import type { SceneState } from '../types';

/**
 * GameScene — main game loop.
 * Stub: full implementation across Phase 4 (Tasks 4.1–4.4).
 */
export class GameScene extends Phaser.Scene {
  private grid!: Grid;
  private cursor!: Cursor;
  private hud!: HUD;
  private gameState!: GameState;
  private sceneState: SceneState = 'IDLE';

  constructor() {
    super({ key: 'GameScene' });
  }

  create(): void {
    this.grid = new Grid(6, 12);
    this.cursor = new Cursor(this);
    this.gameState = new GameState();
    this.hud = new HUD(this, 0, 0);
    this.hud.bind(this.gameState);
    this.sceneState = 'IDLE';
    // TODO Task 4.1 — build BlockSprite pool, wire input, start rising timer
  }

  update(_time: number, delta: number): void {
    this.cursor.update(delta);
    // TODO Task 4.2 — drive state machine
  }
}
