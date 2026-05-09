import json
import os

config_path = r"H:\Work\MyProject\NonogramArt\data\pictures\chinese_history.json"

chapter1_mapping = [
    {"old_id": "元谋人遗址", "new_prefix": "chapter1_01_yuanmou"},
    {"old_id": "北京猿人生活场景", "new_prefix": "chapter1_02_beijing_ape"},
    {"old_id": "山顶洞人狩猎", "new_prefix": "chapter1_03_shandingdong"},
    {"old_id": "河姆渡文化", "new_prefix": "chapter1_04_hemudu"},
    {"old_id": "仰韶文化彩陶", "new_prefix": "chapter1_05_yangshao"},
    {"old_id": "良渚古城", "new_prefix": "chapter1_06_liangzhu"},
    {"old_id": "黄帝部落联盟", "new_prefix": "chapter1_07_huangdi"},
    {"old_id": "大禹治水", "new_prefix": "chapter1_08_dayu"}
]

with open(config_path, 'r', encoding='utf-8') as f:
    data = json.load(f)

updated_count = 0
for picture in data["pictures"]:
    for mapping in chapter1_mapping:
        if picture["id"] == mapping["old_id"]:
            old_image = picture["image"]
            picture["image"] = f"res://assets/images/illustrations/chinese_history/{mapping['new_prefix']}.png"
            
            old_puzzles = picture["puzzles"]
            picture["puzzles"] = [f"{mapping['new_prefix']}_{i}" for i in range(6)]
            
            print(f"更新: {mapping['old_id']}")
            print(f"  图片: {old_image} -> {picture['image']}")
            print(f"  谜题: {old_puzzles} -> {picture['puzzles']}")
            print()
            updated_count += 1
            break

with open(config_path, 'w', encoding='utf-8') as f:
    json.dump(data, f, indent='\t', ensure_ascii=False)

print(f"\n共更新 {updated_count} 个配置项")