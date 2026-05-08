import os
import json

ERA_CONFIG = {
    "mythology": {
        "name": "神话时代",
        "grid_size": 5,
        "split_x": 2,
        "split_y": 2,
        "difficulty": "easy"
    },
    "xia_shang_zhou": {
        "name": "夏商周",
        "grid_size": 8,
        "split_x": 2,
        "split_y": 2,
        "difficulty": "easy"
    },
    "spring_autumn": {
        "name": "春秋战国",
        "grid_size": 10,
        "split_x": 2,
        "split_y": 2,
        "difficulty": "medium"
    },
    "qin_han": {
        "name": "秦汉",
        "grid_size": 12,
        "split_x": 3,
        "split_y": 2,
        "difficulty": "medium"
    },
    "three_kingdoms": {
        "name": "三国两晋南北朝",
        "grid_size": 15,
        "split_x": 3,
        "split_y": 2,
        "difficulty": "medium"
    },
    "sui_tang": {
        "name": "隋唐",
        "grid_size": 15,
        "split_x": 3,
        "split_y": 2,
        "difficulty": "medium"
    },
    "song_yuan": {
        "name": "宋元",
        "grid_size": 18,
        "split_x": 3,
        "split_y": 3,
        "difficulty": "hard"
    },
    "ming_qing": {
        "name": "明清",
        "grid_size": 20,
        "split_x": 3,
        "split_y": 3,
        "difficulty": "hard"
    },
    "modern": {
        "name": "近现代",
        "grid_size": 20,
        "split_x": 3,
        "split_y": 3,
        "difficulty": "hard"
    },
    "contemporary": {
        "name": "当代",
        "grid_size": 20,
        "split_x": 3,
        "split_y": 3,
        "difficulty": "hard"
    }
}

PATTERNS = {
    'star': [
        [0,0,1,0,0],
        [0,1,1,1,0],
        [1,1,1,1,1],
        [0,1,1,1,0],
        [0,0,1,0,0]
    ],
    'circle': [
        [1,1,1,1,1],
        [1,0,0,0,1],
        [1,0,0,0,1],
        [1,0,0,0,1],
        [1,1,1,1,1]
    ],
    'triangle': [
        [0,0,1,0,0],
        [0,1,1,1,0],
        [1,1,1,1,1],
        [0,1,1,1,0],
        [0,0,1,0,0]
    ],
    'diamond': [
        [0,0,1,0,0],
        [0,1,1,1,0],
        [1,1,1,1,1],
        [0,1,1,1,0],
        [0,0,1,0,0]
    ],
    'arrow': [
        [0,0,1,0,0],
        [0,1,1,0,0],
        [1,1,1,1,1],
        [0,0,1,0,0],
        [0,0,1,0,0]
    ],
    'cross': [
        [0,1,0,1,0],
        [0,1,0,1,0],
        [1,1,1,1,1],
        [0,1,0,1,0],
        [0,1,0,1,0]
    ],
    'square': [
        [1,1,1,1],
        [1,0,0,1],
        [1,0,0,1],
        [1,1,1,1]
    ],
    'heart': [
        [1,0,0,0,1],
        [1,1,0,1,1],
        [1,1,1,1,1],
        [0,1,1,1,0],
        [0,0,1,0,0]
    ],
    'moon': [
        [0,1,1,1,0],
        [1,0,0,0,1],
        [1,0,0,0,1],
        [0,1,1,1,0],
        [0,0,0,0,0]
    ],
    'sun': [
        [0,1,0,1,0],
        [1,1,1,1,1],
        [0,1,1,1,0],
        [1,1,1,1,1],
        [0,1,0,1,0]
    ],
    'axe': [
        [0,0,1,0,0],
        [0,1,1,0,0],
        [1,1,1,1,1],
        [0,0,1,0,0],
        [0,0,1,0,0]
    ],
    'bow': [
        [1,0,0,0,1],
        [0,1,0,1,0],
        [0,0,1,0,0],
        [0,0,1,0,0],
        [0,0,1,0,0]
    ],
    'sword': [
        [0,0,1,0,0],
        [0,0,1,0,0],
        [0,1,1,1,0],
        [0,0,1,0,0],
        [1,1,1,1,1]
    ],
    'ship': [
        [0,1,1,1,0],
        [1,1,1,1,1],
        [0,1,0,1,0],
        [0,1,0,1,0],
        [0,1,0,1,0]
    ],
    'building': [
        [0,1,1,1,0],
        [1,1,1,1,1],
        [1,0,0,0,1],
        [1,0,0,0,1],
        [1,1,1,1,1]
    ],
    'tower': [
        [0,0,1,0,0],
        [0,0,1,0,0],
        [0,1,1,1,0],
        [0,1,1,1,0],
        [1,1,1,1,1]
    ],
    'rocket': [
        [0,0,1,0,0],
        [0,1,1,1,0],
        [1,1,1,1,1],
        [0,1,1,1,0],
        [0,0,1,0,0]
    ],
    'book': [
        [1,1,1,1,1],
        [1,0,0,0,1],
        [1,0,0,0,1],
        [1,0,0,0,1],
        [1,1,1,1,1]
    ],
    'flag': [
        [1,0,0,0,0],
        [1,1,1,1,0],
        [1,0,0,0,0],
        [1,0,0,0,0],
        [1,0,0,0,0]
    ],
    'torch': [
        [0,0,1,0,0],
        [0,1,1,1,0],
        [1,1,1,1,1],
        [0,0,1,0,0],
        [0,0,1,0,0]
    ]
}

