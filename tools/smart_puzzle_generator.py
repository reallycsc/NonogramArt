import os
import json

UNKNOWN = 0
FILLED = 1
EMPTY = 2


class NonogramSolver:
    @staticmethod
    def solve(row_clues, col_clues):
        rows = len(row_clues)
        cols = len(col_clues)
        grid = [[UNKNOWN] * cols for _ in range(rows)]

        changed = True
        max_iter = rows * cols * 10

        for _ in range(max_iter):
            if not changed:
                break
            changed = False

            for i in range(rows):
                current = [grid[i][c] for c in range(cols)]
                new_states = NonogramSolver._line_solve(row_clues[i], current, cols)
                for c in range(cols):
                    if new_states[c] != UNKNOWN and grid[i][c] == UNKNOWN:
                        grid[i][c] = new_states[c]
                        changed = True

            for j in range(cols):
                current = [grid[r][j] for r in range(rows)]
                new_states = NonogramSolver._line_solve(col_clues[j], current, rows)
                for r in range(rows):
                    if new_states[r] != UNKNOWN and grid[r][j] == UNKNOWN:
                        grid[r][j] = new_states[r]
                        changed = True

        solvable = all(cell != UNKNOWN for row in grid for cell in row)
        known_count = sum(1 for row in grid for cell in row if cell != UNKNOWN)

        return {
            "solvable": solvable,
            "solution": [[1 if cell == FILLED else 0 for cell in row] for row in grid],
            "known_cells": known_count,
            "total_cells": rows * cols,
        }

    @staticmethod
    def _line_solve(clues, current_states, line_length):
        if not clues or (len(clues) == 1 and clues[0] == 0):
            return [EMPTY] * line_length

        arrangements = NonogramSolver._generate_arrangements(clues, current_states, line_length)
        if not arrangements:
            return list(current_states)

        result = [UNKNOWN] * line_length
        for i in range(line_length):
            if current_states[i] != UNKNOWN:
                result[i] = current_states[i]
                continue
            all_filled = all(arr[i] == FILLED for arr in arrangements)
            all_empty = all(arr[i] == EMPTY for arr in arrangements)
            if all_filled:
                result[i] = FILLED
            elif all_empty:
                result[i] = EMPTY
        return result

    @staticmethod
    def _generate_arrangements(clues, current_states, line_length):
        results = []
        NonogramSolver._place_blocks(clues, 0, 0, current_states, line_length, [], results)
        return results

    @staticmethod
    def _place_blocks(clues, clue_idx, start_pos, current_states, line_length, partial, results):
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
            NonogramSolver._place_blocks(clues, clue_idx + 1, next_start, current_states, line_length, new_partial, results)

ERA_CONFIG = {
    "mythology": {"size": 5, "difficulty": "easy"},
    "xia_shang_zhou": {"size": 8, "difficulty": "easy"},
    "spring_autumn": {"size": 10, "difficulty": "medium"},
    "qin_han": {"size": 12, "difficulty": "medium"},
    "three_kingdoms": {"size": 15, "difficulty": "medium"},
    "sui_tang": {"size": 15, "difficulty": "medium"},
    "song_yuan": {"size": 18, "difficulty": "hard"},
    "ming_qing": {"size": 20, "difficulty": "hard"},
    "modern": {"size": 20, "difficulty": "hard"},
    "contemporary": {"size": 20, "difficulty": "hard"}
}

def create_pattern(size, seed):
    patterns = [
        create_full_row_pattern,
        create_full_col_pattern,
        create_center_cross_pattern,
        create_square_pattern,
        create_frame_pattern,
        create_stripe_pattern,
        create_gradient_pattern,
        create_symmetrical_pattern
    ]
    
    pattern_func = patterns[seed % len(patterns)]
    return pattern_func(size)

def create_full_row_pattern(size):
    grid = [[0]*size for _ in range(size)]
    for i in range(size):
        for j in range(size):
            if i < size // 2:
                grid[i][j] = 1
    return grid

def create_full_col_pattern(size):
    grid = [[0]*size for _ in range(size)]
    for i in range(size):
        for j in range(size):
            if j < size // 2:
                grid[i][j] = 1
    return grid

def create_center_cross_pattern(size):
    grid = [[0]*size for _ in range(size)]
    mid = size // 2
    for i in range(size):
        grid[i][mid] = 1
    for j in range(size):
        grid[mid][j] = 1
    return grid

def create_square_pattern(size):
    grid = [[0]*size for _ in range(size)]
    border = size // 4
    for i in range(border, size - border):
        for j in range(border, size - border):
            grid[i][j] = 1
    return grid

