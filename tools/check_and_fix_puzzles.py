import os
import json

def analyze_puzzle(puzzle_path):
    with open(puzzle_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    solution = data['solution']
    rows = data['size']['rows']
    cols = data['size']['cols']
    
    total_cells = rows * cols
    filled_cells = sum(sum(row) for row in solution)
    filled_ratio = filled_cells / total_cells if total_cells > 0 else 0
    
    empty_rows = sum(1 for row in solution if sum(row) == 0)
    empty_cols = 0
    for j in range(cols):
        col_sum = sum(solution[i][j] for i in range(rows)) if rows > 0 else 0
        if col_sum == 0:
            empty_cols += 1
    
    return {
        'name': data['name'],
        'id': data['id'],
        'size': f"{rows}x{cols}",
        'filled_ratio': filled_ratio,
        'empty_rows': empty_rows,
        'empty_cols': empty_cols,
        'total_filled': filled_cells
    }

def generate_valid_puzzle(name, puzzle_id, rows, cols, difficulty):
    patterns = {
        '太阳': [
            [0,1,1,1,0],
            [1,1,1,1,1],
            [1,1,1,1,1],
            [1,1,1,1,1],
            [0,1,1,1,0]
        ],
        '月亮': [
            [0,1,1,0],
            [1,0,0,1],
            [1,0,0,1],
            [0,1,1,0]
        ],
        '星星': [
            [0,0,1,0,0],
            [0,1,1,1,0],
            [1,1,1,1,1],
            [0,1,1,1,0],
            [0,0,1,0,0]
        ],
        '山': [
            [0,0,1,0,0],
            [0,1,1,1,0],
            [1,1,1,1,1],
            [0,1,1,1,0],
            [0,0,1,0,0]
        ],
        '塔': [
            [0,0,1,0,0],
            [0,0,1,0,0],
            [0,1,1,1,0],
            [1,1,1,1,1],
            [0,1,1,1,0]
        ],
        '鼎': [
            [0,1,1,1,0],
            [1,0,0,0,1],
            [1,1,1,1,1],
            [0,1,0,1,0],
            [0,1,0,1,0]
        ],
        '剑': [
            [0,0,1,0,0],
            [0,0,1,0,0],
            [0,0,1,0,0],
            [0,1,1,1,0],
            [1,0,1,0,1]
        ],
        '弓': [
            [1,0,0,0,1],
            [1,0,0,0,1],
            [0,1,0,1,0],
            [0,0,1,0,0],
            [0,0,1,0,0]
        ],
        '盾': [
            [0,1,1,1,0],
            [1,1,1,1,1],
            [1,1,1,1,1],
            [1,1,1,1,1],
            [0,1,1,1,0]
        ],
        '船': [
            [0,1,1,1,0],
            [1,1,1,1,1],
            [0,1,0,1,0],
            [0,1,0,1,0],
            [0,1,0,1,0]
        ],
        '旗': [
            [1,0,0,0,0],
            [1,1,1,1,0],
            [1,0,0,0,0],
            [1,0,0,0,0],
            [1,0,0,0,0]
        ],
        '书': [
            [1,1,1,1,1],
            [1,0,0,0,1],
            [1,0,0,0,1],
            [1,0,0,0,1],
            [1,1,1,1,1]
        ],
        '壶': [
            [0,1,1,1,0],
            [1,0,0,0,1],
            [1,1,1,1,1],
            [1,0,0,0,1],
            [0,1,1,1,0]
        ],
        '佛': [
            [0,0,1,0,0],
            [0,1,1,1,0],
            [1,0,1,0,1],
            [0,1,1,1,0],
            [0,0,1,0,0]
        ],
        '塔15': [
            [0,0,0,0,0,1,0,0,0,0,0,0,0,0,0],
            [0,0,0,0,1,1,1,0,0,0,0,0,0,0,0],
            [0,0,0,1,1,1,1,1,0,0,0,0,0,0,0],
            [0,0,1,1,1,1,1,1,1,0,0,0,0,0,0],
            [0,1,1,1,1,1,1,1,1,1,0,0,0,0,0],
            [0,0,0,0,1,1,1,0,0,0,0,0,0,0,0],
            [0,0,0,0,1,1,1,0,0,0,0,0,0,0,0],
            [0,0,0,0,1,1,1,0,0,0,0,0,0,0,0],
            [0,0,0,0,1,1,1,0,0,0,0,0,0,0,0],
            [0,0,0,0,1,1,1,0,0,0,0,0,0,0,0],
            [0,0,0,0,1,1,1,0,0,0,0,0,0,0,0],
            [0,0,0,0,1,1,1,0,0,0,0,0,0,0,0],
            [0,0,0,1,1,1,1,1,0,0,0,0,0,0,0],
            [0,0,1,1,1,1,1,1,1,0,0,0,0,0,0],
            [0,1,1,1,1,1,1,1,1,1,0,0,0,0,0]
        ],
        '剑15': [
            [0,0,0,0,0,0,1,0,0,0,0,0,0,0,0],
            [0,0,0,0,0,0,1,0,0,0,0,0,0,0,0],
            [0,0,0,0,0,0,1,0,0,0,0,0,0,0,0],
            [0,0,0,0,0,0,1,0,0,0,0,0,0,0,0],
            [0,0,0,0,0,0,1,0,0,0,0,0,0,0,0],
            [0,0,0,0,0,1,1,1,0,0,0,0,0,0,0],
            [0,0,0,0,1,1,1,1,1,0,0,0,0,0,0],
            [0,0,0,1,1,1,1,1,1,1,0,0,0,0,0],
            [0,0,1,1,1,1,1,1,1,1,1,0,0,0,0],
            [0,0,0,1,1,1,1,1,1,1,0,0,0,0,0,0],
            [0,0,0,0,1,1,1,1,1,0,0,0,0,0,0],
            [0,0,0,0,0,0,1,0,0,0,0,0,0,0,0],
            [0,0,0,0,0,0,1,0,0,0,0,0,0,0,0],
            [0,0,0,0,0,0,1,0,0,0,0,0,0,0,0],
            [0,0,0,0,0,0,1,0,0,0,0,0,0,0,0]
        ],
        '火箭20': [
            [0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0],
            [0,0,0,0,0,0,0,1,1,1,1,0,0,0,0,0,0,0,0,0],
            [0,0,0,0,0,0,0,1,1,1,1,0,0,0,0,0,0,0,0,0],
            [0,0,0,0,0,0,0,1,1,1,1,0,0,0,0,0,0,0,0,0],
            [0,0,0,0,0,0,0,1,1,1,1,0,0,0,0,0,0,0,0,0],
            [0,0,0,0,0,0,0,1,1,1,1,0,0,0,0,0,0,0,0,0],
            [0,0,0,0,0,0,1,1,1,1,1,1,0,0,0,0,0,0,0,0],
            [0,0,0,0,0,0,1,1,1,1,1,1,0,0,0,0,0,0,0,0],
            [0,0,0,0,0,0,1,1,1,1,1,1,0,0,0,0,0,0,0,0],
            [0,0,0,0,0,0,1,1,1,1,1,1,0,0,0,0,0,0,0,0],
            [0,0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0],
            [0,0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0],
            [0,0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0],
            [0,0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0],
            [0,0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0],
            [0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0],
            [0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0],
            [0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0],
            [0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0],
            [0,1,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,1,0]
        ],
        '高楼20': [
            [0,0,0,0,0,1,1,1,1,0,0,0,1,1,1,1,0,0,0,0],
            [0,0,0,0,0,1,1,1,1,0,0,0,1,1,1,1,0,0,0,0],
            [0,0,0,0,0,1,1,1,1,0,0,0,1,1,1,1,0,0,0,0],
            [0,0,0,0,0,1,1,1,1,0,0,0,1,1,1,1,0,0,0,0],
            [0,0,0,0,0,1,1,1,1,0,0,0,1,1,1,1,0,0,0,0],
            [0,0,0,0,0,1,1,1,1,0,0,0,1,1,1,1,0,0,0,0],
            [0,0,0,0,0,1,1,1,1,0,0,0,1,1,1,1,0,0,0,0],
            [0,0,0,0,0,1,1,1,1,0,0,0,1,1,1,1,0,0,0,0],
            [0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0],
            [0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0],
            [0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0],
            [0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0],
            [0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0],
            [0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0],
            [0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0],
            [0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0],
            [0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,0],
            [0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0],
            [0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0],
            [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]
        ]
    }
    
    pattern_name = name if name in patterns else '星星'
    base_pattern = patterns.get(pattern_name, patterns['星星'])
    
    if rows == 5 and cols == 5:
        solution = base_pattern[:5][:5] if len(base_pattern) >= 5 else patterns['星星']
    elif rows == 10 and cols == 10:
        solution = patterns.get(f"{name}10", patterns['星星'])
        if len(solution) < 10:
            solution = [[solution[i//2][j//2] for j in range(10)] for i in range(10)]
    elif rows == 15 and cols == 15:
        solution = patterns.get(f"{name}15", patterns['塔15'])
    elif rows == 20 and cols == 20:
        solution = patterns.get(f"{name}20", patterns['火箭20'])
    else:
        solution = [[1 if (i == j or i + j == rows - 1) else 0 for j in range(cols)] for i in range(rows)]
    
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
    for j in range(cols):
        clues = []
        current = 0
        for i in range(rows):
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
        'story_id': puzzle_id.split('_')[0],
        'size': {'rows': rows, 'cols': cols},
        'difficulty': difficulty,
        'row_clues': row_clues,
        'col_clues': col_clues,
        'solution': solution,
        'hint_cells': [],
        'source_rect': {'x': 0, 'y': 0, 'w': 128, 'h': 128}
    }

def main():
    puzzles_dir = "h:/Work/MyProject/ChineseMemory/data/puzzles"
    problematic_puzzles = []
    fixed_count = 0
    
    for era_dir in os.listdir(puzzles_dir):
        era_path = os.path.join(puzzles_dir, era_dir)
        if not os.path.isdir(era_path):
            continue
        
        for puzzle_file in os.listdir(era_path):
            if not puzzle_file.endswith('.json'):
                continue
            
            puzzle_path = os.path.join(era_path, puzzle_file)
            result = analyze_puzzle(puzzle_path)
            
            if result['filled_ratio'] == 0:
                print(f"[ERROR] 全空谜题: {era_dir}/{puzzle_file} - {result['name']}")
                problematic_puzzles.append((puzzle_path, result))
            elif result['filled_ratio'] < 0.1:
                print(f"[WARN] 填充率过低: {era_dir}/{puzzle_file} - {result['name']} ({result['filled_ratio']:.1%})")
                problematic_puzzles.append((puzzle_path, result))
            elif result['empty_rows'] >= int(result['size'].split('x')[0]):
                print(f"[WARN] 空行过多: {era_dir}/{puzzle_file} - {result['name']} ({result['empty_rows']}空行)")
                problematic_puzzles.append((puzzle_path, result))
    
    print(f"\n共发现 {len(problematic_puzzles)} 个问题谜题")
    
    if problematic_puzzles:
        print("\n开始修复...")
        for puzzle_path, result in problematic_puzzles:
            rows = int(result['size'].split('x')[0])
            cols = int(result['size'].split('x')[1])
            difficulty = 'easy' if rows == 5 else 'medium' if rows <= 15 else 'hard'
            
            fixed_data = generate_valid_puzzle(result['name'], result['id'], rows, cols, difficulty)
            
            with open(puzzle_path, 'w', encoding='utf-8') as f:
                json.dump(fixed_data, f, indent='\t', ensure_ascii=False)
            
            print(f"[FIXED] 已修复: {os.path.basename(puzzle_path)} - {result['name']}")
            fixed_count += 1
    
    print(f"\n修复完成！共修复 {fixed_count} 个谜题")

if __name__ == "__main__":
    main()