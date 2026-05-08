import os
import json
from PIL import Image

def get_image_size(image_path):
    try:
        img = Image.open(image_path)
        return img.size
    except Exception as e:
        print(f"无法读取图片 {image_path}: {e}")
        return None

def fix_source_rect():
    stories_dir = "h:/Work/MyProject/ChineseMemory/data/stories"
    puzzles_dir = "h:/Work/MyProject/ChineseMemory/data/puzzles"
    
    for story_file in os.listdir(stories_dir):
        if not story_file.endswith('.json'):
            continue
        
        era_id = story_file.replace('.json', '')
        story_path = os.path.join(stories_dir, story_file)
        
        with open(story_path, 'r', encoding='utf-8') as f:
            story_data = json.load(f)
        
        for story in story_data['stories']:
            story_id = story['id']
            illustration_path = story['illustration'].replace('res://', 'h:/Work/MyProject/ChineseMemory/')
            grid_x = story['illustration_grid']['x']
            grid_y = story['illustration_grid']['y']
            puzzles = story['puzzles']
            
            if not os.path.exists(illustration_path):
                print(f"警告：插图不存在: {illustration_path}")
                continue
            
            img_size = get_image_size(illustration_path)
            if not img_size:
                print(f"警告：无法读取图片尺寸: {illustration_path}")
                continue
            
            img_width, img_height = img_size
            cell_width = img_width // grid_x
            cell_height = img_height // grid_y
            
            print(f"\n{'='*60}")
            print(f"故事: {story['title']} ({story_id})")
            print(f"插图: {os.path.basename(illustration_path)}")
            print(f"尺寸: {img_width} × {img_height}")
            print(f"网格: {grid_x} × {grid_y}")
            print(f"单元格: {cell_width} × {cell_height}")
            print(f"谜题数量: {len(puzzles)}")
            
            puzzle_idx = 0
            for row in range(grid_y):
                for col in range(grid_x):
                    if puzzle_idx >= len(puzzles):
                        break
                    
                    puzzle_id = puzzles[puzzle_idx]
                    puzzle_path = os.path.join(puzzles_dir, era_id, f"{puzzle_id}.json")
                    
                    if not os.path.exists(puzzle_path):
                        print(f"警告：谜题不存在: {puzzle_path}")
                        puzzle_idx += 1
                        continue
                    
                    with open(puzzle_path, 'r', encoding='utf-8') as f:
                        puzzle_data = json.load(f)
                    
                    old_rect = puzzle_data.get('source_rect', {})
                    new_rect = {
                        'x': col * cell_width,
                        'y': row * cell_height,
                        'w': cell_width,
                        'h': cell_height
                    }
                    
                    puzzle_data['source_rect'] = new_rect
                    
                    with open(puzzle_path, 'w', encoding='utf-8') as f:
                        json.dump(puzzle_data, f, indent='\t', ensure_ascii=False)
                    
                    print(f"  [{row},{col}] {puzzle_id}: {old_rect} → {new_rect}")
                    puzzle_idx += 1
            
            if puzzle_idx < len(puzzles):
                print(f"警告：谜题数量 ({len(puzzles)}) 超过网格数 ({grid_x * grid_y})")

    print("\n" + "="*60)
    print("所有谜题的 source_rect 已修复完成！")

if __name__ == "__main__":
    fix_source_rect()