PATTERN_LIST = list(PATTERNS.values())

def scale_pattern(pattern, size):
    original_size = len(pattern)
    scale = size / original_size
    new_pattern = []
    for i in range(size):
        row = []
        for j in range(size):
            orig_i = min(int(i / scale), original_size - 1)
            orig_j = min(int(j / scale), original_size - 1)
            row.append(pattern[orig_i][orig_j])
        new_pattern.append(row)
    return new_pattern

def generate_puzzle(name, puzzle_id, story_id, size, difficulty):
    pattern_idx = hash(puzzle_id) % len(PATTERN_LIST)
    base_pattern = PATTERN_LIST[pattern_idx]
    solution = scale_pattern(base_pattern, size)
    
    row_clues = []
    for row in solution:
        clues = []
        current = 0
        for cell in row:
            if cell == 1:
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
            if solution[i][j] == 1:
                current += 1
            else:
                if current > 0:
                    clues.append(current)
                    current = 0
        if current > 0:
            clues.append(current)
        col_clues.append(clues if clues else [0])
    
    return {
        'id': puzzle_id,
        'name': name,
        'story_id': story_id,
        'size': {'rows': size, 'cols': size},
        'difficulty': difficulty,
        'row_clues': row_clues,
        'col_clues': col_clues,
        'solution': solution,
        'hint_cells': [],
        'source_rect': {'x': 0, 'y': 0, 'w': 128, 'h': 128}
    }

