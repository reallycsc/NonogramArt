import os
import json
import shutil

def rename_puzzles_to_numbers():
    stories_dir = "h:/Work/MyProject/ChineseMemory/data/stories"
    puzzles_dir = "h:/Work/MyProject/ChineseMemory/data/puzzles"
    
    print("=" * 60)
    print("将数织关卡重命名为数字编号")
    print("=" * 60)
    
    for story_file in os.listdir(stories_dir):
        if not story_file.endswith('.json'):
            continue
        
        era_id = story_file.replace('.json', '')
        story_path = os.path.join(stories_dir, story_file)
        
        with open(story_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        era_puzzle_dir = os.path.join(puzzles_dir, era_id)
        if not os.path.exists(era_puzzle_dir):
            continue
        
        for story in data['stories']:
            story_id = story['id']
            old_puzzles = story['puzzles']
            
            new_puzzles = []
            for idx, old_puzzle_id in enumerate(old_puzzles):
                new_puzzle_id = f"{story_id}_{idx}"
                new_puzzles.append(new_puzzle_id)
                
                old_puzzle_path = os.path.join(era_puzzle_dir, f"{old_puzzle_id}.json")
                new_puzzle_path = os.path.join(era_puzzle_dir, f"{new_puzzle_id}.json")
                
                if os.path.exists(old_puzzle_path):
                    with open(old_puzzle_path, 'r', encoding='utf-8') as f:
                        puzzle_data = json.load(f)
                    
                    puzzle_data['id'] = new_puzzle_id
                    puzzle_data['name'] = str(idx)
                    
                    with open(new_puzzle_path, 'w', encoding='utf-8') as f:
                        json.dump(puzzle_data, f, indent='\t', ensure_ascii=False)
                    
                    os.remove(old_puzzle_path)
                    print(f"重命名: {old_puzzle_id} → {new_puzzle_id}")
            
            story['puzzles'] = new_puzzles
        
        with open(story_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent='\t', ensure_ascii=False)
        
        print(f"更新故事文件: {story_file}")
    
    print("\n" + "=" * 60)
    print("重命名完成！")
    print("=" * 60)

if __name__ == "__main__":
    rename_puzzles_to_numbers()