def create_frame_pattern(size):
    grid = [[0]*size for _ in range(size)]
    for i in range(size):
        for j in range(size):
            if i == 0 or i == size-1 or j == 0 or j == size-1:
                grid[i][j] = 1
    return grid

def create_stripe_pattern(size):
    grid = [[0]*size for _ in range(size)]
    for i in range(size):
        for j in range(size):
            if i % 2 == 0:
                grid[i][j] = 1
    return grid

def create_gradient_pattern(size):
    grid = [[0]*size for _ in range(size)]
    for i in range(size):
        for j in range(size):
            if j <= i:
                grid[i][j] = 1
    return grid

def create_symmetrical_pattern(size):
    grid = [[0]*size for _ in range(size)]
    for i in range(size):
        for j in range(size):
            if abs(i - size//2) + abs(j - size//2) <= size//3:
                grid[i][j] = 1
    return grid

def compute_clues(grid):
    size = len(grid)
    row_clues = []
    for i in range(size):
        clues = []
        current = 0
        for j in range(size):
            if grid[i][j] == 1:
                current += 1
            else:
                if current > 0:
                    clues.append(current)
                    current = 0
        if current > 0:
            clues.append(current)
        row_clues.append(clues if clues else [0])
    
    col_clues = []
    for j in range(size):
        clues = []
        current = 0
        for i in range(size):
            if grid[i][j] == 1:
                current += 1
            else:
                if current > 0:
                    clues.append(current)
                    current = 0
        if current > 0:
            clues.append(current)
        col_clues.append(clues if clues else [0])
    
    return row_clues, col_clues

def generate_solvable_puzzle(puzzle_id, name, story_id, size, difficulty):
    seed = hash(puzzle_id)
    max_attempts = 100
    
    for attempt in range(max_attempts):
        pattern_seed = seed + attempt
        grid = create_pattern(size, pattern_seed)
        row_clues, col_clues = compute_clues(grid)
        
        result = NonogramSolver.solve(row_clues, col_clues)
        
        if result['solvable']:
            return {
                'id': puzzle_id,
                'name': name,
                'story_id': story_id,
                'size': {'rows': size, 'cols': size},
                'difficulty': difficulty,
                'row_clues': row_clues,
                'col_clues': col_clues,
                'solution': grid,
                'hint_cells': [],
                'source_rect': {'x': 0, 'y': 0, 'w': 128, 'h': 128}
            }
    
    grid = create_simple_fallback_pattern(size)
    row_clues, col_clues = compute_clues(grid)
    
    return {
        'id': puzzle_id,
        'name': name,
        'story_id': story_id,
        'size': {'rows': size, 'cols': size},
        'difficulty': difficulty,
        'row_clues': row_clues,
        'col_clues': col_clues,
        'solution': grid,
        'hint_cells': [[size//2, size//2]],
        'source_rect': {'x': 0, 'y': 0, 'w': 128, 'h': 128}
    }

def create_simple_fallback_pattern(size):
    grid = [[0]*size for _ in range(size)]
    mid = size // 2
    for j in range(size):
        grid[mid][j] = 1
    return grid

def main():
    puzzles_dir = "h:/Work/MyProject/ChineseMemory/data/puzzles"
    stories_dir = "h:/Work/MyProject/ChineseMemory/data/stories"
    
    print("=" * 60)
    print("智能生成可推理的数织谜题")
    print("=" * 60)
    
    for era_id, config in ERA_CONFIG.items():
        size = config['size']
        difficulty = config['difficulty']
        
        era_puzzle_dir = os.path.join(puzzles_dir, era_id)
        os.makedirs(era_puzzle_dir, exist_ok=True)
        
        story_file = os.path.join(stories_dir, f"{era_id}.json")
        if not os.path.exists(story_file):
            continue
        
        with open(story_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        for story in data['stories']:
            for puzzle_id in story['puzzles']:
                puzzle_name = puzzle_id.replace(f"{story['id']}_", '')
                puzzle = generate_solvable_puzzle(puzzle_id, puzzle_name, story['id'], size, difficulty)
                
                puzzle_path = os.path.join(era_puzzle_dir, f"{puzzle_id}.json")
                with open(puzzle_path, 'w', encoding='utf-8') as f:
                    json.dump(puzzle, f, indent='\t', ensure_ascii=False)
        
        print(f"生成谜题: {era_id} ({size}x{size}, {difficulty})")
    
    print("\n" + "=" * 60)
    print("智能生成完成！")
    print("=" * 60)

if __name__ == "__main__":
    main()