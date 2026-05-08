import os
import json
from PIL import Image

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

def image_to_grid(image_path, target_size):
    img = Image.open(image_path).convert('L')
    img = img.resize((target_size, target_size), Image.Resampling.LANCZOS)
    
    grid = []
    for i in range(target_size):
        row = []
        for j in range(target_size):
            pixel = img.getpixel((j, i))
            row.append(1 if pixel < 128 else 0)
        grid.append(row)
    
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

def simplify_grid(grid, min_segment=2):
    size = len(grid)
    new_grid = [row.copy() for row in grid]
    
    for i in range(size):
        j = 0
        while j < size:
            if new_grid[i][j] == 1:
                start = j
                while j < size and new_grid[i][j] == 1:
                    j += 1
                length = j - start
                if length < min_segment:
                    for k in range(start, j):
                        new_grid[i][k] = 0
            else:
                j += 1
    
    for j in range(size):
        i = 0
        while i < size:
            if new_grid[i][j] == 1:
                start = i
                while i < size and new_grid[i][j] == 1:
                    i += 1
                length = i - start
                if length < min_segment:
                    for k in range(start, i):
                        new_grid[k][j] = 0
            else:
                i += 1
    
    return new_grid

def enhance_grid(grid):
    size = len(grid)
    new_grid = [row.copy() for row in grid]
    
    for i in range(size):
        for j in range(size):
            if new_grid[i][j] == 1:
                neighbors = 0
                for di in [-1, 0, 1]:
                    for dj in [-1, 0, 1]:
                        if di == 0 and dj == 0:
                            continue
                        ni, nj = i + di, j + dj
                        if 0 <= ni < size and 0 <= nj < size:
                            if new_grid[ni][nj] == 1:
                                neighbors += 1
                if neighbors == 0:
                    new_grid[i][j] = 0
    
    return new_grid

def generate_puzzle_from_image(image_path, puzzle_id, name, story_id, size, difficulty):
    try:
        raw_grid = image_to_grid(image_path, size)
        grid = simplify_grid(raw_grid, min_segment=2)
        grid = enhance_grid(grid)
        
        row_clues, col_clues = compute_clues(grid)
        
        result = NonogramSolver.solve(row_clues, col_clues)
        
        if result['solvable']:
            filled_ratio = sum(sum(row) for row in grid) / (size * size)
            if filled_ratio < 0.1 or filled_ratio > 0.9:
                return None
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
        else:
            return None
    except Exception as e:
        print(f"Error processing {image_path}: {e}")
        return None

def generate_fallback_puzzle(puzzle_id, name, story_id, size, difficulty):
    patterns = [
        create_circle_pattern,
        create_diamond_pattern,
        create_triangle_pattern,
        create_spiral_pattern,
        create_checker_pattern,
        create_zigzag_pattern,
        create_heart_pattern,
        create_star_pattern
    ]
    
    seed = hash(puzzle_id)
    pattern_func = patterns[seed % len(patterns)]
    
    grid = pattern_func(size)
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
    
    grid = create_simple_line_pattern(size)
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

def create_circle_pattern(size):
    grid = [[0]*size for _ in range(size)]
    mid = size // 2
    radius = size // 3
    for i in range(size):
        for j in range(size):
            dist = ((i - mid)**2 + (j - mid)**2)**0.5
            if radius - 1 <= dist <= radius + 1:
                grid[i][j] = 1
    return grid

def create_diamond_pattern(size):
    grid = [[0]*size for _ in range(size)]
    mid = size // 2
    for i in range(size):
        for j in range(size):
            if abs(i - mid) + abs(j - mid) <= mid:
                grid[i][j] = 1
    return grid