def update_stories():
    stories_dir = "h:/Work/MyProject/ChineseMemory/data/stories"
    
    for era_id, config in ERA_CONFIG.items():
        story_file = os.path.join(stories_dir, f"{era_id}.json")
        if not os.path.exists(story_file):
            print(f"警告：故事文件不存在: {story_file}")
            continue
        
        with open(story_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        split_x = config['split_x']
        split_y = config['split_y']
        
        for story in data['stories']:
            story['illustration_grid'] = {'x': split_x, 'y': split_y}
            
            puzzle_count = split_x * split_y
            current_puzzles = story.get('puzzles', [])
            
            if len(current_puzzles) != puzzle_count:
                new_puzzles = []
                puzzle_names = ['figure', 'object1', 'object2', 'object3', 'object4', 'object5', 'object6', 'object7', 'object8']
                for i in range(puzzle_count):
                    puzzle_name = puzzle_names[i] if i < len(puzzle_names) else f'object{i+1}'
                    new_puzzles.append(f"{story['id']}_{puzzle_name}")
                story['puzzles'] = new_puzzles
        
        with open(story_file, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent='\t', ensure_ascii=False)
        
        print(f"更新故事配置: {era_id} (网格: {split_x}×{split_y})")

def generate_puzzles():
    puzzles_dir = "h:/Work/MyProject/ChineseMemory/data/puzzles"
    
    for era_id, config in ERA_CONFIG.items():
        era_puzzle_dir = os.path.join(puzzles_dir, era_id)
        os.makedirs(era_puzzle_dir, exist_ok=True)
        
        story_file = os.path.join("h:/Work/MyProject/ChineseMemory/data/stories", f"{era_id}.json")
        if not os.path.exists(story_file):
            continue
        
        with open(story_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        size = config['grid_size']
        difficulty = config['difficulty']
        
        for story in data['stories']:
            for puzzle_id in story['puzzles']:
                puzzle_name = puzzle_id.replace(f"{story['id']}_", '')
                puzzle = generate_puzzle(puzzle_name, puzzle_id, story['id'], size, difficulty)
                
                puzzle_path = os.path.join(era_puzzle_dir, f"{puzzle_id}.json")
                with open(puzzle_path, 'w', encoding='utf-8') as f:
                    json.dump(puzzle, f, indent='\t', ensure_ascii=False)
        
        print(f"生成谜题: {era_id} (尺寸: {size}×{size}, 难度: {difficulty})")

def update_source_rect():
    import sys
    sys.path.append("h:/Work/MyProject/ChineseMemory/tools")
    from PIL import Image
    
    stories_dir = "h:/Work/MyProject/ChineseMemory/data/stories"
    puzzles_dir = "h:/Work/MyProject/ChineseMemory/data/puzzles"
    
    for era_id, config in ERA_CONFIG.items():
        story_file = os.path.join(stories_dir, f"{era_id}.json")
        if not os.path.exists(story_file):
            continue
        
        with open(story_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        split_x = config['split_x']
        split_y = config['split_y']
        
        for story in data['stories']:
            illustration_path = story['illustration'].replace('res://', 'h:/Work/MyProject/ChineseMemory/')
            
            if os.path.exists(illustration_path):
                try:
                    img = Image.open(illustration_path)
                    img_width, img_height = img.size
                    cell_width = img_width // split_x
                    cell_height = img_height // split_y
                except:
                    cell_width = 512
                    cell_height = 512
            else:
                cell_width = 512
                cell_height = 512
            
            puzzle_idx = 0
            for row in range(split_y):
                for col in range(split_x):
                    if puzzle_idx >= len(story['puzzles']):
                        break
                    
                    puzzle_id = story['puzzles'][puzzle_idx]
                    puzzle_path = os.path.join(puzzles_dir, era_id, f"{puzzle_id}.json")
                    
                    if os.path.exists(puzzle_path):
                        with open(puzzle_path, 'r', encoding='utf-8') as f:
                            puzzle_data = json.load(f)
                        
                        puzzle_data['source_rect'] = {
                            'x': col * cell_width,
                            'y': row * cell_height,
                            'w': cell_width,
                            'h': cell_height
                        }
                        
                        with open(puzzle_path, 'w', encoding='utf-8') as f:
                            json.dump(puzzle_data, f, indent='\t', ensure_ascii=False)
                    
                    puzzle_idx += 1

def main():
    print("=" * 60)
    print("重新规划数织关卡难度和数量")
    print("=" * 60)
    
    print("\n1. 更新故事配置（插图网格划分）...")
    update_stories()
    
    print("\n2. 生成新的数织谜题...")
    generate_puzzles()
    
    print("\n3. 更新谜题source_rect...")
    update_source_rect()
    
    print("\n" + "=" * 60)
    print("重新规划完成！")
    print("=" * 60)
    
    print("\n[SUMMARY] 新配置摘要:")
    total_puzzles = 0
    for era_id, config in ERA_CONFIG.items():
        puzzles_per_story = config['split_x'] * config['split_y']
        total = puzzles_per_story * 3
        total_puzzles += total
        print(f"  {config['name']}: {config['grid_size']}×{config['grid_size']}, {config['difficulty']}, {config['split_x']}×{config['split_y']}={puzzles_per_story}谜题/故事, 共{total}个谜题")
    
    print(f"\n  总计: {total_puzzles}个谜题")

if __name__ == "__main__":
    main()