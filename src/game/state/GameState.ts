import type { GameStateData } from '../types';

/**
 * Lightweight reactive store for score, chain, and combo state.
 * Minimum valid chainLevel is 1. setChain(1) resets between chains.
 */
export class GameState {
  private data: GameStateData = {
    score: 0,
    chainLevel: 1,
    highestCombo: 0,
    isGameOver: false,
  };

  private listeners: Array<(data: Readonly<GameStateData>) => void> = [];

  get(): Readonly<GameStateData> {
    return this.data;
  }

  addScore(points: number): void {
    this.data.score += points;
    this.notify();
  }

  /** Sets the active chain level. Minimum valid value is 1. */
  setChain(level: number): void {
    this.data.chainLevel = Math.max(1, level);
    this.notify();
  }

  updateHighestCombo(count: number): void {
    if (count > this.data.highestCombo) {
      this.data.highestCombo = count;
      this.notify();
    }
  }

  setGameOver(): void {
    this.data.isGameOver = true;
    this.notify();
  }

  onChange(fn: (data: Readonly<GameStateData>) => void): void {
    this.listeners.push(fn);
  }

  private notify(): void {
    for (const fn of this.listeners) {
      fn(this.data);
    }
  }
}
