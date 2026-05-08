import os
import sys
try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    print("需要安装 Pillow 库，请运行: pip install pillow")
    sys.exit(1)

ASSETS_DIR = "h:/Work/MyProject/ChineseMemory/assets/images"

ERA_COLORS = {
    "mythology": (194, 59, 33),
    "xia_shang_zhou": (153, 102, 51),
    "spring_autumn": (128, 128, 51),
    "qin_han": (51, 128, 51),
    "three_kingdoms": (51, 102, 153),
    "sui_tang": (153, 51, 153),
    "song_yuan": (102, 153, 102),
    "ming_qing": (178, 127, 77),
    "modern": (77, 77, 153),
    "contemporary": (204, 51, 51),
}

def create_era_icon(era_id, color):
    img = Image.new('RGBA', (64, 64), (245, 240, 235, 255))
    draw = ImageDraw.Draw(img)
    draw.ellipse((8, 8, 56, 56), fill=color)
    icon_path = os.path.join(ASSETS_DIR, "icons", f"era_{era_id}.png")
    img.save(icon_path)
    print(f"已生成时代图标: {icon_path}")

def create_story_illustration(story_id, title, era_dir):
    img = Image.new('RGBA', (640, 480), (245, 240, 235, 255))
    draw = ImageDraw.Draw(img)
    
    ink_color = (38, 38, 38, 230)
    red_color = (194, 59, 33, 230)
    blue_color = (46, 91, 138, 180)
    green_color = (46, 91, 46, 150)
    
    if story_id == "pangu":
        draw.rectangle([0, 0, 640, 200], fill=(191, 213, 239, 100))
        draw.rectangle([0, 340, 640, 480], fill=(153, 128, 89, 80))
        
        draw.polygon([(80, 340), (180, 160), (280, 340)], fill=green_color)
        draw.polygon([(300, 340), (440, 120), (580, 340)], fill=green_color)
        draw.polygon([(500, 340), (590, 190), (680, 340)], fill=green_color)
        
        draw.ellipse((480, 40, 560, 120), fill=red_color)
        for i in range(8):
            angle = i * 45
            cx, cy = 520, 80
            import math
            start_x = cx + math.cos(math.radians(angle)) * 45
            start_y = cy + math.sin(math.radians(angle)) * 45
            end_x = cx + math.cos(math.radians(angle)) * 65
            end_y = cy + math.sin(math.radians(angle)) * 65
            draw.line([(start_x, start_y), (end_x, end_y)], fill=red_color, width=2)
        
        draw.rectangle([196, 120, 204, 200], fill=ink_color)
        draw.polygon([(166, 120), (200, 100), (200, 140)], fill=ink_color)
        
        draw.ellipse((312, 180, 348, 216), fill=ink_color)
        draw.rectangle([316, 216, 344, 256], fill=ink_color)
        draw.line([(316, 228), (291, 213)], fill=ink_color, width=3)
        draw.line([(344, 228), (369, 213)], fill=ink_color, width=3)
        draw.line([(319, 256), (309, 281)], fill=ink_color, width=3)
        draw.line([(341, 256), (351, 281)], fill=ink_color, width=3)
        
        font = ImageFont.truetype("arial.ttf", 36) if os.path.exists("arial.ttf") else ImageFont.load_default()
        draw.text((240, 420), title, fill=ink_color, font=font)
    
    elif story_id == "nuwa":
        draw.rectangle([0, 0, 640, 300], fill=(191, 213, 239, 100))
        draw.rectangle([0, 300, 640, 480], fill=(153, 128, 89, 80))
        
        draw.ellipse((280, 100, 360, 180), fill=(255, 215, 0, 200))
        
        colors = [(255, 0, 0), (0, 255, 0), (0, 0, 255), (255, 255, 0), (128, 0, 128)]
        for i, c in enumerate(colors):
            draw.rectangle([80 + i * 110, 350, 160 + i * 110, 450], fill=c)
        
        draw.ellipse((480, 150, 560, 230), fill=(194, 59, 33, 200))
        draw.ellipse((500, 170, 540, 210), fill=(255, 255, 255, 150))
        
        font = ImageFont.truetype("arial.ttf", 36) if os.path.exists("arial.ttf") else ImageFont.load_default()
        draw.text((240, 420), title, fill=ink_color, font=font)
    
    elif story_id == "houyi":
        draw.rectangle([0, 0, 640, 350], fill=(255, 223, 186, 150))
        
        sun_positions = [(80, 80), (180, 50), (280, 80), (130, 150), (230, 130)]
        for x, y in sun_positions:
            draw.ellipse((x-25, y-25, x+25, y+25), fill=(255, 200, 50, 200))
        
        draw.ellipse((480, 80, 560, 160), fill=(255, 200, 50, 255))
        for i in range(8):
            angle = i * 45
            cx, cy = 520, 120
            import math
            start_x = cx + math.cos(math.radians(angle)) * 30
            start_y = cy + math.sin(math.radians(angle)) * 30
            end_x = cx + math.cos(math.radians(angle)) * 50
            end_y = cy + math.sin(math.radians(angle)) * 50
            draw.line([(start_x, start_y), (end_x, end_y)], fill=(255, 200, 50), width=2)
        
        draw.ellipse((280, 280, 320, 320), fill=ink_color)
        draw.rectangle([292, 320, 308, 380], fill=ink_color)
        
        import math
        start_x, start_y = 292, 330
        end_x, end_y = 292 - 80 * math.cos(math.radians(30)), 330 - 80 * math.sin(math.radians(30))
        draw.line([(start_x, start_y), (end_x, end_y)], fill=ink_color, width=3)
        
        bow_center_x, bow_center_y = 320, 350
        bow_radius = 60
        points = []
        for angle in range(-120, 61, 10):
            x = bow_center_x + bow_radius * math.cos(math.radians(angle))
            y = bow_center_y + bow_radius * math.sin(math.radians(angle))
            points.append((x, y))
        draw.polygon(points, fill=None, outline=ink_color, width=3)
        
        font = ImageFont.truetype("arial.ttf", 36) if os.path.exists("arial.ttf") else ImageFont.load_default()
        draw.text((240, 420), title, fill=ink_color, font=font)
    
    illustration_path = os.path.join(ASSETS_DIR, "illustrations", era_dir, f"{story_id}.png")
    img.save(illustration_path)
    print(f"已生成故事插图: {illustration_path}")

