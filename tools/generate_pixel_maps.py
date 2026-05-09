import json
import os

puzzles_dir = r"h:\Work\MyProject\ChineseMemory\data\puzzles\chinese_history"
output_dir = r"h:\Work\MyProject\ChineseMemory\output_pixel_maps"

os.makedirs(output_dir, exist_ok=True)

chapter1_images = [
    "yuanmouren",     # 元谋人遗址
    "beijing_yuanren", # 北京猿人生活场景
    "shandingdong",    # 山顶洞人狩猎
    "hemudu",          # 河姆渡文化
    "yangshao",        # 仰韶文化彩陶
    "liangzhu",        # 良渚古城
    "huangdi",         # 黄帝部落联盟
    "dayu"             # 大禹治水
]

def read_puzzle_file(filename):
    filepath = os.path.join(puzzles_dir, filename)
    if os.path.exists(filepath):
        with open(filepath, 'r', encoding='utf-8') as f:
            return json.load(f)
    return None

def merge_puzzle_blocks(image_id):
    blocks = []
    for i in range(6):
        filename = f"{image_id}_{i}.json"
        puzzle = read_puzzle_file(filename)
        if puzzle:
            blocks.append(puzzle)
    
    if len(blocks) != 6:
        print(f"警告: {image_id} 缺少分块文件，只有 {len(blocks)}/6 个")
        return None
    
    block_order = [(0, 0), (1, 0), (2, 0),  # 第一行
                   (0, 1), (1, 1), (2, 1)]  # 第二行
    
    full_grid = []
    
    for row in range(2):
        for block_row in range(10):
            full_row = []
            for col in range(3):
                block_idx = row * 3 + col
                if block_idx < len(blocks):
                    solution = blocks[block_idx]["solution"]
                    if block_row < len(solution):
                        full_row.extend(solution[block_row])
            full_grid.append(full_row)
    
    return full_grid

def grid_to_text(grid):
    text = ""
    for row in grid:
        line = "".join(["█" if cell == 1 else " " for cell in row])
        text += line + "\n"
    return text

def grid_to_json(grid):
    return json.dumps(grid, indent=2, ensure_ascii=False)

for image_id in chapter1_images:
    grid = merge_puzzle_blocks(image_id)
    if grid:
        text_content = grid_to_text(grid)
        json_content = grid_to_json(grid)
        
        txt_file = os.path.join(output_dir, f"{image_id}_pixel_map.txt")
        json_file = os.path.join(output_dir, f"{image_id}_pixel_map.json")
        
        with open(txt_file, 'w', encoding='utf-8') as f:
            f.write(text_content)
        
        with open(json_file, 'w', encoding='utf-8') as f:
            f.write(json_content)
        
        print(f"已生成: {image_id}")
    else:
        print(f"跳过: {image_id}")

print("\n所有像素图已生成完成！")