def create_triangle_pattern(size):
    grid = [[0]*size for _ in range(size)]
    for i in range(size):
        start = max(0, size // 2 - i)
        end = min(size, size // 2 + i + 1)
        for j in range(start, end):
            grid[i][j] = 1
    return grid

def create_spiral_pattern(size):
    grid = [[0]*size for _ in range(size)]
    x, y = size // 2, size // 2
    dx, dy = 0, -1
    steps = 1
    
    while x >= 0 and x < size and y >= 0 and y < size:
        for _ in range(steps):
            if 0 <= x < size and 0 <= y < size:
                grid[y][x] = 1
            x += dx
            y += dy
        dx, dy = dy, -dx
        if dy == 0:
            steps += 1
    
    return grid

def create_checker_pattern(size):
    grid = [[0]*size for _ in range(size)]
    for i in range(size):
        for j in range(size):
            if (i + j) % 3 == 0:
                grid[i][j] = 1
    return grid

def create_zigzag_pattern(size):
    grid = [[0]*size for _ in range(size)]
    for i in range(size):
        for j in range(size):
            if j == i or j == size - 1 - i:
                grid[i][j] = 1
    return grid

def create_heart_pattern(size):
    grid = [[0]*size for _ in range(size)]
    for i in range(size):
        for j in range(size):
            x = j - size//2
            y = i - size//2
            eq = x**2 + (y - (abs(x)**0.5)**(2/3))**2
            if eq <= (size//3)**2:
                grid[i][j] = 1
    return grid

def create_star_pattern(size):
    grid = [[0]*size for _ in range(size)]
    mid = size // 2
    for i in range(size):
        for j in range(size):
            if abs(i - mid) + abs(j - mid) == mid // 2 or abs(i - mid) == abs(j - mid) == mid // 3:
                grid[i][j] = 1
    return grid

def create_simple_line_pattern(size):
    grid = [[0]*size for _ in range(size)]
    mid = size // 2
    for j in range(size):
        grid[mid][j] = 1
    for i in range(size):
        grid[i][mid] = 1
    return grid

def main():
    puzzles_dir = "h:/Work/MyProject/ChineseMemory/data/puzzles"
    stories_dir = "h:/Work/MyProject/ChineseMemory/data/stories"
    illustrations_dir = "h:/Work/MyProject/ChineseMemory/assets/images/illustrations"
    
    print("=" * 60)
    print("从插图提取数织谜题")
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
        
        era_illustration_dir = os.path.join(illustrations_dir, era_id)
        
        fallback_count = 0
        image_count = 0
        
        for story in data['stories']:
            illustration_path = story['illustration'].replace('res://', 'h:/Work/MyProject/ChineseMemory/')
            grid_x = story['illustration_grid']['x']
            grid_y = story['illustration_grid']['y']
            
            if os.path.exists(illustration_path):
                img = Image.open(illustration_path)
                img_width, img_height = img.size
                cell_width = img_width // grid_x
                cell_height = img_height // grid_y
            else:
                cell_width = 512
                cell_height = 512
            
            puzzle_idx = 0
            for row in range(grid_y):
                for col in range(grid_x):
                    if puzzle_idx >= len(story['puzzles']):
                        break
                    
                    puzzle_id = story['puzzles'][puzzle_idx]
                    puzzle_name = puzzle_id.replace(f"{story['id']}_", '')
                    
                    region_path = None
                    if os.path.exists(illustration_path):
                        region_path = f"{era_illustration_dir}/{story['id']}_{puzzle_name}.png"
                        
                        if os.path.exists(illustration_path):
                            img = Image.open(illustration_path)
                            region = img.crop((col * cell_width, row * cell_height,
                                             (col + 1) * cell_width, (row + 1) * cell_height))
                            region.save(region_path)
                    
                    puzzle = None
                    if region_path and os.path.exists(region_path):
                        puzzle = generate_puzzle_from_image(region_path, puzzle_id, puzzle_name, story['id'], size, difficulty)
                    
                    if puzzle is None:
                        puzzle = generate_fallback_puzzle(puzzle_id, puzzle_name, story['id'], size, difficulty)
                        fallback_count += 1
                    else:
                        image_count += 1
                    
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
        
        print(f"{era_id}: 从图片提取 {image_count} 个, 使用 fallback {fallback_count} 个 ({size}x{size}, {difficulty})")
    
    print("\n" + "=" * 60)
    print("提取完成！")
    print("=" * 60)

if __name__ == "__main__":
    main()