def create_puzzle_image(puzzle_id, size, solution):
    cell_size = 16
    img_width = size["cols"] * cell_size
    img_height = size["rows"] * cell_size
    
    img = Image.new('RGBA', (img_width, img_height), (255, 255, 255, 255))
    draw = ImageDraw.Draw(img)
    
    for row in range(size["rows"]):
        for col in range(size["cols"]):
            if solution[row][col] == 1:
                draw.rectangle([
                    col * cell_size,
                    row * cell_size,
                    (col + 1) * cell_size,
                    (row + 1) * cell_size
                ], fill=(38, 38, 38, 255))
    
    puzzle_path = os.path.join(ASSETS_DIR, "puzzles", "mythology", f"{puzzle_id}.png")
    img.save(puzzle_path)
    print(f"已生成谜题图片: {puzzle_path}")

def main():
    print("开始生成神话时代的图片...")
    
    create_era_icon("mythology", ERA_COLORS["mythology"])
    
    create_story_illustration("pangu", "盘古开天", "mythology")
    create_story_illustration("nuwa", "女娲补天", "mythology")
    create_story_illustration("houyi", "后羿射日", "mythology")
    
    import json
    puzzle_dir = "h:/Work/MyProject/ChineseMemory/data/puzzles/mythology"
    for filename in os.listdir(puzzle_dir):
        if filename.endswith(".json"):
            puzzle_path = os.path.join(puzzle_dir, filename)
            with open(puzzle_path, 'r', encoding='utf-8') as f:
                puzzle_data = json.load(f)
            create_puzzle_image(
                puzzle_data["id"],
                puzzle_data["size"],
                puzzle_data["solution"]
            )
    
    print("神话时代图片生成完成！")

if __name__ == "__main__":
    main()