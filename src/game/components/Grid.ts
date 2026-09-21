import type { GridData, GridCell, CellCoord } from '../types';

/**
 * Grid — owns all playfield data and mutation logic.
 * Stub: full implementation in Phase 1 (Tasks 1.2–1.7).
 */
export class Grid {
  readonly data: GridData;

  constructor(cols: number, rows: number) {
    this.data = Array.from({ length: rows }, () =>
      Array.from<GridCell>({ length: cols }).fill(null)
    );
  }

  initialize(): void {
    // TODO Task 1.2
  }

  swap(_row: number, _col: number): void {
    // TODO Task 1.3
  }

  findMatches(): CellCoord[] {
    // TODO Task 1.4
    return [];
  }

  markFlashing(_matches: CellCoord[]): void {
    // TODO Task 1.5
  }

  clearFlashing(): void {
    // TODO Task 1.5
  }

  applyGravity(): boolean {
    // TODO Task 1.6
    return false;
  }

  riseRow(): boolean {
    // TODO Task 1.7
    return false;
  }
}
