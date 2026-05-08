import os
import json
import requests
from PIL import Image
from io import BytesIO

API_BASE_URL = "https://ark.cn-beijing.volces.com/api/v3/images/generations"
API_KEY = "ark-769a3f8a-9ceb-4556-ae95-d882f7966850-2be63"
MODEL = "doubao-seedream-4-5-251128"

OUTPUT_DIR = "h:/Work/MyProject/ChineseMemory/assets/images/icons"


def generate_jimeng_image(prompt, size="2048x2048"):
    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Content-Type": "application/json"
    }

    payload = {
        "model": MODEL,
        "prompt": prompt,
        "sequential_image_generation": "disabled",
        "response_format": "url",
        "size": size,
        "stream": False,
        "watermark": False
    }

    try:
        print(f"正在调用API生成图片 (size={size})...")
        response = requests.post(API_BASE_URL, headers=headers, json=payload, timeout=120)
        response.raise_for_status()
        result = response.json()

        if result.get("data") and isinstance(result["data"], list) and len(result["data"]) > 0:
            if result["data"][0].get("url"):
                return result["data"][0]["url"]

        print(f"API调用失败: {result.get('error', {}).get('message', '未知错误')}")
        return None
    except requests.exceptions.RequestException as e:
        print(f"请求异常: {str(e)}")
        return None


def download_image(url, save_path):
    try:
        response = requests.get(url)
        response.raise_for_status()
        img = Image.open(BytesIO(response.content))
        img.save(save_path)
        print(f"图片已保存: {save_path} ({img.size[0]}x{img.size[1]})")
        return True
    except Exception as e:
        print(f"下载图片失败: {str(e)}")
        return False


def generate_bookshelf_icons():
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    bookshelves = [
        {
            "id": "humanities_history",
            "name": "人文历史",
            "icon": "bookshelf_humanities.png",
            "prompt": (
                "中国风书架图标设计，人文历史主题，展示古籍书籍和历史文物，"
                "简洁现代的图标风格，方形构图，色彩温暖，中国传统元素，"
                "高清分辨率，图标设计，UI元素，纯色背景，专业设计"
            )
        },
        {
            "id": "art_creativity",
            "name": "艺术创作",
            "icon": "bookshelf_art.png",
            "prompt": (
                "中国风书架图标设计，艺术创作主题，展示画笔、调色板和艺术作品，"
                "简洁现代的图标风格，方形构图，色彩丰富，艺术感强，"
                "高清分辨率，图标设计，UI元素，纯色背景，专业设计"
            )
        },
        {
            "id": "nature_geography",
            "name": "自然地理",
            "icon": "bookshelf_nature.png",
            "prompt": (
                "中国风书架图标设计，自然地理主题，展示山脉、河流和自然风光，"
                "简洁现代的图标风格，方形构图，绿色系配色，自然清新，"
                "高清分辨率，图标设计，UI元素，纯色背景，专业设计"
            )
        },
        {
            "id": "biology_world",
            "name": "生物世界",
            "icon": "bookshelf_biology.png",
            "prompt": (
                "中国风书架图标设计，生物世界主题，展示动植物和自然生态，"
                "简洁现代的图标风格，方形构图，绿色和蓝色系配色，生命感，"
                "高清分辨率，图标设计，UI元素，纯色背景，专业设计"
            )
        },
        {
            "id": "life_society",
            "name": "生活社会",
            "icon": "bookshelf_life.png",
            "prompt": (
                "中国风书架图标设计，生活社会主题，展示日常生活场景和社会元素，"
                "简洁现代的图标风格，方形构图，温暖的橙色系配色，生活化，"
                "高清分辨率，图标设计，UI元素，纯色背景，专业设计"
            )
        },
        {
            "id": "technology_industry",
            "name": "科技工业",
            "icon": "bookshelf_tech.png",
            "prompt": (
                "中国风书架图标设计，科技工业主题，展示科技元素和工业设备，"
                "简洁现代的图标风格，方形构图，蓝色和银色系配色，科技感，"
                "高清分辨率，图标设计，UI元素，纯色背景，专业设计"
            )
        },
        {
            "id": "general_materials",
            "name": "综合素材",
            "icon": "bookshelf_general.png",
            "prompt": (
                "中国风书架图标设计，综合素材主题，展示各种图案和素材元素，"
                "简洁现代的图标风格，方形构图，多彩配色，综合性，"
                "高清分辨率，图标设计，UI元素，纯色背景，专业设计"
            )
        }
    ]

    print("=" * 80)
    print("书架图标生成")
    print("=" * 80)

    success_count = 0
    fail_count = 0

    for shelf in bookshelves:
        print(f"\n{'='*60}")
        print(f"书架: {shelf['name']} ({shelf['id']})")
        print(f"图标文件: {shelf['icon']}")
        print(f"提示词: {shelf['prompt']}")
        print(f"{'='*60}")

        image_url = generate_jimeng_image(shelf['prompt'], size="2048x2048")
        if image_url:
            print(f"生成成功: {image_url}")
            save_path = os.path.join(OUTPUT_DIR, shelf['icon'])
            if download_image(image_url, save_path):
                success_count += 1
            else:
                fail_count += 1
        else:
            print(f"生成失败: {shelf['id']}")
            fail_count += 1

    print("\n" + "=" * 80)
    print("书架图标生成完成！")
    print("=" * 80)
    print(f"\n生成结果摘要:")
    print(f"  书架总数: {len(bookshelves)}")
    print(f"  成功: {success_count}")
    print(f"  失败: {fail_count}")
    print(f"  输出目录: {OUTPUT_DIR}")


if __name__ == "__main__":
    generate_bookshelf_icons()