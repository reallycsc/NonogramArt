import os
import json
from PIL import Image

ERA_CONFIG = {
    "mythology": {"size": 5, "difficulty": "easy"},
    "xia_shang_zhou": {"size": 10, "difficulty": "easy"},
    "spring_autumn": {"size": 10, "difficulty": "medium"},
    "qin_han": {"size": 15, "difficulty": "medium"},
    "three_kingdoms": {"size": 15, "difficulty": "medium"},
    "sui_tang": {"size": 15, "difficulty": "medium"},
    "song_yuan": {"size": 20, "difficulty": "hard"},
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

def create_pattern_from_image(img, size):
    img_gray = img.convert('L')
    img_resized = img_gray.resize((size, size), Image.Resampling.LANCZOS)
    
    pixels = list(img_resized.getdata())
    avg_brightness = sum(pixels) / len(pixels)
    threshold = avg_brightness + 15
    
    grid = []
    for i in range(size):
        row = []
        for j in range(size):
            pixel = img_resized.getpixel((j, i))
            row.append(1 if pixel < threshold else 0)
        grid.append(row)
    
    return grid

def ensure_solvable(grid):
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

def generate_puzzle(img, region_rect, puzzle_id, name, story_id, size, difficulty):
    grid = create_pattern_from_image(img, size)
    grid = ensure_solvable(grid)
    
    filled_ratio = sum(sum(row) for row in grid) / (size * size)
    if filled_ratio < 0.1:
        for i in range(size):
            for j in range(size):
                if (i + j) % 3 == 0:
                    grid[i][j] = 1
    elif filled_ratio > 0.9:
        for i in range(size):
            for j in range(size):
                if (i + j) % 3 == 0:
                    grid[i][j] = 0
    
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

def main():
    puzzles_dir = "h:/Work/MyProject/ChineseMemory/data/puzzles"
    stories_dir = "h:/Work/MyProject/ChineseMemory/data/stories"
    
    print("=" * 60)
    print("修复网格大小为5的倍数")
    print("=" * 60)
    
    for era_id, config in ERA_CONFIG.items():
        size = config['size']
        difficulty = config['difficulty']
        
        print(f"{era_id}: {size}x{size} ({difficulty})")
        
        era_puzzle_dir = os.path.join(puzzles_dir, era_id)
        os.makedirs(era_puzzle_dir, exist_ok=True)
        
        story_file = os.path.join(stories_dir, f"{era_id}.json")
        if not os.path.exists(story_file):
            continue
        
        with open(story_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
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
                    
                    puzzle_path = os.path.join(era_puzzle_dir, f"{puzzle_id}.json")
                    with open(puzzle_path, 'w', encoding='utf-8') as f:
                        json.dump(puzzle, f, indent='\t', ensure_ascii=False)
                    
                    puzzle_idx += 1
    
    print("\n" + "=" * 60)
    print("修复完成！")
    print("=" * 60)

if __name__ == "__main__":
    main()