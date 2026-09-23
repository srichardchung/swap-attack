# Swap Attack — Scoring Skill

## Purpose
Exact scoring rules and chain/combo logic for `scripts/GameState.gd` and `GameScene`.

## Score formula
```
score += BASE_POINTS × block_count × combo_mult × chain_level
```
Where:
- `BASE_POINTS = 10`
- `combo_mult = max(1, block_count / 3)`  (integer floor division)
- `chain_level` starts at 1 for the first player-initiated clear in a sequence

## Chain rules
| Event | chain_level |
|---|---|
| Player swap → first clear | 1 (set via `GameState.set_chain(1)`) |
| First gravity-triggered clear after that | 2 |
| Each subsequent gravity clear | increments by 1 |
| Gravity settles, no more matches | resets to 1 |

`GameState.set_chain(level)` enforces a minimum of 1 — never 0.

## Combo vs Chain
- **Combo**: clearing > 3 blocks in a single pass (`block_count > 3`)  
  → `HUD.show_combo_label(block_count)` fires
- **Chain**: a clear triggered by falling blocks after a prior clear  
  → `HUD.show_chain_label(chain_level)` fires when `chain_level > 1`

## Examples
| Scenario | block_count | combo_mult | chain_level | Points |
|---|---|---|---|---|
| Player clears 3 | 3 | 1 | 1 | 30 |
| Gravity chain, 3 blocks | 3 | 1 | 2 | 60 |
| Gravity chain, 6 blocks | 6 | 2 | 2 | 240 |
| 3rd chain, 3 blocks | 3 | 1 | 3 | 90 |

## Rising speed progression
Every 500 score points: `RiseTimer.wait_time -= 0.1` (floor at `0.5s`)
