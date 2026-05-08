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

def analyze_image_region(img, target_size):
    img_gray = img.convert('L')
    img_resized = img_gray.resize((target_size, target_size), Image.Resampling.LANCZOS)
    
    pixels = list(img_resized.getdata())
    avg_brightness = sum(pixels) / len(pixels)
    contrast = max(pixels) - min(pixels)
    
    return avg_brightness, contrast

def extract_grid_with_adaptive_threshold(img, target_size):
    img_gray = img.convert('L')
    img_resized = img_gray.resize((target_size, target_size), Image.Resampling.LANCZOS)
    
    pixels = list(img_resized.getdata())
    avg_brightness = sum(pixels) / len(pixels)
    
    threshold = avg_brightness + 20
    
    grid = []
    for i in range(target_size):
        row = []
        for j in range(target_size):
            pixel = img_resized.getpixel((j, i))
            row.append(1 if pixel < threshold else 0)
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

def simplify_grid(grid):
    size = len(grid)
    new_grid = [row.copy() for row in grid]
    
    for _ in range(2):
        for i in range(size):
            for j in range(size):
                neighbors = 0
                for di in [-1, 0, 1]:
                    for dj in [-1, 0, 1]:
                        if di == 0 and dj == 0:
                            continue
                        ni, nj = i + di, j + dj
                        if 0 <= ni < size and 0 <= nj < size:
                            if new_grid[ni][nj] == 1:
                                neighbors += 1
                if new_grid[i][j] == 1 and neighbors <= 1:
                    new_grid[i][j] = 0
    
    return new_grid

def enhance_grid_for_solvability(grid):
    size = len(grid)
    new_grid = [row.copy() for row in grid]
    
    for i in range(size):
        filled = sum(new_grid[i])
        if filled == 0:
            new_grid[i][size//2] = 1
        elif filled == size:
            new_grid[i][size//2] = 0
    
    for j in range(size):
        filled = sum(new_grid[i][j] for i in range(size))
        if filled == 0:
            new_grid[size//2][j] = 1
        elif filled == size:
            new_grid[size//2][j] = 0
    
    return new_grid

def generate_puzzle_from_image(img, region_rect, puzzle_id, name, story_id, size, difficulty):
    avg_brightness, contrast = analyze_image_region(img, size)
    
    if contrast < 30:
        return None
    
    grid = extract_grid_with_adaptive_threshold(img, size)
    grid = simplify_grid(grid)
    grid = enhance_grid_for_solvability(grid)
    
    filled_ratio = sum(sum(row) for row in grid) / (size * size)
    if filled_ratio < 0.1 or filled_ratio > 0.9:
        return None
    
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
            'source_rect': region_rect
        }
    
    return None

def generate_pattern_based_on_image(img, puzzle_id, name, story_id, size, difficulty, region_rect):
    avg_brightness, contrast = analyze_image_region(img, size)
    
    patterns = [
        create_dense_pattern,
        create_sparse_pattern,
        create_center_pattern,
        create_edge_pattern,
        create_scattered_pattern
    ]
    
    if avg_brightness < 100:
        pattern_idx = 0
    elif avg_brightness > 180:
        pattern_idx = 1
    elif contrast > 80:
        pattern_idx = hash(puzzle_id) % len(patterns)
    else:
        pattern_idx = hash(puzzle_id) % len(patterns)
    
    grid = patterns[pattern_idx](size, hash(puzzle_id))
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
        'source_rect': region_rect
    }

def create_dense_pattern(size, seed):
    grid = [[0]*size for _ in range(size)]
    for i in range(size):
        for j in range(size):
            if (i + j + seed) % 3 != 0:
                grid[i][j] = 1
    return grid

def create_sparse_pattern(size, seed):
    grid = [[0]*size for _ in range(size)]
    for i in range(size):
        for j in range(size):
            if (i + j + seed) % 4 == 0:
                grid[i][j] = 1
    return grid

def create_center_pattern(size, seed):
    grid = [[0]*size for _ in range(size)]
    mid = size // 2
    radius = size // 3
    for i in range(size):
        for j in range(size):
            if abs(i - mid) + abs(j - mid) <= radius:
                grid[i][j] = 1
    return grid

def create_edge_pattern(size, seed):
    grid = [[0]*size for _ in range(size)]
    border = size // 5
    for i in range(size):
        for j in range(size):
            if i < border or i >= size - border or j < border or j >= size - border:
                grid[i][j] = 1
    return grid

def create_scattered_pattern(size, seed):
    grid = [[0]*size for _ in range(size)]
    for i in range(size):
        for j in range(size):
            if (i * j + seed) % 7 == 0:
                grid[i][j] = 1
    return grid

def main():
    puzzles_dir = "h:/Work/MyProject/ChineseMemory/data/puzzles"
    stories_dir = "h:/Work/MyProject/ChineseMemory/data/stories"
    
    print("=" * 60)
    print("智能图片数织谜题生成器")
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
        
        image_count = 0
        pattern_count = 0
        
        for story in data['stories']:
            illustration_path = story['illustration'].replace('res://', 'h:/Work/MyProject/ChineseMemory/')
            
            if not os.path.exists(illustration_path):
                print(f"警告：插图不存在: {illustration_path}")
                continue
            
            img = Image.open(illustration_path)
            img_width, img_height = img.size
            
            grid_x = story['illustration_grid']['x']
            grid_y = story['illustration_grid']['y']
            
            cell_width = img_width // grid_x
            cell_height = img_height // grid_y
            
            puzzle_idx = 0
            for row in range(grid_y):
                for col in range(grid_x):
                    if puzzle_idx >= len(story['puzzles']):
                        break
                    
                    puzzle_id = story['puzzles'][puzzle_idx]
                    puzzle_name = puzzle_id.replace(f"{story['id']}_", '')
                    
                    region_rect = {
                        'x': col * cell_width,
                        'y': row * cell_height,
                        'w': cell_width,
                        'h': cell_height
                    }
                    
                    region = img.crop((region_rect['x'], region_rect['y'],
                                     region_rect['x'] + region_rect['w'],
                                     region_rect['y'] + region_rect['h']))
                    
                    puzzle = generate_puzzle_from_image(region, region_rect, puzzle_id, puzzle_name, story['id'], size, difficulty)
                    
                    if puzzle is None:
                        puzzle = generate_pattern_based_on_image(region, puzzle_id, puzzle_name, story['id'], size, difficulty, region_rect)
                        pattern_count += 1
                    else:
                        image_count += 1
                    
                    puzzle_path = os.path.join(era_puzzle_dir, f"{puzzle_id}.json")
                    with open(puzzle_path, 'w', encoding='utf-8') as f:
                        json.dump(puzzle, f, indent='\t', ensure_ascii=False)
                    
                    puzzle_idx += 1
        
        print(f"{era_id}: 从图片提取 {image_count} 个, 基于图片生成 {pattern_count} 个 ({size}x{size})")
    
    print("\n" + "=" * 60)
    print("生成完成！")
    print("=" * 60)

if __name__ == "__main__":
    main()