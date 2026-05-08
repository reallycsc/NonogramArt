import os
import json

class NonogramSolver:
    @staticmethod
    def solve(row_clues, col_clues):
        rows = len(row_clues)
        cols = len(col_clues)
        
        grid = [[0 for _ in range(cols)] for _ in range(rows)]
        known = [[False for _ in range(cols)] for _ in range(rows)]
        
        changed = True
        iteration = 0
        max_iterations = rows * cols * 2
        
        while changed and iteration < max_iterations:
            changed = False
            iteration += 1
            
            for i in range(rows):
                clues = row_clues[i]
                possible = NonogramSolver.get_line_permutations(clues, cols)
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
                possible = NonogramSolver.get_line_permutations(clues, rows)
                for i in range(rows):
                    if known[i][j]:
                        continue
                    column_possible = [p[i] for p in possible]
                    all_filled = all(v == 1 for v in column_possible)
                    all_empty = all(v == 0 for v in column_possible)
                    if all_filled:
                        grid[i][j] = 1
                        known[i][j] = True
                        changed = True
                    elif all_empty:
                        grid[i][j] = 0
                        known[i][j] = True
                        changed = True
        
        all_known = all(all(row) for row in known)
        return {
            'solvable': all_known,
            'solution': grid,
            'known_cells': sum(sum(row) for row in known),
            'total_cells': rows * cols
        }
    
    @staticmethod
    def get_line_permutations(clues, length):
        if not clues or clues == [0]:
            return [[0] * length]
        
        total_filled = sum(clues)
        total_gaps = len(clues) - 1
        min_length = total_filled + total_gaps
        
        if min_length > length:
            return []
        
        result = []
        NonogramSolver._generate_permutations(clues, length, 0, [], result)
        return result
    
    @staticmethod
    def _generate_permutations(clues, length, start, current, result):
        if not clues:
            if start <= length:
                result.append(current + [0] * (length - len(current)))
            return
        
        clue = clues[0]
        remaining_clues = clues[1:]
        remaining_length = length - start
        
        min_remaining = sum(remaining_clues) + len(remaining_clues)
        max_start = length - min_remaining - clue + 1
        
        for i in range(start, max_start + 1):
            new_current = current + [0] * (i - len(current)) + [1] * clue
            if remaining_clues:
                new_current.append(0)
            NonogramSolver._generate_permutations(remaining_clues, length, i + clue + 1, new_current, result)

ERA_CONFIG = {
    "mythology": {"expected_difficulty": "easy", "expected_size": 5},
    "xia_shang_zhou": {"expected_difficulty": "easy", "expected_size": 8},
    "spring_autumn": {"expected_difficulty": "medium", "expected_size": 10},
    "qin_han": {"expected_difficulty": "medium", "expected_size": 12},
    "three_kingdoms": {"expected_difficulty": "medium", "expected_size": 15},
    "sui_tang": {"expected_difficulty": "medium", "expected_size": 15},
    "song_yuan": {"expected_difficulty": "hard", "expected_size": 18},
    "ming_qing": {"expected_difficulty": "hard", "expected_size": 20},
    "modern": {"expected_difficulty": "hard", "expected_size": 20},
    "contemporary": {"expected_difficulty": "hard", "expected_size": 20}
}

def verify_puzzles():
    puzzles_dir = "h:/Work/MyProject/ChineseMemory/data/puzzles"
    
    stats = {
        'total': 0,
        'solvable': 0,
        'not_solvable': 0,
        'difficulty_mismatch': 0,
        'size_mismatch': 0,
        'issues': []
    }
    
    for era_id, config in ERA_CONFIG.items():
        era_puzzle_dir = os.path.join(puzzles_dir, era_id)
        if not os.path.exists(era_puzzle_dir):
            continue
        
        expected_difficulty = config['expected_difficulty']
        expected_size = config['expected_size']
        
        puzzle_files = [f for f in os.listdir(era_puzzle_dir) if f.endswith('.json')]
        
        for puzzle_file in puzzle_files:
            stats['total'] += 1
            puzzle_path = os.path.join(era_puzzle_dir, puzzle_file)
            
            try:
                with open(puzzle_path, 'r', encoding='utf-8') as f:
                    puzzle = json.load(f)
                
                row_clues = puzzle['row_clues']
                col_clues = puzzle['col_clues']
                actual_size = puzzle['size']['rows']
                actual_difficulty = puzzle['difficulty']
                
                result = NonogramSolver.solve(row_clues, col_clues)
                
                if not result['solvable']:
                    stats['not_solvable'] += 1
                    progress = (result['known_cells'] / result['total_cells']) * 100
                    stats['issues'].append({
                        'type': 'not_solvable',
                        'era': era_id,
                        'puzzle': puzzle_file,
                        'name': puzzle['name'],
                        'progress': f"{progress:.1f}%"
                    })
                
                if actual_difficulty != expected_difficulty:
                    stats['difficulty_mismatch'] += 1
                    stats['issues'].append({
                        'type': 'difficulty_mismatch',
                        'era': era_id,
                        'puzzle': puzzle_file,
                        'name': puzzle['name'],
                        'expected': expected_difficulty,
                        'actual': actual_difficulty
                    })
                
                if actual_size != expected_size:
                    stats['size_mismatch'] += 1
                    stats['issues'].append({
                        'type': 'size_mismatch',
                        'era': era_id,
                        'puzzle': puzzle_file,
                        'name': puzzle['name'],
                        'expected': expected_size,
                        'actual': actual_size
                    })
                
                if result['solvable']:
                    stats['solvable'] += 1
                    
            except Exception as e:
                stats['issues'].append({
                    'type': 'error',
                    'era': era_id,
                    'puzzle': puzzle_file,
                    'error': str(e)
                })
    
    print("=" * 80)
    print("谜题验证结果")
    print("=" * 80)
    print(f"\n[统计]")
    print(f"  总谜题数: {stats['total']}")
    print(f"  可推理求解: {stats['solvable']} ({stats['solvable']/stats['total']*100:.1f}%)")
    print(f"  不可推理求解: {stats['not_solvable']} ({stats['not_solvable']/stats['total']*100:.1f}%)")
    print(f"  难度标注不匹配: {stats['difficulty_mismatch']}")
    print(f"  尺寸不匹配: {stats['size_mismatch']}")
    
    if stats['issues']:
        print("\n[问题详情]")
        for issue in stats['issues'][:20]:
            if issue['type'] == 'not_solvable':
                print(f"  [ERROR] 不可推理: {issue['era']}/{issue['puzzle']} - {issue['name']} (进度: {issue['progress']})")
            elif issue['type'] == 'difficulty_mismatch':
                print(f"  [WARN] 难度不匹配: {issue['era']}/{issue['puzzle']} - {issue['name']} (预期: {issue['expected']}, 实际: {issue['actual']})")
            elif issue['type'] == 'size_mismatch':
                print(f"  [WARN] 尺寸不匹配: {issue['era']}/{issue['puzzle']} - {issue['name']} (预期: {issue['expected']}x{issue['expected']}, 实际: {issue['actual']}x{issue['actual']})")
            else:
                print(f"  [ERROR] 错误: {issue['era']}/{issue['puzzle']} - {issue['error']}")
        
        if len(stats['issues']) > 20:
            print(f"  ... 还有 {len(stats['issues']) - 20} 个问题")
    
    return stats

if __name__ == "__main__":
    verify_puzzles()