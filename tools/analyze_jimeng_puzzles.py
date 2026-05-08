import os
import json

def print_pattern(solution):
    rows = len(solution)
    cols = len(solution[0]) if rows > 0 else 0
    
    lines = []
    for row in solution:
        line = ''.join(['█' if cell == 1 else ' ' for cell in row])
        lines.append(line)
    return '\n'.join(lines)

def is_puzzle_reasonable(row_clues, col_clues, solution):
    rows = len(solution)
    cols = len(solution[0]) if rows > 0 else 0
    
    for i, row in enumerate(solution):
        clue = row_clues[i]
        if not check_clue(row, clue):
            return False
    
    for j in range(cols):
        col = [solution[i][j] for i in range(rows)]
        clue = col_clues[j]
        if not check_clue(col, clue):
            return False
    
    return True

def check_clue(cells, clue):
    blocks = []
    current = 0
    
    for cell in cells:
        if cell == 1:
            current += 1
        else:
            if current > 0:
                blocks.append(current)
                current = 0
    if current > 0:
        blocks.append(current)
    
    return blocks == clue

def calculate_completeness(row_clues, col_clues, size):
    total_cells = size['rows'] * size['cols']
    
    row_sum = sum(sum(clue) for clue in row_clues)
    col_sum = sum(sum(clue) for clue in col_clues)
    
    if row_sum != col_sum:
        return None
    
    filled_cells = row_sum
    return filled_cells / total_cells

def analyze_puzzle(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    name = data['name']
    difficulty = data['difficulty']
    size = data['size']
    row_clues = data['row_clues']
    col_clues = data['col_clues']
    solution = data['solution']
    
    pattern = print_pattern(solution)
    is_valid = is_puzzle_reasonable(row_clues, col_clues, solution)
    completeness = calculate_completeness(row_clues, col_clues, size)
    
    return {
        'filename': os.path.basename(filepath),
        'id': data['id'],
        'name': name,
        'story_id': data['story_id'],
        'size': size,
        'difficulty': difficulty,
        'pattern': pattern,
        'is_valid': is_valid,
        'completeness': completeness,
        'has_unique_solution': assess_uniqueness(row_clues, col_clues, size)
    }

def assess_uniqueness(row_clues, col_clues, size):
    rows = size['rows']
    cols = size['cols']
    
    total_clues = sum(len(clue) for clue in row_clues) + sum(len(clue) for clue in col_clues)
    avg_clues_per_line = total_clues / (rows + cols)
    
    if avg_clues_per_line >= 2:
        return "高"
    elif avg_clues_per_line >= 1:
        return "中"
    else:
        return "低"

def main():
    puzzles_dir = 'h:/Work/MyProject/ChineseMemory/data/puzzles/mythology_jimeng'
    
    results = []
    for filename in sorted(os.listdir(puzzles_dir)):
        if filename.endswith('.json'):
            filepath = os.path.join(puzzles_dir, filename)
            result = analyze_puzzle(filepath)
            results.append(result)
    
    print("=" * 80)
    print(f"数织关卡分析报告")
    print("=" * 80)
    print()
    
    for result in results:
        print(f"【{result['name']}】")
        print(f"  文件: {result['filename']}")
        print(f"  ID: {result['id']}")
        print(f"  故事: {result['story_id']}")
        print(f"  尺寸: {result['size']['rows']}x{result['size']['cols']}")
        print(f"  难度: {result['difficulty']}")
        print(f"  图案完整性: {result['completeness']:.1%}")
        print(f"  线索匹配: {'OK 正确' if result['is_valid'] else 'ERR 错误'}")
        print(f"  唯一解可能性: {result['has_unique_solution']}")
        print(f"  完成图案:")
        print("  +" + "-" * result['size']['cols'] + "+")
        for line in result['pattern'].split('\n'):
            print(f"  |{line}|")
        print("  +" + "-" * result['size']['cols'] + "+")
        print()

if __name__ == '__main__':
    main()