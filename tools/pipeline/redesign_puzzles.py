import json
import os

UNKNOWN = 0
FILLED = 1
EMPTY = 2

def line_solve(clues, current_states, line_length):
    if not clues or (len(clues) == 1 and clues[0] == 0):
        return [EMPTY] * line_length
    arrangements = generate_arrangements(clues, current_states, line_length)
    if not arrangements:
        return list(current_states)
    result = [UNKNOWN] * line_length
    for i in range(line_length):
        if current_states[i] != UNKNOWN:
            result[i] = current_states[i]
            continue
        all_filled = True
        all_empty = True
        for arr in arrangements:
            if arr[i] == FILLED:
                all_empty = False
            else:
                all_filled = False
        if all_filled:
            result[i] = FILLED
        elif all_empty:
            result[i] = EMPTY
    return result

def generate_arrangements(clues, current_states, line_length):
    results = []
    place_blocks(clues, 0, 0, current_states, line_length, [], results)
    return results

def place_blocks(clues, clue_idx, start_pos, current_states, line_length, partial, results):
    if clue_idx >= len(clues):
        arrangement = [EMPTY] * line_length
        for pos in partial:
            for i in pos:
                arrangement[i] = FILLED
        for i in range(line_length):
            if current_states[i] == FILLED and arrangement[i] != FILLED:
                return
            if current_states[i] == EMPTY and arrangement[i] != EMPTY:
                return
        results.append(arrangement)
        return
    block_size = clues[clue_idx]
    min_remaining = sum(clues[k] + 1 for k in range(clue_idx + 1, len(clues)))
    max_start = line_length - block_size - min_remaining
    for pos in range(start_pos, max_start + 1):
        can_place = True
        for i in range(start_pos, pos):
            if current_states[i] == FILLED:
                can_place = False
                break
        if not can_place:
            break
        block_valid = True
        for i in range(pos, pos + block_size):
            if current_states[i] == EMPTY:
                block_valid = False
                break
        if not block_valid:
            continue
        if pos + block_size < line_length and current_states[pos + block_size] == FILLED:
            if block_size == clues[clue_idx]:
                continue
        new_partial = list(partial)
        block_positions = list(range(pos, pos + block_size))
        new_partial.append(block_positions)
        next_start = pos + block_size + 1
        place_blocks(clues, clue_idx + 1, next_start, current_states, line_length, new_partial, results)

def solve(row_clues, col_clues):
    num_rows = len(row_clues)
    num_cols = len(col_clues)
    grid = [[UNKNOWN] * num_cols for _ in range(num_rows)]
    changed = True
    steps = 0
    while changed:
        changed = False
        steps += 1
        for r in range(num_rows):
            current = [grid[r][c] for c in range(num_cols)]
            new_states = line_solve(row_clues[r], current, num_cols)
            for c in range(num_cols):
                if new_states[c] != UNKNOWN and grid[r][c] == UNKNOWN:
                    grid[r][c] = new_states[c]
                    changed = True
        for c in range(num_cols):
            current = [grid[r][c] for r in range(num_rows)]
            new_states = line_solve(col_clues[c], current, num_rows)
            for r in range(num_rows):
                if new_states[r] != UNKNOWN and grid[r][c] == UNKNOWN:
                    grid[r][c] = new_states[r]
                    changed = True
    solvable = all(cell != UNKNOWN for row in grid for cell in row)
    return solvable, grid, steps

def compute_clues(solution):
    num_rows = len(solution)
    num_cols = len(solution[0]) if num_rows > 0 else 0
    row_clues = []
    for r in range(num_rows):
        segments = []
        count = 0
        for c in range(num_cols):
            if solution[r][c] == 1:
                count += 1
            else:
                if count > 0:
                    segments.append(count)
                count = 0
        if count > 0:
            segments.append(count)
        if not segments:
            segments = [0]
        row_clues.append(segments)
    col_clues = []
    for c in range(num_cols):
        segments = []
        count = 0
        for r in range(num_rows):
            if solution[r][c] == 1:
                count += 1
            else:
                if count > 0:
                    segments.append(count)
                count = 0
        if count > 0:
            segments.append(count)
        if not segments:
            segments = [0]
        col_clues.append(segments)
    return row_clues, col_clues


