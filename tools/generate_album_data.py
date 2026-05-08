#!/usr/bin/env python3
import os
import json
import re

# 画册配置数据（从内容生产文档提取）
ALBUMS_CONFIG = {
    # 人文历史（12本）
    "chinese_history": {
        "name": "中国通史",
        "picture_count": 105,
        "grid_size": {"x": 3, "y": 2},
        "difficulty": "5×5~25×25"
    },
    "world_history": {
        "name": "世界通史",
        "picture_count": 100,
        "grid_size": {"x": 3, "y": 2},
        "difficulty": "10×10~20×20"
    },
    "asian_civilization": {
        "name": "亚洲文明史",
        "picture_count": 95,
        "grid_size": {"x": 3, "y": 2},
        "difficulty": "10×10~20×20"
    },
    "european_civilization": {
        "name": "欧洲文明史",
        "picture_count": 95,
        "grid_size": {"x": 3, "y": 2},
        "difficulty": "10×10~20×20"
    },
    "africa_america_civilization": {
        "name": "非洲与美洲文明史",
        "picture_count": 90,
        "grid_size": {"x": 3, "y": 2},
        "difficulty": "10×10~20×20"
    },
    "war_military": {
        "name": "战争与军事史",
        "picture_count": 100,
        "grid_size": {"x": 3, "y": 2},
        "difficulty": "10×10~25×25"
    },
    "political_system": {
        "name": "政治与制度史",
        "picture_count": 90,
        "grid_size": {"x": 3, "y": 2},
        "difficulty": "10×10~25×25"
    },
    "economic_trade": {
        "name": "经济与贸易史",
        "picture_count": 85,
        "grid_size": {"x": 3, "y": 2},
        "difficulty": "10×10~25×25"
    },
    "world_heritage": {
        "name": "世界文化遗产",
        "picture_count": 80,
        "grid_size": {"x": 3, "y": 2},
        "difficulty": "10×10~25×25"
    },
    "chinese_heritage": {
        "name": "中国文化遗产",
        "picture_count": 85,
        "grid_size": {"x": 3, "y": 2},
        "difficulty": "10×10~25×25"
    },
    "archaeology": {
        "name": "考古发现与发掘",
        "picture_count": 80,
        "grid_size": {"x": 3, "y": 2},
        "difficulty": "10×10~25×25"
    },
    "historical_mysteries": {
        "name": "历史未解之谜",
        "picture_count": 70,
        "grid_size": {"x": 3, "y": 2},
        "difficulty": "10×10~25×25"
    },
    # 艺术创作（10本）
    "chinese_painting": {
        "name": "中国书画艺术",
        "picture_count": 80,
        "grid_size": {"x": 3, "y": 2},
        "difficulty": "10×10~20×20"
    },
    "western_painting": {
        "name": "西方绘画艺术",
        "picture_count": 80,
        "grid_size": {"x": 3, "y": 2},
        "difficulty": "10×10~20×20"
    },
    "sculpture": {
        "name": "雕塑艺术",
        "picture_count": 75,
        "grid_size": {"x": 3, "y": 2},
        "difficulty": "10×10~20×20"
    },
    "photography": {
        "name": "摄影艺术",
        "picture_count": 70,
        "grid_size": {"x": 3, "y": 2},
        "difficulty": "10×10~20×20"
    },
    "architecture": {
        "name": "建筑艺术",
        "picture_count": 75,
        "grid_size": {"x": 3, "y": 2},
        "difficulty": "10×10~25×25"
    },
    "crafts": {
        "name": "工艺美术",
        "picture_count": 70,
        "grid_size": {"x": 3, "y": 2},
        "difficulty": "10×10~25×25"
    },
    "design": {
        "name": "设计艺术",
        "picture_count": 70,
        "grid_size": {"x": 3, "y": 2},
        "difficulty": "10×10~20×20"
    },
    "performing_arts": {
        "name": "表演艺术",
        "picture_count": 70,
        "grid_size": {"x": 3, "y": 2},
        "difficulty": "10×10~25×25"
    },
    "folk_traditional": {
        "name": "民间与传统艺术",
        "picture_count": 70,
        "grid_size": {"x": 3, "y": 2},
        "difficulty": "10×10~20×20"
    },
    "contemporary_media": {
        "name": "当代传媒",
        "picture_count": 65,
        "grid_size": {"x": 3, "y": 2},
        "difficulty": "10×10~25×25"
    },
    # 自然地理（8本）
    "mountains_plateaus": {
        "name": "山脉与高原",
        "picture_count": 60,
        "grid_size": {"x": 3, "y": 2},
        "difficulty": "10×10~15×15"
    },
    "plains_basins": {
        "name": "平原与盆地",
        "picture_count": 60,
        "grid_size": {"x": 3, "y": 2},
        "difficulty": "10×10~15×15"
    },
    "deserts_gobi": {
        "name": "沙漠与戈壁",
        "picture_count": 60,
        "grid_size": {"x": 3, "y": 2},
        "difficulty": "10×10~20×20"
    },
    "rivers_lakes": {
        "name": "河流与湖泊",
        "picture_count": 65,
        "grid_size": {"x": 3, "y": 2},
        "difficulty": "10×10~20×20"
    },
    "atmosphere": {
        "name": "大气与天气",
        "picture_count": 60,
        "grid_size": {"x": 3, "y": 2},
        "difficulty": "10×10~20×20"
    },
    "geology": {
        "name": "地质地貌",
        "picture_count": 65,
        "grid_size": {"x": 3, "y": 2},
        "difficulty": "10×10~20×20"
    },
    "paleontology": {
        "name": "古生物化石",
        "picture_count": 65,
        "grid_size": {"x": 3, "y": 2},
        "difficulty": "10×10~20×20"
    },
    "nature_reserves": {
        "name": "自然保护区",
        "picture_count": 60,
        "grid_size": {"x": 3, "y": 2},
        "difficulty": "10×10~20×20"
    },
    # 生物世界（10本）
    "mammals": {
        "name": "哺乳动物",
        "picture_count": 80,
        "grid_size": {"x": 3, "y": 2},
        "difficulty": "10×10~20×20"
    },
    "birds": {
        "name": "鸟类",
        "picture_count": 75,
        "grid_size": {"x": 3, "y": 2},
        "difficulty": "10×10~20×20"
    },
    "reptiles": {
        "name": "爬行动物",
        "picture_count": 65,
        "grid_size": {"x": 3, "y": 2},
        "difficulty": "10×10~20×20"
    },
    "fish": {
        "name": "鱼类",
        "picture_count": 70,
        "grid_size": {"x": 3, "y": 2},
        "difficulty": "10×10~20×20"
    },
    "insects": {
        "name": "昆虫",
        "picture_count": 70,
        "grid_size": {"x": 3, "y": 2},
        "difficulty": "10×10~20×20"
    },
    "trees": {
        "name": "树木",
        "picture_count": 65,
        "grid_size": {"x": 3, "y": 2},
        "difficulty": "10×10~20×20"
    },
    "flowers": {
        "name": "花卉",
        "picture_count": 65,
        "grid_size": {"x": 3, "y": 2},
        "difficulty": "10×10~20×20"
    },
    "crops": {
        "name": "农作物",
        "picture_count": 60,
        "grid_size": {"x": 3, "y": 2},
        "difficulty": "10×10~20×20"
    },
    "fungi": {
        "name": "真菌",
        "picture_count": 60,
        "grid_size": {"x": 3, "y": 2},
        "difficulty": "10×10~20×20"
    },
    "ecosystems": {
        "name": "生态系统",
        "picture_count": 60,
        "grid_size": {"x": 3, "y": 2},
        "difficulty": "10×10~20×20"
    },
    # 生活社会（11本）
    "fashion": {
        "name": "时尚服饰",
        "picture_count": 65,
        "grid_size": {"x": 3, "y": 2},
        "difficulty": "10×10~20×20"
    },
    "food": {
        "name": "美食",
        "picture_count": 70,
        "grid_size": {"x": 3, "y": 2},
        "difficulty": "10×10~20×20"
    },
    "housing": {
        "name": "居住建筑",
        "picture_count": 65,
        "grid_size": {"x": 3, "y": 2},
        "difficulty": "10×10~20×20"
    },
    "transportation": {
        "name": "交通运输",
        "picture_count": 65,
        "grid_size": {"x": 3, "y": 2},
        "difficulty": "10×10~20×20"
    },
    "festivals": {
        "name": "节日庆典",
        "picture_count": 65,
        "grid_size": {"x": 3, "y": 2},
        "difficulty": "10×10~20×20"
    },
    "religion": {
        "name": "宗教信仰",
        "picture_count": 65,
        "grid_size": {"x": 3, "y": 2},
        "difficulty": "10×10~20×20"
    },
    "family": {
        "name": "家庭生活",
        "picture_count": 60,
        "grid_size": {"x": 3, "y": 2},
        "difficulty": "10×10~20×20"
    },
    "workplace": {
        "name": "职场工作",
        "picture_count": 60,
        "grid_size": {"x": 3, "y": 2},
        "difficulty": "10×10~20×20"
    },
    "education": {
        "name": "教育学习",
        "picture_count": 60,
        "grid_size": {"x": 3, "y": 2},
        "difficulty": "10×10~20×20"
    },
    "sports": {
        "name": "体育竞技",
        "picture_count": 70,
        "grid_size": {"x": 3, "y": 2},
        "difficulty": "10×10~20×20"
    },
    "entertainment": {
        "name": "休闲娱乐",
        "picture_count": 65,
        "grid_size": {"x": 3, "y": 2},
        "difficulty": "10×10~20×20"
    },
    # 科技工业（11本）
    "health": {
        "name": "健康医疗",
        "picture_count": 65,
        "grid_size": {"x": 3, "y": 2},
        "difficulty": "10×10~20×20"
    },
    "math_physics": {
        "name": "数学与物理",
        "picture_count": 75,
        "grid_size": {"x": 3, "y": 2},
        "difficulty": "10×10~20×20"
    },
    "chemistry_biology": {
        "name": "化学与生物",
        "picture_count": 70,
        "grid_size": {"x": 3, "y": 2},
        "difficulty": "10×10~20×20"
    },
    "astronomy": {
        "name": "天文学",
        "picture_count": 65,
        "grid_size": {"x": 3, "y": 2},
        "difficulty": "10×10~20×20"
    },
    "mechanical_electronic": {
        "name": "机械电子",
        "picture_count": 65,
        "grid_size": {"x": 3, "y": 2},
        "difficulty": "10×10~20×20"
    },
    "energy": {
        "name": "能源",
        "picture_count": 65,
        "grid_size": {"x": 3, "y": 2},
        "difficulty": "10×10~20×20"
    },
    "civil_engineering": {
        "name": "土木工程",
        "picture_count": 65,
        "grid_size": {"x": 3, "y": 2},
        "difficulty": "10×10~20×20"
    },
    "information_technology": {
        "name": "信息技术",
        "picture_count": 70,
        "grid_size": {"x": 3, "y": 2},
        "difficulty": "10×10~20×20"
    },
    "industrial_production": {
        "name": "工业生产",
        "picture_count": 65,
        "grid_size": {"x": 3, "y": 2},
        "difficulty": "10×10~20×20"
    },
    "agriculture_food": {
        "name": "农业与食品",
        "picture_count": 65,
        "grid_size": {"x": 3, "y": 2},
        "difficulty": "10×10~20×20"
    },
    "transport_industry": {
        "name": "交通工业",
        "picture_count": 65,
        "grid_size": {"x": 3, "y": 2},
        "difficulty": "10×10~20×20"
    },
    # 综合素材（4本）
    "abstract": {
        "name": "抽象图案",
        "picture_count": 60,
        "grid_size": {"x": 3, "y": 2},
        "difficulty": "10×10~20×20"
    },
    "symbols": {
        "name": "符号标志",
        "picture_count": 60,
        "grid_size": {"x": 3, "y": 2},
        "difficulty": "10×10~20×20"
    },
    "textures": {
        "name": "纹理材质",
        "picture_count": 60,
        "grid_size": {"x": 3, "y": 2},
        "difficulty": "10×10~20×20"
    },
    "miscellaneous": {
        "name": "综合素材",
        "picture_count": 60,
        "grid_size": {"x": 3, "y": 2},
        "difficulty": "10×10~20×20"
    }
}

