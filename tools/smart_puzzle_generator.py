import os
import json

class NonogramSolver:
    @staticmethod
    def solve(row_clues, col_clues):
        rows = len(row_clues)
        cols = len(col_clues)
        grid = [[0]*cols for _ in range(rows)]
        known = [[False]*cols for _ in range(rows)]
        
        changed = True
        max_iter = rows * cols * 5
        
        for _ in range(max_iter):
            if not changed:
                break
            changed = False
            
            for i in range(rows):
                clues = row_clues[i]
                possible = NonogramSolver._get_line_permutations(clues, cols)
                for j in range(cols):
                    if known[i][j]:
                        continue
                    all_filled = all(p[j] == 1 for p in possible)
                    all_empty = all(p[j] == 0 for p in possible)
                    if all_filled:
                        grid[i][j] = 1
                        known[i][j] = True
                        changed = True
                    elif all_empty:
                        grid[i][j] = 0
                        known[i][j] = True
                        changed = True
            
            for j in range(cols):
                clues = col_clues[j]
                possible = NonogramSolver._get_line_permutations(clues, rows)
                for i in range(rows):
                    if known[i][j]:
                        continue
                    col_vals = [p[i] for p in possible]
                    all_filled = all(v == 1 for v in col_vals)
                    all_empty = all(v == 0 for v in col_vals)
                    if all_filled:
                        grid[i][j] = 1
                        known[i][j] = True
                        changed = True
                    elif all_empty:
                        grid[i][j] = 0
                        known[i][j] = True
                        changed = True
        
        return {
            'solvable': all(all(row) for row in known),
            'solution': grid,
            'known_cells': sum(sum(row) for row in known),
            'total_cells': rows * cols
        }
    
    @staticmethod
    def _get_line_permutations(clues, length):
        if not clues or clues == [0]:
            return [[0]*length]
        
        total_filled = sum(clues)
        total_gaps = len(clues) - 1
        min_len = total_filled + total_gaps
        
        if min_len > length:
            return []
        
        result = []
        NonogramSolver._generate_permutations(clues, length, 0, [], result)
        return result
    
    @staticmethod
    def _generate_permutations(clues, length, start, current, result):
        if not clues:
            if start <= length:
                result.append(current + [0]*(length - len(current)))
            return
        
        clue = clues[0]
        remaining = clues[1:]
        min_remaining = sum(remaining) + len(remaining)
        max_start = length - min_remaining - clue + 1
        
        for i in range(start, max_start + 1):
            new_current = current + [0]*(i - len(current)) + [1]*clue
            if remaining:
                new_current.append(0)
            NonogramSolver._generate_permutations(remaining, length, i + clue + 1, new_current, result)

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