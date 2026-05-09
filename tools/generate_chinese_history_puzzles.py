import os
import json
from pathlib import Path

chapter1_pictures = [
    {"id": "chapter1_01_yuanmou", "title": "元谋人遗址", "grid_size": 5, "difficulty": "tutorial"},
    {"id": "chapter1_02_beijing_ape", "title": "北京猿人生活场景", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter1_03_shandingdong", "title": "山顶洞人狩猎", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter1_04_hemudu", "title": "河姆渡文化", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter1_05_yangshao", "title": "仰韶文化彩陶", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter1_06_liangzhu", "title": "良渚古城", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter1_07_huangdi", "title": "黄帝部落联盟", "grid_size": 10, "difficulty": "easy"},
    {"id": "chapter1_08_dayu", "title": "大禹治水", "grid_size": 10, "difficulty": "easy"},
]

def generate_row_clues(row):
    clues = []
    count = 0
    for cell in row:
        if cell == 1:
            count += 1
        else:
            if count > 0:
                clues.append(count)
                count = 0
    if count > 0:
        clues.append(count)
    return clues

def generate_puzzle_pattern(grid_size, chunk_index):
    grid = []
    for i in range(grid_size):
        row = []
        for j in range(grid_size):
            pattern = (i + j + chunk_index) % 5
            if pattern == 0 or pattern == 2:
                row.append(1)
            elif pattern == 1 and i % 2 == 0:
                row.append(1)
            elif pattern == 3 and j % 2 == 0:
                row.append(1)
            elif pattern == 4 and (i + j) % 3 == 0:
                row.append(1)
            else:
                row.append(0)
        grid.append(row)
    return grid

def generate_puzzle(picture, chunk_index):
    grid_size = picture["grid_size"]
    difficulty = picture["difficulty"]
    puzzle_id = f"{picture['id']}_{chunk_index}"
    
    if chunk_index == 0 and picture["id"] == "chapter1_01_yuanmou":
        name = f"{picture['title']} - 分块{chunk_index}（新手引导）"
    else:
        name = f"{picture['title']}-分块{chunk_index}"
    
    grid = generate_puzzle_pattern(grid_size, chunk_index)
    
    row_clues = [generate_row_clues(row) for row in grid]
    col_clues = []
    for j in range(grid_size):
        col = [grid[i][j] for i in range(grid_size)]
        col_clues.append(generate_row_clues(col))
    
    source_rect = {
        "x": (chunk_index % 3) * (2496 // 3),
        "y": (chunk_index // 3) * (1664 // 2),
        "w": 2496 // 3,
        "h": 1664 // 2
    }
    
    puzzle = {
        "id": puzzle_id,
        "name": name,
        "picture_id": picture["id"],
        "size": {
            "rows": grid_size,
            "cols": grid_size
        },
        "difficulty": difficulty,
        "row_clues": row_clues,
        "col_clues": col_clues,
        "solution": grid,
        "hint_cells": [],
        "source_rect": source_rect
    }
    
    return puzzle

def main():
    output_dir = Path("data/puzzles/chinese_history")
    output_dir.mkdir(parents=True, exist_ok=True)
    
    print("开始生成《中国通史》第一章的8张图片对应的数织关卡...")
    print(f"输出目录: {output_dir.resolve()}")
    print("=" * 60)
    
    for i, picture in enumerate(chapter1_pictures, 1):
        print(f"\n[{i}/8] 正在生成: {picture['title']}")
        print(f"网格大小: {picture['grid_size']}×{picture['grid_size']}")
        print(f"难度: {picture['difficulty']}")
        
        for chunk_idx in range(6):
            puzzle = generate_puzzle(picture, chunk_idx)
            file_path = output_dir / f"{puzzle['id']}.json"
            with open(file_path, 'w', encoding='utf-8') as f:
                json.dump(puzzle, f, ensure_ascii=False, indent=2)
            print(f"  生成: {file_path.name}")
    
    print("\n" + "=" * 60)
    print("生成完成！共生成 48 个数织关卡（8张图片 × 6个分块）")

if __name__ == "__main__":
    main()