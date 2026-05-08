import os
from PIL import Image, ImageDraw, ImageFont


def generate_placeholder(output_path, title, era_name):
    width, height = 3136, 1344
    img = Image.new('RGB', (width, height), color=(245, 240, 232))
    draw = ImageDraw.Draw(img)
    
    font_large = ImageFont.truetype("arial.ttf", 64) if os.path.exists("arial.ttf") else ImageFont.load_default()
    font_medium = ImageFont.truetype("arial.ttf", 48) if os.path.exists("arial.ttf") else ImageFont.load_default()
    
    era_text = f"【{era_name}】"
    title_text = title
    
    era_bbox = draw.textbbox((0, 0), era_text, font=font_medium)
    title_bbox = draw.textbbox((0, 0), title_text, font=font_large)
    
    era_x = (width - era_bbox[2]) // 2
    era_y = (height - 100) // 3
    
    title_x = (width - title_bbox[2]) // 2
    title_y = era_y + 80
    
    draw.text((era_x, era_y), era_text, font=font_medium, fill=(44, 44, 44))
    draw.text((title_x, title_y), title_text, font=font_large, fill=(194, 59, 34))
    
    draw.rectangle([(50, 50), (width-50, height-50)], outline=(194, 59, 34), width=4)
    
    for i in range(10):
        x = 100 + i * 300
        y = height // 2
        draw.line([(x, y-100), (x, y+100)], fill=(200, 200, 200), width=2)
        draw.line([(x-50, y), (x+50, y)], fill=(200, 200, 200), width=2)
    
    img.save(output_path)
    print(f"占位图片已生成: {output_path}")


def main():
    missing_images = [
        ("modern", "wusi", "五四运动", "近现代"),
    ]
    
    for era_id, story_id, title, era_name in missing_images:
        output_dir = f"h:/Work/MyProject/ChineseMemory/assets/images/illustrations/{era_id}"
        os.makedirs(output_dir, exist_ok=True)
        output_path = os.path.join(output_dir, f"{story_id}.png")
        generate_placeholder(output_path, title, era_name)
    
    print("\n占位图片生成完成！")


if __name__ == "__main__":
    main()