# Swap Attack — Grid Algorithms Skill

## Purpose
Deep context on the board data model and all algorithms in `scripts/Grid.gd`.

## Data model
`Grid._data` is an `Array[Array]` of size `ROWS × COLS` (12 × 6).  
Each cell holds either `null` (empty) or a Dictionary:
```gdscript
{"color": Constants.BlockColor.<VALUE>, "state": Constants.BlockState.<VALUE>}
```

## Algorithms

### `initialize()`
- Fills rows 6–11 with random `BlockColor` values
- Rejects any placement that would create a run of ≥ 3 same colour (horizontal or vertical)
- Rows 0–5 remain `null`

### `swap(row, col)`
- Swaps `_data[row][col]` ↔ `_data[row][col+1]`
- No-op if both cells are `null` (REQ-2.6)
- Validates bounds; `push_error` on out-of-range

### `find_matches() → Array[Vector2i]`
- Horizontal pass + vertical pass over all IDLE blocks
- Returns deduplicated `Vector2i(col, row)` coords for every cell in a run of ≥ 3
- Non-IDLE (FLASHING) cells are excluded

### `mark_flashing(coords)` / `clear_flashing()`
- `mark_flashing`: sets `state = FLASHING` on each coord
- `clear_flashing`: sets all FLASHING cells to `null`

### `apply_gravity() → bool`
- Per column, moves each non-null, non-FLASHING block one row down if the cell below is `null`
- Returns `true` if any block moved, `false` when fully settled
- Called repeatedly by `FallTimer` until it returns `false`

### `rise_row() → bool`
- Returns `true` (game over) if row 0 has any block **before** shifting
- Shifts rows 0–10 upward; generates a new random row at row 11
- Returns `false` on success

## State machine cycle
```
IDLE → swap → CHECK_MATCHES → FLASHING → CLEARING → FALLING → CHECK_MATCHES → RISING → IDLE
```
Chain reactions: `CHECK_MATCHES` re-enters itself from `FALLING` until `find_matches()` returns empty.
