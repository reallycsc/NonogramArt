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

def create_complex_pattern(size, seed):
    patterns = [
        create_double_circle,
        create_cross_diamond,
        create_stripe_pattern,
        create_checkerboard,
        create_letter_pattern,
        create_abstract_shape,
        create_spiral,
        create_geometric_mix
    ]
    
    func = patterns[seed % len(patterns)]
    return func(size)

def create_double_circle(size):
    grid = [[0]*size for _ in range(size)]
    mid = size // 2
    r1 = size // 4
    r2 = size // 2 - 1
    
    for i in range(size):
        for j in range(size):
            dist = ((i - mid)**2 + (j - mid)**2)**0.5
            if r1 - 1 <= dist <= r1 + 1 or r2 - 1 <= dist <= r2 + 1:
                grid[i][j] = 1
    return grid

def create_cross_diamond(size):
    grid = [[0]*size for _ in range(size)]
    mid = size // 2
    
    for i in range(size):
        grid[i][mid] = 1
        grid[mid][i] = 1
    
    for i in range(size):
        for j in range(size):
            if abs(i - mid) + abs(j - mid) == size // 3:
                grid[i][j] = 1
    return grid

def create_stripe_pattern(size):
    grid = [[0]*size for _ in range(size)]
    stripe_width = size // 5
    
    for i in range(size):
        for j in range(size):
            if j % (stripe_width * 2) < stripe_width:
                grid[i][j] = 1
    return grid

def create_checkerboard(size):
    grid = [[0]*size for _ in range(size)]
    for i in range(size):
        for j in range(size):
            if (i // 2 + j // 2) % 2 == 0:
                grid[i][j] = 1
    return grid

def create_letter_pattern(size):
    grid = [[0]*size for _ in range(size)]
    
    mid = size // 2
    bar_width = size // 6
    
    for i in range(size):
        if mid - bar_width <= i <= mid + bar_width:
            for j in range(size):
                if j < size // 3 or (size // 3 * 2 < j < size):
                    grid[i][j] = 1
    
    for j in range(size):
        if size // 3 <= j < size // 3 * 2:
            grid[size // 4][j] = 1
            grid[size - size // 4 - 1][j] = 1
    
    return grid

def create_abstract_shape(size):
    grid = [[0]*size for _ in range(size)]
    
    for i in range(size):
        for j in range(size):
            if i < size // 3 and j < size // 3:
                grid[i][j] = 1
            if i >= size * 2 // 3 and j >= size * 2 // 3:
                grid[i][j] = 1
            if i >= size // 3 and i < size * 2 // 3 and j >= size // 3 and j < size * 2 // 3:
                grid[i][j] = 1
    return grid

def create_spiral(size):
    grid = [[0]*size for _ in range(size)]
    x, y = size // 2, size // 2
    dx, dy = 0, -1
    steps = 1
    
    while steps < size:
        for _ in range(steps):
            if 0 <= x < size and 0 <= y < size:
                grid[y][x] = 1
            x += dx
            y += dy
        
        dx, dy = dy, -dx
        if dy == 0:
            steps += 2
    
    return grid

def create_geometric_mix(size):
    grid = [[0]*size for _ in range(size)]
    mid = size // 2
    
    for i in range(size):
        for j in range(size):
            if i == j or i + j == size - 1:
                grid[i][j] = 1
            if abs(i - mid) <= 1 or abs(j - mid) <= 1:
                grid[i][j] = 1
    
    return grid

def generate_puzzle(puzzle_id, name, story_id, size, difficulty):
    seed = hash(puzzle_id)
    max_attempts = 200
    
    for attempt in range(max_attempts):
        pattern_seed = seed + attempt
        grid = create_complex_pattern(size, pattern_seed)
        
        filled_ratio = sum(sum(row) for row in grid) / (size * size)
        if filled_ratio < 0.15 or filled_ratio > 0.85:
            continue
        
        row_clues, col_clues = compute_clues(grid)
        
        result = NonogramSolver.solve(row_clues, col_clues)
        
        if result['solvable']:
            avg_clues_per_row = sum(len(c) for c in row_clues) / len(row_clues)
            if avg_clues_per_row > 1:
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
    
    return generate_fallback_puzzle(puzzle_id, name, story_id, size, difficulty)

def generate_fallback_puzzle(puzzle_id, name, story_id, size, difficulty):
    grid = [[0]*size for _ in range(size)]
    mid = size // 2
    
    for i in range(size):
        for j in range(size):
            if abs(i - mid) <= size // 4 or abs(j - mid) <= size // 4:
                grid[i][j] = 1
    
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
        'hint_cells': [],
        'source_rect': {'x': 0, 'y': 0, 'w': 128, 'h': 128}
    }

def main():
    puzzles_dir = "h:/Work/MyProject/ChineseMemory/data/puzzles"
    stories_dir = "h:/Work/MyProject/ChineseMemory/data/stories"
    
    print("=" * 60)
    print("高级谜题生成器")
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
        
        grid_x = None
        grid_y = None
        cell_width = 512
        cell_height = 512
        
        if data['stories']:
            grid_x = data['stories'][0].get('illustration_grid', {}).get('x', 2)
            grid_y = data['stories'][0].get('illustration_grid', {}).get('y', 2)
        
        for story in data['stories']:
            puzzle_idx = 0
            for row in range(grid_y or 2):
                for col in range(grid_x or 2):
                    if puzzle_idx >= len(story['puzzles']):
                        break
                    
                    puzzle_id = story['puzzles'][puzzle_idx]
                    puzzle_name = puzzle_id.replace(f"{story['id']}_", '')
                    
                    puzzle = generate_puzzle(puzzle_id, puzzle_name, story['id'], size, difficulty)
                    
                    puzzle['source_rect'] = {
                        'x': col * cell_width,
                        'y': row * cell_height,
                        'w': cell_width,
                        'h': cell_height
                    }
                    
                    puzzle_path = os.path.join(era_puzzle_dir, f"{puzzle_id}.json")
                    with open(puzzle_path, 'w', encoding='utf-8') as f:
                        json.dump(puzzle, f, indent='\t', ensure_ascii=False)
                    
                    puzzle_idx += 1
        
        print(f"生成谜题: {era_id} ({size}x{size}, {difficulty})")
    
    print("\n" + "=" * 60)
    print("生成完成！")
    print("=" * 60)

if __name__ == "__main__":
    main()