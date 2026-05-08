import json
import os
import copy

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

def find_hint_cells(row_clues, col_clues, solution, max_hints=10):
    num_rows = len(row_clues)
    num_cols = len(col_clues)
    
    grid = [[UNKNOWN] * num_cols for _ in range(num_rows)]
    
    changed = True
    while changed:
        changed = False
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
    
    stuck_cells = []
    for r in range(num_rows):
        for c in range(num_cols):
            if grid[r][c] == UNKNOWN:
                row_unknowns = sum(1 for cc in range(num_cols) if grid[r][cc] == UNKNOWN)
                col_unknowns = sum(1 for rr in range(num_rows) if grid[rr][c] == UNKNOWN)
                stuck_cells.append((r, c, row_unknowns + col_unknowns))
    
    stuck_cells.sort(key=lambda x: x[2])
    
    hint_cells = []
    for r, c, _ in stuck_cells:
        if len(hint_cells) >= max_hints:
            break
        hint_cells.append([r, c])
        
        test_grid = [row[:] for row in grid]
        for hr, hc in hint_cells:
            test_grid[hr][hc] = FILLED if solution[hr][hc] == 1 else EMPTY
        
        test_changed = True
        while test_changed:
            test_changed = False
            for rr in range(num_rows):
                current = [test_grid[rr][cc] for cc in range(num_cols)]
                new_states = line_solve(row_clues[rr], current, num_cols)
                for cc in range(num_cols):
                    if new_states[cc] != UNKNOWN and test_grid[rr][cc] == UNKNOWN:
                        test_grid[rr][cc] = new_states[cc]
                        test_changed = True
            for cc in range(num_cols):
                current = [test_grid[rr][cc] for rr in range(num_rows)]
                new_states = line_solve(col_clues[cc], current, num_rows)
                for rr in range(num_rows):
                    if new_states[rr] != UNKNOWN and test_grid[rr][cc] == UNKNOWN:
                        test_grid[rr][cc] = new_states[rr]
                        test_changed = True
        
        all_determined = all(cell != UNKNOWN for row in test_grid for cell in row)
        if all_determined:
            return hint_cells
    
    return hint_cells

def main():
    base_dir = r"H:\Work\MyProject\ChineseMemory"
    puzzle_dir = os.path.join(base_dir, "data", "puzzles")
    
    eras = ["mythology", "xia_shang_zhou", "spring_autumn", "qin_han",
            "three_kingdoms", "sui_tang", "song_yuan", "ming_qing",
            "modern", "contemporary"]
    
    fixed_count = 0
    still_failing = 0
    
    for era_id in eras:
        era_dir = os.path.join(puzzle_dir, era_id)
        if not os.path.exists(era_dir):
            continue
        
        files = sorted([f for f in os.listdir(era_dir) if f.endswith('.json')])
        
        for file_name in files:
            path = os.path.join(era_dir, file_name)
            with open(path, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            solution = data['solution']
            computed_row, computed_col = compute_clues(solution)
            
            clues_fixed = False
            if computed_row != data['row_clues'] or computed_col != data['col_clues']:
                data['row_clues'] = computed_row
                data['col_clues'] = computed_col
                clues_fixed = True
            
            solvable, grid, steps = solve(data['row_clues'], data['col_clues'])
            
            if not solvable:
                hint_cells = find_hint_cells(data['row_clues'], data['col_clues'], solution)
                if hint_cells:
                    data['hint_cells'] = hint_cells
                    
                    test_grid = [[UNKNOWN] * len(data['row_clues'][0]) if data['row_clues'][0] != [0] else [UNKNOWN] * data['size']['cols'] for _ in range(data['size']['rows'])]
                    num_rows = data['size']['rows']
                    num_cols = data['size']['cols']
                    test_grid = [[UNKNOWN] * num_cols for _ in range(num_rows)]
                    
                    for hr, hc in hint_cells:
                        test_grid[hr][hc] = FILLED if solution[hr][hc] == 1 else EMPTY
                    
                    test_changed = True
                    while test_changed:
                        test_changed = False
                        for r in range(num_rows):
                            current = [test_grid[r][c] for c in range(num_cols)]
                            new_states = line_solve(data['row_clues'][r], current, num_cols)
                            for c in range(num_cols):
                                if new_states[c] != UNKNOWN and test_grid[r][c] == UNKNOWN:
                                    test_grid[r][c] = new_states[c]
                                    test_changed = True
                        for c in range(num_cols):
                            current = [test_grid[r][c] for r in range(num_rows)]
                            new_states = line_solve(data['col_clues'][c], current, num_rows)
                            for r in range(num_rows):
                                if new_states[r] != UNKNOWN and test_grid[r][c] == UNKNOWN:
                                    test_grid[r][c] = new_states[r]
                                    test_changed = True
                    
                    all_determined = all(cell != UNKNOWN for row in test_grid for cell in row)
                    if all_determined:
                        print(f"  FIXED with {len(hint_cells)} hints: {era_id}/{file_name}")
                        fixed_count += 1
                    else:
                        print(f"  STILL FAILING: {era_id}/{file_name} ({len(hint_cells)} hints not enough)")
                        still_failing += 1
                else:
                    print(f"  STILL FAILING: {era_id}/{file_name} (no hint cells found)")
                    still_failing += 1
            elif clues_fixed:
                print(f"  FIXED clues: {era_id}/{file_name}")
                fixed_count += 1
            
            with open(path, 'w', encoding='utf-8') as f:
                json.dump(data, f, ensure_ascii=False, indent='\t')
    
    print(f"\nFixed: {fixed_count}, Still failing: {still_failing}")

if __name__ == "__main__":
    main()