def parse_album_md(md_path):
    """从MD文件中解析图片信息"""
    if not os.path.exists(md_path):
        return None
    
    with open(md_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 提取画册信息
    info = {}
    info_match = re.search(r'\| 属性 \| 内容 \|[\s\S]*?(?=\n## )', content)
    if info_match:
        lines = info_match.group(0).split('\n')
        for line in lines:
            if '|' in line and '属性' not in line and '----' not in line:
                parts = [p.strip() for p in line.split('|') if p.strip()]
                if len(parts) >= 2:
                    info[parts[0]] = parts[1]
    
    # 提取图片列表
    pictures = []
    chapters = re.split(r'### 第[一二三]+章：', content)[1:]
    chapter_order = 0
    
    for chapter in chapters:
        chapter_name_match = re.match(r'([^\n]+)', chapter)
        chapter_name = chapter_name_match.group(1) if chapter_name_match else f"第{chapter_order + 1}章"
        
        # 匹配图片条目：数字. 标题 - 描述
        image_pattern = re.compile(r'(\d+)\.\s*([^-]+?)\s*-\s*(.+)')
        matches = image_pattern.findall(chapter)
        
        for match in matches:
            idx = int(match[0])
            title = match[1].strip()
            summary = match[2].strip()
            
            if "待填充图片" not in title:
                pictures.append({
                    "id": title.lower().replace(' ', '_').replace('、', '_').replace('·', '_').replace('（', '_').replace('）', '_').replace('-', '_'),
                    "title": title,
                    "summary": summary,
                    "order": idx - 1,
                    "chapter": chapter_name
                })
    
    return {
        "info": info,
        "pictures": pictures
    }

def generate_picture_data(album_id, config, parsed_data=None):
    """生成单本画册的图片数据"""
    picture_count = config["picture_count"]
    grid_size = config["grid_size"]
    puzzle_count = grid_size["x"] * grid_size["y"]
    
    pictures = []
    
    if parsed_data and parsed_data["pictures"]:
        # 使用解析的数据
        for pic in parsed_data["pictures"]:
            pic_id = pic["id"]
            puzzles = [f"{pic_id}_{i}" for i in range(puzzle_count)]
            
            pictures.append({
                "id": pic_id,
                "title": pic["title"],
                "summary": pic["summary"],
                "full_text": f"关于「{pic['title']}」的详细介绍。{pic['summary']}",
                "image": f"res://assets/images/illustrations/{album_id}/{pic_id}.png",
                "image_grid": grid_size,
                "puzzles": puzzles,
                "order": pic["order"]
            })
    else:
        # 生成默认数据
        for i in range(picture_count):
            pic_id = f"{album_id}_{i:03d}"
            puzzles = [f"{pic_id}_{j}" for j in range(puzzle_count)]
            
            pictures.append({
                "id": pic_id,
                "title": f"{config['name']} - 图片{i + 1}",
                "summary": f"{config['name']}相关图片",
                "full_text": f"这是{config['name']}中的第{i + 1}张图片。",
                "image": f"res://assets/images/illustrations/{album_id}/{pic_id}.png",
                "image_grid": grid_size,
                "puzzles": puzzles,
                "order": i
            })
    
    return {
        "album_id": album_id,
        "pictures": pictures
    }

def generate_empty_puzzle(puzzle_id, album_id, picture_id, size=10):
    """生成空的数织关卡数据"""
    # 生成简单的对角线索引
    row_clues = []
    col_clues = []
    solution = []
    
    for i in range(size):
        # 简单的对角线图案
        row_clue = [1] if i < size // 2 else []
        col_clue = [1] if i < size // 2 else []
        row_clues.append(row_clue)
        col_clues.append(col_clue)
        
        row = [1 if j <= i and i < size // 2 else 0 for j in range(size)]
        solution.append(row)
    
    return {
        "id": puzzle_id,
        "name": f"{picture_id} - 分块{puzzle_id.split('_')[-1]}",
        "picture_id": picture_id,
        "size": {"rows": size, "cols": size},
        "difficulty": "easy",
        "row_clues": row_clues,
        "col_clues": col_clues,
        "solution": solution,
        "hint_cells": [],
        "source_rect": {"x": 0, "y": 0, "w": 832, "h": 832}
    }

def main():
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    docs_dir = os.path.join(base_dir, "docs", "albums")
    pictures_dir = os.path.join(base_dir, "data", "pictures")
    puzzles_dir = os.path.join(base_dir, "data", "puzzles")
    illustrations_dir = os.path.join(base_dir, "assets", "images", "illustrations")
    
    # 确保目录存在
    os.makedirs(pictures_dir, exist_ok=True)
    os.makedirs(puzzles_dir, exist_ok=True)
    os.makedirs(illustrations_dir, exist_ok=True)
    
    total_pictures = 0
    total_puzzles = 0
    
    for album_id, config in ALBUMS_CONFIG.items():
        print(f"Processing album: {album_id} - {config['name']}")
        
        # 解析MD文档
        md_path = os.path.join(docs_dir, f"{str(list(ALBUMS_CONFIG.keys()).index(album_id) + 1).zfill(2)}_{album_id}.md")
        parsed_data = parse_album_md(md_path)
        
        # 生成图片数据
        picture_data = generate_picture_data(album_id, config, parsed_data)
        
        # 保存图片数据文件
        picture_file = os.path.join(pictures_dir, f"{album_id}.json")
        with open(picture_file, 'w', encoding='utf-8') as f:
            json.dump(picture_data, f, ensure_ascii=False, indent=2)
        
        # 创建谜题目录
        album_puzzles_dir = os.path.join(puzzles_dir, album_id)
        os.makedirs(album_puzzles_dir, exist_ok=True)
        
        # 创建插图目录
        album_illustration_dir = os.path.join(illustrations_dir, album_id)
        os.makedirs(album_illustration_dir, exist_ok=True)
        
        # 获取网格大小
        grid_size = config["grid_size"]
        
        # 生成谜题数据（对于已有图片的画册）
        if album_id == "chinese_history":
            # 已有谜题的画册跳过
            print(f"  -> Skipping puzzle generation (already exists)")
        else:
            # 为每张图片生成谜题
            puzzle_count_per_pic = grid_size["x"] * grid_size["y"]
            
            for pic in picture_data["pictures"]:
                for i in range(puzzle_count_per_pic):
                    puzzle_id = f"{pic['id']}_{i}"
                    puzzle_data = generate_empty_puzzle(puzzle_id, album_id, pic["id"])
                    
                    puzzle_file = os.path.join(album_puzzles_dir, f"{puzzle_id}.json")
                    with open(puzzle_file, 'w', encoding='utf-8') as f:
                        json.dump(puzzle_data, f, ensure_ascii=False, indent=2)
        
        pic_count = len(picture_data["pictures"])
        total_pictures += pic_count
        total_puzzles += pic_count * (grid_size["x"] * grid_size["y"])
        
        print(f"  -> Generated {pic_count} pictures")
    
    print(f"\n=== Summary ===")
    print(f"Total albums processed: {len(ALBUMS_CONFIG)}")
    print(f"Total pictures generated: {total_pictures}")
    print(f"Total puzzles generated: {total_puzzles}")

if __name__ == "__main__":
    main()