REDESIGNED_PUZZLES = {
    "xia_shang_zhou": {
        "taigong_hook": {
            "id": "taigong_hook",
            "name": "鱼钩",
            "story_id": "taigong",
            "difficulty": "medium",
            "source_rect": {"x": 64, "y": 0, "w": 128, "h": 128},
            "solution": [
                [0,0,0,0,0,0,0,0,1,1],
                [0,0,0,0,0,0,0,0,1,1],
                [0,0,0,0,0,0,0,0,1,1],
                [0,0,0,0,0,0,0,0,1,1],
                [0,0,0,0,0,0,0,0,1,1],
                [0,0,0,0,0,0,0,0,1,1],
                [0,0,0,0,1,0,0,1,1,0],
                [0,0,0,1,1,1,1,1,0,0],
                [0,0,1,1,1,1,1,0,0,0],
                [0,1,1,1,1,1,0,0,0,0]
            ]
        }
    },
    "song_yuan": {
        "yuefei_spear": {
            "id": "yuefei_spear",
            "name": "长枪",
            "story_id": "yuefei",
            "difficulty": "medium",
            "source_rect": {"x": 64, "y": 0, "w": 128, "h": 128},
            "solution": [
                [0,0,0,0,0,1,0,0,0,0],
                [0,0,0,0,1,1,1,0,0,0],
                [0,0,0,0,0,1,0,0,0,0],
                [0,0,0,0,0,1,0,0,0,0],
                [0,0,0,0,0,1,0,0,0,0],
                [0,0,0,0,0,1,0,0,0,0],
                [0,0,0,0,0,1,0,0,0,0],
                [0,0,0,0,0,1,0,0,0,0],
                [0,0,0,0,0,1,0,0,0,0],
                [0,0,0,0,0,1,0,0,0,0]
            ]
        }
    },
    "ming_qing": {
        "linzexu_pipe": {
            "id": "linzexu_pipe",
            "name": "烟管",
            "story_id": "linzexu",
            "difficulty": "medium",
            "source_rect": {"x": 64, "y": 0, "w": 128, "h": 128},
            "solution": [
                [0,0,0,0,0,0,0,0,1,1],
                [0,0,0,0,0,0,0,0,1,1],
                [0,0,0,0,0,0,0,0,1,1],
                [0,0,0,0,0,0,0,0,1,1],
                [0,0,0,0,0,0,0,0,1,1],
                [0,0,0,0,0,0,0,0,1,1],
                [0,0,0,0,0,0,0,0,1,1],
                [0,0,0,0,0,0,0,0,1,1],
                [0,0,0,0,0,0,1,1,1,1],
                [0,0,0,0,0,1,1,1,1,1]
            ]
        }
    }
}


def main():
    base_dir = r"H:\Work\MyProject\ChineseMemory"
    puzzle_dir = os.path.join(base_dir, "data", "puzzles")
    
    for era_id, puzzles in REDESIGNED_PUZZLES.items():
        for puzzle_id, config in puzzles.items():
            path = os.path.join(puzzle_dir, era_id, puzzle_id + ".json")
            solution = config["solution"]
            row_clues, col_clues = compute_clues(solution)
            
            solvable, grid, steps = solve(row_clues, col_clues)
            
            puzzle_data = {
                "id": config["id"],
                "name": config["name"],
                "story_id": config["story_id"],
                "size": {"rows": len(solution), "cols": len(solution[0])},
                "difficulty": config["difficulty"],
                "row_clues": row_clues,
                "col_clues": col_clues,
                "solution": solution,
                "hint_cells": [],
                "source_rect": config["source_rect"]
            }
            
            with open(path, 'w', encoding='utf-8') as f:
                json.dump(puzzle_data, f, ensure_ascii=False, indent='\t')
            
            status = "SOLVABLE" if solvable else "NOT SOLVABLE"
            print(f"  {era_id}/{puzzle_id}: {status} ({steps} steps)")

    print("\nRedesigned puzzles saved!")

if __name__ == "__main__":
    main()
