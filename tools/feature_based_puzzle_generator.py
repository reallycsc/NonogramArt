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

def analyze_image_features(img):
    img_gray = img.convert('L')
    
    width, height = img_gray.size
    pixel_count = width * height
    
    pixels = list(img_gray.getdata())
    avg_brightness = sum(pixels) / pixel_count
    contrast = max(pixels) - min(pixels)
    
    dark_pixels = sum(1 for p in pixels if p < 128)
    dark_ratio = dark_pixels / pixel_count
    
    edge_count = 0
    for i in range(height - 1):
        for j in range(width - 1):
            current = img_gray.getpixel((j, i))
            right = img_gray.getpixel((j + 1, i))
            down = img_gray.getpixel((j, i + 1))
            if abs(current - right) > 40 or abs(current - down) > 40:
                edge_count += 1
    
    edge_density = edge_count / ((width - 1) * (height - 1))
    
    return {
        'avg_brightness': avg_brightness,
        'contrast': contrast,
        'dark_ratio': dark_ratio,
        'edge_density': edge_density
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

def generate_grid_from_features(features, size, seed):
    avg_brightness = features['avg_brightness']
    contrast = features['contrast']
    dark_ratio = features['dark_ratio']
    edge_density = features['edge_density']
    
    target_density = dark_ratio
    if target_density < 0.15:
        target_density = 0.3
    elif target_density > 0.85:
        target_density = 0.7
    
    grid = [[0]*size for _ in range(size)]
    
    if edge_density > 0.3:
        grid = create_texture_pattern(size, seed, target_density)
    elif contrast > 80:
        grid = create_high_contrast_pattern(size, seed, target_density)
    elif avg_brightness < 100:
        grid = create_dark_pattern(size, seed, target_density)
    elif avg_brightness > 180:
        grid = create_light_pattern(size, seed, target_density)
    else:
        grid = create_mixed_pattern(size, seed, target_density)
    
    return grid

def create_texture_pattern(size, seed, target_density):
    grid = [[0]*size for _ in range(size)]
    threshold = int(255 * (1 - target_density))
    
    for i in range(size):
        for j in range(size):
            val = (i * 7 + j * 11 + seed) % 256
            if val > threshold:
                grid[i][j] = 1
    
    return grid

def create_high_contrast_pattern(size, seed, target_density):
    grid = [[0]*size for _ in range(size)]
    mid = size // 2
    
    for i in range(size):
        for j in range(size):
            dist = abs(i - mid) + abs(j - mid)
            if dist < size * target_density:
                grid[i][j] = 1
    
    return grid

def create_dark_pattern(size, seed, target_density):
    grid = [[0]*size for _ in range(size)]
    threshold = int(size * size * target_density)
    count = 0
    
    for i in range(size):
        for j in range(size):
            if count < threshold:
                grid[i][j] = 1
                count += 1
    
    return grid

def create_light_pattern(size, seed, target_density):
    grid = [[0]*size for _ in range(size)]
    threshold = int(size * size * (1 - target_density))
    count = 0
    
    for i in range(size):
        for j in range(size):
            if count >= threshold:
                grid[i][j] = 1
            count += 1
    
    return grid

def create_mixed_pattern(size, seed, target_density):
    grid = [[0]*size for _ in range(size)]
    
    for i in range(size):
        for j in range(size):
            if (i + j) % 3 == 0:
                if seed % 2 == 0:
                    grid[i][j] = 1
            elif (i + j) % 3 == 1:
                if seed % 3 == 0:
                    grid[i][j] = 1
    
    current_density = sum(sum(row) for row in grid) / (size * size)
    
    if current_density < target_density:
        fill_needed = int((target_density - current_density) * size * size)
        count = 0
        for i in range(size):
            for j in range(size):
                if grid[i][j] == 0 and count < fill_needed:
                    grid[i][j] = 1
                    count += 1
    
    elif current_density > target_density:
        remove_needed = int((current_density - target_density) * size * size)
        count = 0
        for i in range(size):
            for j in range(size):
                if grid[i][j] == 1 and count < remove_needed:
                    grid[i][j] = 0
                    count += 1
    
    return grid

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
    
    for i in range(size):
        for j in range(size):
            if new_grid[i][j] == 1:
                has_neighbor = False
                for di in [-1, 0, 1]:
                    for dj in [-1, 0, 1]:
                        if di == 0 and dj == 0:
                            continue
                        ni, nj = i + di, j + dj
                        if 0 <= ni < size and 0 <= nj < size:
                            if new_grid[ni][nj] == 1:
                                has_neighbor = True
                                break
                    if has_neighbor:
                        break
                if not has_neighbor:
                    new_grid[i][j] = 0
    
    return new_grid

def generate_puzzle(img, region_rect, puzzle_id, name, story_id, size, difficulty):
    features = analyze_image_features(img)
    grid = generate_grid_from_features(features, size, hash(puzzle_id))
    grid = enhance_grid_for_solvability(grid)
    
    row_clues, col_clues = compute_clues(grid)
    
    result = NonogramSolver.solve(row_clues, col_clues)
    
    if result['solvable']:
        filled_ratio = sum(sum(row) for row in grid) / (size * size)
        if 0.1 <= filled_ratio <= 0.9:
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
    
    return generate_fallback_puzzle(puzzle_id, name, story_id, size, difficulty, region_rect)

def generate_fallback_puzzle(puzzle_id, name, story_id, size, difficulty, region_rect):
    patterns = [
        create_stripe_pattern,
        create_checker_pattern,
        create_circle_pattern,
        create_diamond_pattern,
        create_cross_pattern
    ]
    
    pattern_idx = hash(puzzle_id) % len(patterns)
    grid = patterns[pattern_idx](size)
    
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

def create_stripe_pattern(size):
    grid = [[0]*size for _ in range(size)]
    for i in range(size):
        for j in range(size):
            if j % 4 < 2:
                grid[i][j] = 1
    return grid

def create_checker_pattern(size):
    grid = [[0]*size for _ in range(size)]
    for i in range(size):
        for j in range(size):
            if (i // 2 + j // 2) % 2 == 0:
                grid[i][j] = 1
    return grid

def create_circle_pattern(size):
    grid = [[0]*size for _ in range(size)]
    mid = size // 2
    radius = size // 3
    for i in range(size):
        for j in range(size):
            dist = ((i - mid)**2 + (j - mid)**2)**0.5
            if dist <= radius:
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

def create_cross_pattern(size):
    grid = [[0]*size for _ in range(size)]
    mid = size // 2
    for i in range(size):
        grid[i][mid] = 1
    for j in range(size):
        grid[mid][j] = 1
    return grid

def main():
    puzzles_dir = "h:/Work/MyProject/ChineseMemory/data/puzzles"
    stories_dir = "h:/Work/MyProject/ChineseMemory/data/stories"
    
    print("=" * 60)
    print("基于图片特征的数织谜题生成器")
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
        
        feature_count = 0
        fallback_count = 0
        
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
                    
                    puzzle = generate_puzzle(region, region_rect, puzzle_id, puzzle_name, story['id'], size, difficulty)
                    
                    if puzzle:
                        feature_count += 1
                    else:
                        puzzle = generate_fallback_puzzle(puzzle_id, puzzle_name, story['id'], size, difficulty, region_rect)
                        fallback_count += 1
                    
                    puzzle_path = os.path.join(era_puzzle_dir, f"{puzzle_id}.json")
                    with open(puzzle_path, 'w', encoding='utf-8') as f:
                        json.dump(puzzle, f, indent='\t', ensure_ascii=False)
                    
                    puzzle_idx += 1
        
        print(f"{era_id}: 基于特征生成 {feature_count} 个, fallback {fallback_count} 个 ({size}x{size})")
    
    print("\n" + "=" * 60)
    print("生成完成！")
    print("=" * 60)

if __name__ == "__main__":
    main()