import os
import json

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

def create_simple_pattern(size, pattern_type):
    grid = [[0 for _ in range(size)] for _ in range(size)]
    
    if pattern_type == 'horizontal_line':
        mid = size // 2
        for j in range(size):
            grid[mid][j] = 1
            
    elif pattern_type == 'vertical_line':
        mid = size // 2
        for i in range(size):
            grid[i][mid] = 1
            
    elif pattern_type == 'cross':
        mid = size // 2
        for i in range(size):
            grid[i][mid] = 1
            grid[mid][i] = 1
            
    elif pattern_type == 'square':
        border = size // 4
        for i in range(border, size - border):
            for j in range(border, size - border):
                grid[i][j] = 1
                
    elif pattern_type == 'frame':
        border = size // 4
        for i in range(size):
            for j in range(size):
                if i == border or i == size - border - 1 or j == border or j == size - border - 1:
                    grid[i][j] = 1
                    
    elif pattern_type == 'diagonal':
        for i in range(size):
            grid[i][i] = 1
            if i < size - 1:
                grid[i][i + 1] = 1
                
    elif pattern_type == 'triangle':
        for i in range(size):
            start = max(0, size // 2 - i)
            end = min(size, size // 2 + i + 1)
            for j in range(start, end):
                grid[i][j] = 1
                
    elif pattern_type == 'diamond':
        mid = size // 2
        for i in range(size):
            for j in range(size):
                if abs(i - mid) + abs(j - mid) <= mid:
                    grid[i][j] = 1
                    
    elif pattern_type == 'checker':
        for i in range(size):
            for j in range(size):
                if (i + j) % 2 == 0:
                    grid[i][j] = 1
                    
    elif pattern_type == 'center_dot':
        mid = size // 2
        grid[mid][mid] = 1
        if mid > 0:
            grid[mid-1][mid] = 1
            grid[mid+1][mid] = 1
            grid[mid][mid-1] = 1
            grid[mid][mid+1] = 1
            
    elif pattern_type == 'corner':
        quarter = size // 4
        for i in range(quarter * 2):
            for j in range(quarter * 2):
                grid[i][j] = 1
                
    elif pattern_type == 'stripe':
        for i in range(size):
            for j in range(size):
                if j % 3 == 0:
                    grid[i][j] = 1
                    
    return grid

PATTERN_TYPES = [
    'horizontal_line', 'vertical_line', 'cross', 'square', 'frame',
    'diagonal', 'triangle', 'diamond', 'checker', 'center_dot', 'corner', 'stripe'
]

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
    pattern_idx = hash(puzzle_id) % len(PATTERN_TYPES)
    pattern_type = PATTERN_TYPES[pattern_idx]
    solution = create_simple_pattern(size, pattern_type)
    row_clues, col_clues = compute_clues(solution)
    
    hint_cells = []
    if size >= 10:
        hint_cells.append([size//2, size//2])
    
    return {
        'id': puzzle_id,
        'name': name,
        'story_id': story_id,
        'size': {'rows': size, 'cols': size},
        'difficulty': difficulty,
        'row_clues': row_clues,
        'col_clues': col_clues,
        'solution': solution,
        'hint_cells': hint_cells,
        'source_rect': {'x': 0, 'y': 0, 'w': 128, 'h': 128}
    }

def main():
    puzzles_dir = "h:/Work/MyProject/ChineseMemory/data/puzzles"
    stories_dir = "h:/Work/MyProject/ChineseMemory/data/stories"
    
    print("=" * 60)
    print("重新生成可推理的数织谜题")
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
    print("重新生成完成！")
    print("=" * 60)

if __name__ == "__main__":
    main()