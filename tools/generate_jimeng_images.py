import os
import sys
import json
import requests
from PIL import Image
from io import BytesIO

API_BASE_URL = "https://ark.cn-beijing.volces.com/api/v3/images/generations"
API_KEY = "ark-769a3f8a-9ceb-4556-ae95-d882f7966850-2be63"
MODEL = "doubao-seedream-4-5-251128"

MYTHOLOGY_GRID_SIZE = 5

ASPECT_RATIO_SIZES = {
    "1:1": "2048x2048",
    "4:3": "2304x1728",
    "3:4": "1728x2304",
    "16:9": "2848x1600",
    "9:16": "1600x2848",
    "3:2": "2496x1664",
    "2:3": "1664x2496",
    "21:9": "3136x1344",
}


def get_size_for_grid(x_cells, y_cells):
    from math import gcd
    g = gcd(x_cells, y_cells)
    ratio_w = x_cells // g
    ratio_h = y_cells // g
    ratio_key = f"{ratio_w}:{ratio_h}"
    if ratio_key in ASPECT_RATIO_SIZES:
        return ASPECT_RATIO_SIZES[ratio_key]
    return "2K"


def generate_jimeng_image(prompt, size="2K"):
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
        print(f"API返回结果: {json.dumps(result, ensure_ascii=False, indent=2)}")

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


def main():
    output_dir = "h:/Work/MyProject/ChineseMemory/assets/images/illustrations/mythology_jimeng"
    os.makedirs(output_dir, exist_ok=True)

    print("=" * 80)
    print("神话时代插图生成（遵循新规则 - 不拉伸）")
    print(f"当前难度阶段: 入门级 (grid_size = {MYTHOLOGY_GRID_SIZE})")
    print("=" * 80)

    stories = {
        "pangu": {
            "name": "盘古开天",
            "x_cells": 3,
            "y_cells": 2,
            "objects": ["巨斧", "太阳", "山脉"],
            "prompt": (
                "盘古开天辟地，中国传统水墨画风格，一幅完整的故事场景画。"
                "画面中央巨人盘古手持巨斧劈开天地，上方天空中有太阳，下方大地上有连绵山脉，"
                "云雾缭绕，天地初开的壮丽景象。"
                "浓墨重彩，传统中国画技法，完整构图，高分辨率"
            )
        },
        "nuwa": {
            "name": "女娲补天",
            "x_cells": 3,
            "y_cells": 2,
            "objects": ["五色石", "巨龟", "天空裂缝"],
            "prompt": (
                "女娲补天，中国传统工笔画风格，一幅完整的故事场景画。"
                "画面中央女娲女神手持五色石飞向天空，天空中有巨大的裂缝，"
                "下方大地上有巨龟驮着天柱，祥云缭绕，神话场景。"
                "细腻笔触，传统东方美学，完整构图，高分辨率"
            )
        },
        "houyi": {
            "name": "后羿射日",
            "x_cells": 3,
            "y_cells": 2,
            "objects": ["神弓", "太阳", "箭"],
            "prompt": (
                "后羿射日，中国传统壁画风格，一幅完整的故事场景画。"
                "画面中央英雄后羿拉满神弓射向天空，天空中有多个太阳，"
                "弓箭飞向太阳，大地焦枯，动感构图。"
                "粗犷线条，敦煌壁画风格，完整构图，高分辨率"
            )
        }
    }

    for story_id, story_info in stories.items():
        x = story_info['x_cells']
        y = story_info['y_cells']
        api_size = get_size_for_grid(x, y)

        print(f"\n{'='*60}")
        print(f"故事: {story_info['name']} ({story_id})")
        print(f"布局: {x}x{y} 个 {MYTHOLOGY_GRID_SIZE}x{MYTHOLOGY_GRID_SIZE} 网格区域")
        print(f"API尺寸参数: {api_size} (宽高比 {x}:{y})")
        print(f"核心物体: {', '.join(story_info['objects'])}")
        print(f"提示词: {story_info['prompt']}")
        print(f"{'='*60}")

        image_url = generate_jimeng_image(story_info['prompt'], size=api_size)
        if image_url:
            print(f"生成成功: {image_url}")
            save_path = os.path.join(output_dir, f"{story_id}.png")
            download_image(image_url, save_path)
        else:
            print(f"生成失败: {story_id}")

    print("\n" + "=" * 80)
    print("神话时代插图生成完成！")
    print("=" * 80)
    print(f"\n生成结果摘要:")
    print(f"  故事插图: 3张")
    for story_id, story_info in stories.items():
        x = story_info['x_cells']
        y = story_info['y_cells']
        api_size = get_size_for_grid(x, y)
        img_path = os.path.join(output_dir, f"{story_id}.png")
        if os.path.exists(img_path):
            img = Image.open(img_path)
            print(f"    {story_info['name']}: {x}x{y} 区域, {img.size[0]}x{img.size[1]} 像素 (API size={api_size}), 物体: {', '.join(story_info['objects'])}")
        else:
            print(f"    {story_info['name']}: 生成失败")
    print(f"  难度阶段: 入门级 (grid_size = {MYTHOLOGY_GRID_SIZE})")


if __name__ == "__main__":
    main()
