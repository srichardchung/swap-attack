import Phaser from 'phaser';
import { BootScene } from './scenes/BootScene';
import { GameScene } from './scenes/GameScene';
import { GameOverScene } from './scenes/GameOverScene';
import { CANVAS_WIDTH, CANVAS_HEIGHT } from './constants';

/**
 * main.ts — Phaser game boot configuration.
 * Scenes run in order: BootScene → GameScene ↔ GameOverScene.
 */
const config: Phaser.Types.Core.GameConfig = {
  type: Phaser.AUTO,
  width: CANVAS_WIDTH,
  height: CANVAS_HEIGHT,
  backgroundColor: '#1a1a2e',
  scene: [BootScene, GameScene, GameOverScene],
  parent: document.body,
};

new Phaser.Game(config);
