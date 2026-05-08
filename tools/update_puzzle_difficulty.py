import os
import json

def update_puzzle_size_and_difficulty(puzzle_path, new_rows, new_cols, new_difficulty):
    with open(puzzle_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    old_rows = data['size']['rows']
    old_cols = data['size']['cols']
    old_difficulty = data.get('difficulty', 'unknown')
    
    scale_rows = new_rows / old_rows
    scale_cols = new_cols / old_cols
    
    data['size']['rows'] = new_rows
    data['size']['cols'] = new_cols
    data['difficulty'] = new_difficulty
    
    old_solution = data['solution']
    new_solution = []
    
    for i in range(new_rows):
        old_row_idx = int(i / scale_rows)
        new_row = []
        for j in range(new_cols):
            old_col_idx = int(j / scale_cols)
            if old_row_idx < len(old_solution) and old_col_idx < len(old_solution[old_row_idx]):
                new_row.append(old_solution[old_row_idx][old_col_idx])
            else:
                new_row.append(0)
        new_solution.append(new_row)
    
    data['solution'] = new_solution
    
    old_row_clues = data['row_clues']
    new_row_clues = []
    for i in range(new_rows):
        old_row_idx = int(i / scale_rows)
        if old_row_idx < len(old_row_clues):
            new_row_clues.append(old_row_clues[old_row_idx])
        else:
            new_row_clues.append([0])
    
    data['row_clues'] = new_row_clues
    
    old_col_clues = data['col_clues']
    new_col_clues = []
    for j in range(new_cols):
        old_col_idx = int(j / scale_cols)
        if old_col_idx < len(old_col_clues):
            new_col_clues.append(old_col_clues[old_col_idx])
        else:
            new_col_clues.append([0])
    
    data['col_clues'] = new_col_clues
    
    with open(puzzle_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent='\t', ensure_ascii=False)
    
    print(f"Updated: {os.path.basename(puzzle_path)}")
    print(f"  Size: {old_rows}x{old_cols} → {new_rows}x{new_cols}")
    print(f"  Difficulty: {old_difficulty} → {new_difficulty}")
    print()

def main():
    era_configs = [
        {
            "era_id": "qin_han",
            "name": "秦汉",
            "new_size": (15, 15),
            "new_difficulty": "medium"
        },
        {
            "era_id": "three_kingdoms",
            "name": "三国两晋南北朝",
            "new_size": (15, 15),
            "new_difficulty": "medium"
        },
        {
            "era_id": "sui_tang",
            "name": "隋唐",
            "new_size": (15, 15),
            "new_difficulty": "medium"
        },
        {
            "era_id": "song_yuan",
            "name": "宋元",
            "new_size": (20, 20),
            "new_difficulty": "hard"
        },
        {
            "era_id": "ming_qing",
            "name": "明清",
            "new_size": (20, 20),
            "new_difficulty": "hard"
        },
        {
            "era_id": "modern",
            "name": "近现代",
            "new_size": (20, 20),
            "new_difficulty": "hard"
        },
        {
            "era_id": "contemporary",
            "name": "当代",
            "new_size": (20, 20),
            "new_difficulty": "hard"
        },
        {
            "era_id": "mythology",
            "name": "神话时代",
            "new_size": (5, 5),
            "new_difficulty": "easy"
        }
    ]
    
    for config in era_configs:
        era_dir = f"h:/Work/MyProject/ChineseMemory/data/puzzles/{config['era_id']}"
        if not os.path.exists(era_dir):
            print(f"目录不存在: {era_dir}")
            continue
        
        print("=" * 60)
        print(f"正在更新【{config['name']}】时代的谜题")
        print(f"新尺寸: {config['new_size'][0]}x{config['new_size'][1]}")
        print(f"新难度: {config['new_difficulty']}")
        print("-" * 60)
        
        puzzle_files = [f for f in os.listdir(era_dir) if f.endswith('.json')]
        
        for puzzle_file in puzzle_files:
            puzzle_path = os.path.join(era_dir, puzzle_file)
            update_puzzle_size_and_difficulty(
                puzzle_path,
                config['new_size'][0],
                config['new_size'][1],
                config['new_difficulty']
            )
    
    print("=" * 60)
    print("所有谜题难度更新完成！")
    print("=" * 60)

if __name__ == "__main__":
    main()