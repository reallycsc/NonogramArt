import json
import os
from PIL import Image

puzzles_dir = r"h:\Work\MyProject\NonogramArt\data\puzzles\chinese_history"
images_dir = r"h:\Work\MyProject\NonogramArt\assets\images\illustrations\chinese_history\chapter1"
output_dir = images_dir  

os.makedirs(output_dir, exist_ok=True)

chapter1_images = [
    {"id": "chapter1_01_yuanmou", "name": "元谋人遗址"},
    {"id": "chapter1_02_beijing_ape", "name": "北京猿人生活场景"},
    {"id": "chapter1_03_shandingdong", "name": "山顶洞人狩猎"},
    {"id": "chapter1_04_hemudu", "name": "河姆渡文化"},
    {"id": "chapter1_05_yangshao", "name": "仰韶文化彩陶"},
    {"id": "chapter1_06_liangzhu", "name": "良渚古城"},
    {"id": "chapter1_07_huangdi", "name": "黄帝部落联盟"},
    {"id": "chapter1_08_dayu", "name": "大禹治水"}
]

def read_puzzle_file(filename):
    filepath = os.path.join(puzzles_dir, filename)
    if os.path.exists(filepath):
        with open(filepath, 'r', encoding='utf-8') as f:
            return json.load(f)
    return None

def get_puzzle_mask(image_id):
    blocks = []
    for i in range(6):
        filename = f"{image_id}_{i}.json"
        puzzle = read_puzzle_file(filename)
        if puzzle:
            blocks.append(puzzle)
    
    if len(blocks) != 6:
        print(f"警告: {image_id} 缺少分块文件，只有 {len(blocks)}/6 个")
        return None
    
    full_mask = []
    for row in range(2):
        for block_row in range(10):
            mask_row = []
            for col in range(3):
                block_idx = row * 3 + col
                if block_idx < len(blocks):
                    solution = blocks[block_idx]["solution"]
                    if block_row < len(solution):
                        mask_row.extend(solution[block_row])
            full_mask.append(mask_row)
    
    return full_mask

def process_image(image_id):
    img_path = os.path.join(images_dir, f"{image_id}.png")
    if not os.path.exists(img_path):
        print(f"图片文件不存在: {img_path}")
        return None
    
    img = Image.open(img_path)
    img_width, img_height = img.size
    
    mask = get_puzzle_mask(image_id)
    if not mask:
        return None
    
    block_width = img_width // 3
    block_height = img_height // 2
    
    pixel_img = Image.new('RGB', (30, 20))
    
    for y_block in range(2):
        for y_pixel in range(10):
            for x_block in range(3):
                for x_pixel in range(10):
                    sample_x = int(x_block * block_width + block_width * (x_pixel + 0.5) / 10)
                    sample_y = int(y_block * block_height + block_height * (y_pixel + 0.5) / 10)
                    sample_x = min(sample_x, img_width - 1)
                    sample_y = min(sample_y, img_height - 1)
                    
                    pixel_color = img.getpixel((sample_x, sample_y))
                    pixel_img.putpixel((x_block * 10 + x_pixel, y_block * 10 + y_pixel), pixel_color)
    
    return pixel_img, img_width, img_height

def upscale_image(img, target_width, target_height):
    upscaled = img.resize((target_width, target_height), Image.Resampling.NEAREST)
    return upscaled

for item in chapter1_images:
    image_id = item["id"]
    image_name = item["name"]
    
    print(f"\n正在处理: {image_name} ({image_id})")
    result = process_image(image_id)
    
    if result:
        pixel_img, target_width, target_height = result
        
        upscaled_img = upscale_image(pixel_img, target_width, target_height)
        
        output_path = os.path.join(output_dir, f"{image_id}_pixel.png")
        upscaled_img.save(output_path, 'PNG')
        
        print(f"已生成: {image_id}_pixel.png ({target_width}x{target_height})")
    else:
        print(f"跳过: {image_id}")

print("\n所有像素图片已生成完成！")