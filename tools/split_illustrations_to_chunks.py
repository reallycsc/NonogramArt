import os
import json
from PIL import Image

def split_illustrations_to_chunks():
    stories_dir = "h:/Work/MyProject/ChineseMemory/data/stories"
    illustrations_dir = "h:/Work/MyProject/ChineseMemory/assets/images/illustrations"
    
    print("=" * 60)
    print("将故事图片分块并按数字编号命名")
    print("=" * 60)
    
    for story_file in os.listdir(stories_dir):
        if not story_file.endswith('.json'):
            continue
        
        era_id = story_file.replace('.json', '')
        story_path = os.path.join(stories_dir, story_file)
        
        with open(story_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        era_illustration_dir = os.path.join(illustrations_dir, era_id)
        os.makedirs(era_illustration_dir, exist_ok=True)
        
        for story in data['stories']:
            story_id = story['id']
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
                    
                    x = col * cell_width
                    y = row * cell_height
                    w = cell_width
                    h = cell_height
                    
                    region = img.crop((x, y, x + w, y + h))
                    
                    chunk_filename = f"{story_id}_{puzzle_idx}.png"
                    chunk_path = os.path.join(era_illustration_dir, chunk_filename)
                    region.save(chunk_path)
                    
                    print(f"保存分块: {chunk_filename}")
                    
                    puzzle_idx += 1
        
        print(f"完成时代: {era_id}")
    
    print("\n" + "=" * 60)
    print("分块完成！")
    print("=" * 60)

if __name__ == "__main__":
    split_illustrations_to_chunks()