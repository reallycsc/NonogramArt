import json
import os
import sys
from itertools import product

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

def verify_puzzle(path):
    with open(path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    row_clues = data['row_clues']
    col_clues = data['col_clues']
    solution = data['solution']
    hint_cells = data.get('hint_cells', [])
    num_rows = data['size']['rows']
    num_cols = data['size']['cols']
    
    computed_row, computed_col = compute_clues(solution)
    clues_match = (computed_row == row_clues and computed_col == col_clues)
    
    solvable, grid, steps = solve(row_clues, col_clues)
    
    if not solvable and hint_cells:
        grid_with_hints = [[UNKNOWN] * num_cols for _ in range(num_rows)]
        for hc in hint_cells:
            hr, hcc = hc[0], hc[1]
            grid_with_hints[hr][hcc] = FILLED if solution[hr][hcc] == 1 else EMPTY
        
        changed = True
        hint_steps = 0
        while changed:
            changed = False
            hint_steps += 1
            for r in range(num_rows):
                current = [grid_with_hints[r][c] for c in range(num_cols)]
                new_states = line_solve(row_clues[r], current, num_cols)
                for c in range(num_cols):
                    if new_states[c] != UNKNOWN and grid_with_hints[r][c] == UNKNOWN:
                        grid_with_hints[r][c] = new_states[c]
                        changed = True
            for c in range(num_cols):
                current = [grid_with_hints[r][c] for r in range(num_rows)]
                new_states = line_solve(col_clues[c], current, num_rows)
                for r in range(num_rows):
                    if new_states[r] != UNKNOWN and grid_with_hints[r][c] == UNKNOWN:
                        grid_with_hints[r][c] = new_states[r]
                        changed = True
        
        solvable_with_hints = all(cell != UNKNOWN for row in grid_with_hints for row in grid_with_hints for cell in row if isinstance(row, list))
        
        all_determined = True
        for r in range(num_rows):
            for c in range(num_cols):
                if grid_with_hints[r][c] == UNKNOWN:
                    all_determined = False
                    break
            if not all_determined:
                break
        
        if all_determined:
            solvable = True
            grid = grid_with_hints
            steps = hint_steps
    
    solution_match = True
    if solvable:
        for r in range(len(solution)):
            for c in range(len(solution[r])):
                solver_val = 1 if grid[r][c] == FILLED else 0
                if solver_val != solution[r][c]:
                    solution_match = False
                    break
            if not solution_match:
                break
    
    has_hints = len(hint_cells) > 0
    return {
        'id': data['id'],
        'name': data['name'],
        'size': f"{data['size']['rows']}x{data['size']['cols']}",
        'clues_match': clues_match,
        'solvable': solvable,
        'steps': steps if solvable else 0,
        'solution_match': solution_match if solvable else False,
        'has_hints': has_hints,
        'hint_count': len(hint_cells),
        'overall': clues_match and solvable and solution_match
    }

def main():
    base_dir = r"H:\Work\MyProject\ChineseMemory"
    puzzle_dir = os.path.join(base_dir, "data", "puzzles")
    
    eras = ["mythology", "xia_shang_zhou", "spring_autumn", "qin_han",
            "three_kingdoms", "sui_tang", "song_yuan", "ming_qing",
            "modern", "contemporary"]
    
    total = 0
    passed = 0
    failed_list = []
    
    for era_id in eras:
        era_dir = os.path.join(puzzle_dir, era_id)
        if not os.path.exists(era_dir):
            print(f"\n时代 '{era_id}': 无关卡数据")
            continue
        
        files = sorted([f for f in os.listdir(era_dir) if f.endswith('.json')])
        print(f"\n=== 时代: {era_id} ({len(files)} 关卡) ===")
        
        for file_name in files:
            path = os.path.join(era_dir, file_name)
            result = verify_puzzle(path)
            total += 1
            
            status = "[PASS]" if result['overall'] else "[FAIL]"
            solvable_str = "solvable" if result['solvable'] else "NOT solvable"
            hint_str = f" (+{result['hint_count']}hints)" if result['has_hints'] else ""
            print(f"  {result['name']} ({result['size']}): {status} - {solvable_str}{hint_str}" +
                  (f" ({result['steps']}steps)" if result['solvable'] else ""))
            
            if result['overall']:
                passed += 1
            else:
                failed_list.append(f"{era_id}/{file_name}")
                if not result['clues_match']:
                    print(f"    Clues mismatch!")
                if not result['solvable']:
                    print(f"    NOT logically solvable!")
                if result['solvable'] and not result['solution_match']:
                    print(f"    Solution mismatch!")
    
    print(f"\n{'='*50}")
    print(f"Verification done: {passed}/{total} passed")
    if failed_list:
        print(f"Failed puzzles:")
        for f in failed_list:
            print(f"  - {f}")
    else:
        print("All puzzles passed verification!")

if __name__ == "__main__":
    main()
